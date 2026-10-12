// Production routes and components, isolated from Supabase for visual checks.
// flutter run -d web-server -t test/browser/modern_interactions_probe.dart --web-port 7367
import 'package:flutter/material.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/community/data/social_repository.dart';
import '../support/fakes.dart';
import '../support/mission_repository_fake.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  final controller = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: FakeProfileRepository(),
    communityRepository: _Community(),
    socialRepository: _Social(),
  );
  await controller.initialize();
  final router = AppRouter.create(controller)..go('/home');
  runApp(
    MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    ),
  );
}

class _Community extends MissionRepositoryFake {
  @override
  Future<List<CommunityPost>> posts({
    String? authorId,
    String query = '',
    String? category,
    bool savedOnly = false,
    int offset = 0,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return offset > 0
        ? []
        : [
            CommunityPost(
              id: 'preview-post',
              authorId: 'other',
              kind: PostKind.community,
              title: 'Una idea pequeña también puede hacer olas',
              body:
                  'Estoy creando una colección inspirada en la luz de Manzanillo. ¿Qué te inspira a crear? Me encantaría escuchar sus ideas y conectar con personas de la comunidad.',
              category: 'arte',
              allowsCollaboration: true,
              createdAt: DateTime.utc(2026, 10, 5),
              updatedAt: DateTime.utc(2026, 10, 5),
            ),
          ];
  }

  @override
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  }) async => [
    CommunityProfile.fromJson(sampleProfile.toJson()),
    const CommunityProfile(
      id: 'other',
      fullName: 'Mariana Torres',
      username: 'mariana',
      userType: UserType.creator,
    ),
  ];
}

class _Social implements SocialRepository {
  PostReaction? selected;
  final entries = <PostComment>[];
  @override
  Future<Map<String, PostSocialStats>> stats(List<String> ids) async => {
    for (final id in ids)
      id: PostSocialStats(
        postId: id,
        myReaction: selected,
        reactionCount: selected == null ? 12 : 13,
        commentCount: entries.length,
      ),
  };
  @override
  Future<void> setReaction(String id, PostReaction? reaction) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    selected = reaction;
  }

  @override
  Future<List<PostComment>> comments(String id, {int offset = 0}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return entries;
  }

  @override
  Future<String> createComment(
    String id,
    String body,
    String operationId,
  ) async {
    entries.add(
      PostComment(
        id: operationId,
        postId: id,
        authorId: sampleProfile.id,
        body: body,
        createdAt: DateTime.now(),
      ),
    );
    return operationId;
  }

  @override
  Stream<void> changes(String recipientId) => const Stream.empty();
  @override
  Future<List<SocialNotification>> notifications({
    bool unreadOnly = false,
    int offset = 0,
  }) async => [];
  @override
  Future<int> unreadCount() async => 0;
  @override
  Future<void> markRead({String? id, DateTime? before}) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
