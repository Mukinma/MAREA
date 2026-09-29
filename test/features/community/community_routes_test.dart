import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/explore_screen.dart';
import 'package:marea/features/community/presentation/missions_screen.dart';
import 'package:marea/features/community/presentation/post_composer_screen.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/presentation/profile_screen.dart';
import '../../support/fakes.dart';
import '../../support/mission_repository_fake.dart';

class _CommunityFake extends MissionRepositoryFake {
  String title = 'Proyecto original';
  bool hidden = false;
  int postLoads = 0, postSaves = 0;
  final savedPosts = <String>{};
  CommunityPost get currentPost => CommunityPost(
    id: 'post-1',
    authorId: sampleProfile.id,
    kind: PostKind.project,
    title: title,
    body: 'Un proyecto para conectar a nuestra comunidad.',
    category: 'arte',
    hidden: hidden,
    createdAt: DateTime.utc(2026, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 2),
  );
  @override
  Future<List<CommunityPost>> posts({
    String? authorId,
    String query = '',
    String? category,
    bool savedOnly = false,
    int offset = 0,
  }) async {
    postLoads++;
    return offset > 0 || (savedOnly && !savedPosts.contains('post-1'))
        ? []
        : [currentPost];
  }

  @override
  Future<CommunityPost?> post(String id) async => currentPost;
  @override
  Future<void> savePost(PostInput input, {String? id}) async {
    postSaves++;
    title = input.title;
  }

  @override
  Future<Set<String>> savedPostIds() async => {...savedPosts};
  @override
  Future<void> setSaved(String postId, bool saved) async {
    if (saved) {
      savedPosts.add(postId);
    } else {
      savedPosts.remove(postId);
    }
  }

  @override
  Future<List<ContentReport>> reports({int offset = 0}) async => offset > 0
      ? []
      : [
          ContentReport(
            id: 'report-1',
            reporterId: 'reporter',
            postId: 'post-1',
            reason: 'Revisar el contenido publicado',
            state: hidden ? 'reviewed' : 'open',
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        ];
  @override
  Future<void> moderate(
    String id, {
    required bool mission,
    required bool hide,
  }) async {
    hidden = hide;
  }

  @override
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  }) async => [
    CommunityProfile(
      id: sampleProfile.id,
      fullName: sampleProfile.fullName,
      username: sampleProfile.username,
      userType: sampleProfile.userType,
    ),
    const CommunityProfile(
      id: 'applicant',
      fullName: 'Mariana Torres',
      username: 'marianatorres',
      userType: UserType.creator,
    ),
  ].where((p) => ids == null || ids.contains(p.id)).toList();
}

Future<GoRouter> _open(
  WidgetTester tester,
  _CommunityFake repo,
  String path, {
  bool admin = false,
}) async {
  final profile = Profile.fromJson({
    ...sampleProfile.toJson(),
    'role': admin ? 'admin' : 'user',
  }).copyWith(onboardingStatus: OnboardingStatus.skipped);
  final session = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: FakeProfileRepository()..value = profile,
    communityRepository: repo,
  );
  await session.initialize();
  final router = AppRouter.create(session)..go(path);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() {
    router.dispose();
    session.dispose();
  });
  return router;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _backWithAppBar(WidgetTester tester) async {
  await _tap(tester, find.byIcon(Icons.arrow_back));
}

void main() {
  for (final origin in ['/home', '/profile']) {
    testWidgets('moderating a post refreshes retained $origin on return', (
      tester,
    ) async {
      final repo = _CommunityFake();
      final router = await _open(tester, repo, origin, admin: true);
      if (origin == '/profile') await _tap(tester, find.text('Publicaciones'));
      expect(find.text('Oculta por moderación'), findsNothing);
      final before = repo.postLoads;
      await _tap(tester, find.text('Moderación'));
      await _tap(tester, find.text('Ocultar contenido'));
      expect(repo.hidden, isTrue);
      await _backWithAppBar(tester);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, origin);
      expect(repo.postLoads, greaterThan(before));
      expect(find.text('Oculta por moderación'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'own public link redirects and edited posts refresh the main profile',
    (tester) async {
      final repo = _CommunityFake();
      final path = '/people/${sampleProfile.id}';
      final router = await _open(tester, repo, path);
      await _tap(tester, find.text('Publicaciones'));
      await _tap(tester, find.byTooltip('Opciones de publicación'));
      await _tap(tester, find.text('Editar'));
      expect(find.byType(PostComposerScreen), findsOneWidget);
      final title = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Título',
      );
      await tester.ensureVisible(title);
      await tester.enterText(title, 'Proyecto actualizado');
      final save = find.text('Guardar cambios');
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await _tap(tester, save);
      expect(repo.postSaves, 1);
      expect(router.routeInformationProvider.value.uri.path, '/profile');
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Proyecto actualizado'), findsOneWidget);
      expect(find.text('Proyecto original'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'saving a post persists into Explore saved list and can be removed',
    (tester) async {
      final repo = _CommunityFake();
      final router = await _open(tester, repo, '/home');
      await _tap(tester, find.text('Guardar'));
      expect(repo.savedPosts, contains('post-1'));
      router.go('/explore');
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Guardados'));
      expect(find.text('Proyecto original'), findsOneWidget);
      await _tap(tester, find.text('Guardado'));
      expect(repo.savedPosts, isEmpty);
      expect(find.text('Proyecto original'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'owner can open private applicant profile and return to mission',
    (tester) async {
      final repo = _CommunityFake()
        ..value = missionFixture(author: sampleProfile.id)
        ..requests = [application()];
      final router = await _open(tester, repo, '/missions/mission-1');
      await _tap(tester, find.widgetWithText(TextButton, 'Mariana Torres'));
      await tester.pumpAndSettle();
      expect(find.byType(PublicProfileScreen), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.matches.last.matchedLocation,
        '/people/applicant',
      );
      await _backWithAppBar(tester);
      await tester.pumpAndSettle();
      expect(find.byType(MissionDetailScreen), findsOneWidget);
      expect(find.text('Quiero aportar mi experiencia.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
