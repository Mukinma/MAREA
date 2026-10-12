import 'package:marea/features/auth/presentation/welcome_screen.dart';
import 'package:marea/features/location/models/location_models.dart';
import 'package:marea/features/community/data/mission_social_repository.dart';
import 'package:marea/features/community/models/mission_social.dart';
// Visual verification only: production components with isolated fixture data.
// flutter run -d web-server -t test/browser/home_feed_probe.dart --web-port 7373
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/home_feed/models/home_feed_models.dart';
import 'package:marea/features/home_feed/models/story.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../support/fakes.dart';
import '../support/home_feed_fakes.dart';
import 'package:marea/features/community/data/social_repository.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'dart:typed_data';

void main() async {
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  final now = DateTime.now();
  final feed = _Feed()
    ..entries = [
      HomeFeedEntry.mission(
        Mission(
          id: 'event',
          authorId: 'other',
          startsAt: now.add(const Duration(days: 3)),
          capacity: 5,
          title: 'Mercado Creativo en la Playa',
          body:
              'Arte, música, comida local y buena vibra. Un espacio para compartir, crear y apoyar talento local.',
          category: 'arte',
          location: 'Manzanillo',
          imagePath: 'Hero1.webp',
          city: const LocationCity(name: 'Manzanillo'),
          createdAt: now,
        ),
      ),

      HomeFeedEntry.post(
        CommunityPost(
          id: 'cafe',
          authorId: 'cafe',
          kind: PostKind.space,
          title: 'Un espacio para crear',
          body:
              'Café de especialidad, arte local y un espacio de trabajo para conectar con la comunidad.',
          category: 'gastronomia',
          location: 'Manzanillo',
          city: const LocationCity(name: 'Manzanillo'),
          imagePath: 'Hero3.webp',
          createdAt: now.subtract(const Duration(hours: 2)),
          updatedAt: now,
        ),
      ),
      HomeFeedEntry.post(
        homePost(id: 'text-only', title: 'Ideas que conectan a nuestra ciudad'),
      ),
    ];
  final stories = StoriesFake()
    ..values.addAll([
      Story(
        id: 'story-one',
        authorId: 'other',
        text: 'Hoy seguimos creando. ¿Qué te inspira?',
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      ),
      Story(
        id: 'story-two',
        authorId: 'cafe',
        text: 'Un café y una buena idea.',
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      ),
    ]);
  final session = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: FakeProfileRepository(),
    homeFeedRepository: feed,
    storiesRepository: stories,
    communityRepository: _Community(),
    socialRepository: _Social(),
    missionSocialRepository: _MissionSocial(),
    mediaRepository: _Media(),
  );
  await session.initialize();
  final router = AppRouter.create(session)..go('/home');
  final welcome = Uri.base.queryParameters['screen'] == 'welcome';
  final scale = double.tryParse(Uri.base.queryParameters['scale'] ?? '1') ?? 1;
  runApp(
    welcome
        ? MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: const WelcomeScreen(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          )
        : MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            locale: const Locale('es', 'MX'),
            supportedLocales: const [Locale('es', 'MX')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
  );
}

class _Feed extends HomeFeedFake {
  @override
  Future<HomeFeedPage> page(
    HomeFeedFilter filter, {
    Map<String, dynamic>? cursor,
  }) async => HomeFeedPage(
    entries: entries
        .where(
          (e) =>
              (filter.kind == HomeFeedKind.all ||
                  (filter.kind == HomeFeedKind.post) == (e.post != null)) &&
              (filter.category == null ||
                  (e.post?.category ?? e.mission!.category) ==
                      filter.category) &&
              (filter.mode != HomeFeedMode.following ||
                  follows.contains(e.authorId)),
        )
        .toList(),
  );
}

class _Community extends HomeCommunityFake {
  @override
  Future<String> imageUrl(String path) async =>
      '/assets/assets/onboarding/$path';
  @override
  Future<String> missionImageUrl(String path) async =>
      '/assets/assets/onboarding/$path';
  @override
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  }) async => [
    const CommunityProfile(
      id: 'other',
      fullName: 'Mariana Torres',
      username: 'mariana',
      userType: UserType.creator,
      avatarPath: 'Hero4.webp',
    ),
    const CommunityProfile(
      id: 'cafe',
      fullName: 'Café Bruma',
      username: 'cafebruma',
      userType: UserType.business,
      avatarPath: 'Hero3.webp',
    ),
  ];
}

class _Media implements ProfileMediaRepository {
  @override
  Future<String> signedUrl(String path) async =>
      '/assets/assets/onboarding/$path';
  @override
  Future<String> upload(Uint8List png) async => 'unused';
  @override
  Future<void> remove(String path) async {}
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

class _MissionSocial implements MissionSocialRepository {
  final reactions = <String, PostReaction?>{};
  final values = <MissionComment>[];
  @override
  Future<Map<String, MissionSocialStats>> stats(List<String> ids) async => {
    for (final id in ids)
      id: MissionSocialStats(
        missionId: id,
        reactionCount: reactions[id] == null ? 126 : 127,
        commentCount: 12 + values.length,
        myReaction: reactions[id],
      ),
  };
  @override
  Future<void> setReaction(String id, PostReaction? reaction) async {
    reactions[id] = reaction;
  }

  @override
  Future<List<MissionComment>> comments(String id, {int offset = 0}) async =>
      values.where((c) => c.missionId == id).skip(offset).take(30).toList();
  @override
  Future<MissionComment?> comment(String id) async =>
      values.where((c) => c.id == id).firstOrNull;
  @override
  Future<String> createComment(
    String id,
    String body,
    String operationId,
  ) async {
    if (!values.any((c) => c.id == operationId)) {
      values.add(
        MissionComment(
          id: operationId,
          missionId: id,
          authorId: sampleProfile.id,
          body: body,
          createdAt: DateTime.now(),
        ),
      );
    }
    return operationId;
  }

  @override
  Future<void> deleteComment(String id) async {
    values.removeWhere((c) => c.id == id);
  }
}
