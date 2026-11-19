import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/profile/presentation/profile_screen.dart';
import 'package:marea/features/profile/presentation/onboarding_screen.dart';
import 'package:marea/features/ar_markers/data/local_marker_repository.dart';
import 'package:marea/features/chat/data/chat_repository.dart';
import 'package:marea/features/chat/models/chat_models.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/home_feed/data/home_feed_repository.dart';
import 'package:marea/features/profile/presentation/profile_experience.dart';
import '../../support/fakes.dart';
import 'package:marea/shared/widgets/primary_button.dart';
import '../../support/test_app.dart';

class _ProfileChat implements ChatRepository {
  final requested = <String>[];

  @override
  Future<List<ChatConversation>> conversations() async => [];

  @override
  Future<String> request(String targetId) async {
    requested.add(targetId);
    return 'pending-chat';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProfileFollows
    implements HomeFeedRepository, ProfileFollowCountsRepository {
  bool _following = false;

  @override
  Future<ProfileFollowCounts> followCounts(String profileId) async =>
      (followers: _following ? 8 : 7, following: 3);

  @override
  Future<bool> isFollowing(String authorId) async => _following;

  @override
  Future<void> setFollowing(String authorId, bool following) async {
    _following = following;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('message confirms the request and preserves its pending state', (
    tester,
  ) async {
    final chat = _ProfileChat();
    final session = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: FakeProfileRepository(),
      chatRepository: chat,
      homeFeedRepository: _ProfileFollows(),
    );
    await session.initialize();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: ProfileExperience(
            controller: session,
            profile: const CommunityProfile(
              id: 'studio',
              username: 'studio',
              fullName: 'Estudio Marea',
              userType: UserType.business,
            ),
            owner: false,
            onRefresh: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final waveActions = find.byKey(const Key('profile-wave-actions'));
    final message = find.byTooltip('Mensaje');
    expect(find.descendant(of: waveActions, matching: message), findsOneWidget);
    expect(find.text('7 seguidores', findRichText: true), findsOneWidget);
    expect(find.text('3 seguidos', findRichText: true), findsOneWidget);
    await tester.tap(find.text('Seguir'));
    await tester.pumpAndSettle();
    expect(find.text('8 seguidores', findRichText: true), findsOneWidget);
    await tester.tap(message);
    await tester.pumpAndSettle();
    expect(find.text('Enviar solicitud de chat'), findsOneWidget);
    expect(chat.requested, isEmpty);
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();
    expect(chat.requested, ['studio']);
    expect(find.byTooltip('Solicitud enviada'), findsOneWidget);
    final button = find.ancestor(
      of: find.byIcon(Icons.schedule_outlined),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(button).onPressed, isNull);
  });

  testWidgets('initial type and preferences require explicit choices', (
    tester,
  ) async {
    final profiles = FakeProfileRepository()
      ..value = sampleProfile.copyWith(
        initialProfileCompletedAt: null,
        onboardingStatus: OnboardingStatus.pending,
      );
    final c = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: profiles,
    );
    await c.initialize();
    addTearDown(c.dispose);
    await tester.pumpWidget(testApp(OnboardingScreen(controller: c)));
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('register-type-business')));
    await tester.pump();
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNotNull,
    );
    expect(find.textContaining('El tipo de perfil queda fijo'), findsOneWidget);
    expect(find.text('Ahora no'), findsNothing);
  });
  testWidgets(
    'own presentation exposes selected interests and private shortcuts',
    (tester) async {
      final profiles = FakeProfileRepository()
        ..value = sampleProfile.copyWith(interests: ['arte']);
      final c = AppSessionController(
        authRepository: FakeAuthRepository(),
        profileRepository: profiles,
        markerRepository: LocalMarkerRepository(),
      );
      await c.initialize();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        testApp(Scaffold(body: ProfileScreen(controller: c))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Arte'), findsOneWidget);
      expect(find.text(sampleProfile.bio!), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('profile-wave-actions')),
          matching: find.text('Editar perfil'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('profile-experiences-section')),
          matching: find.text('Gestionar experiencias'),
        ),
        findsOneWidget,
      );
      expect(find.text('Guardados'), findsNothing);
      await tester.tap(find.byTooltip('Menú del perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Guardados'), findsOneWidget);
      expect(find.text('Mis postulaciones'), findsOneWidget);
    },
  );
}
