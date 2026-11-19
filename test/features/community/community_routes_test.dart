import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/data/social_repository.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/community/presentation/social_panels.dart';
import 'package:marea/features/home_feed/models/home_feed_models.dart';
import 'package:marea/features/community/presentation/community_collection_screen.dart';
import 'package:marea/features/community/presentation/mission_management_screen.dart';
import 'package:marea/features/community/presentation/post_composer_screen.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/presentation/profile_screen.dart';
import '../../support/fakes.dart';
import '../../support/home_feed_fakes.dart';
import '../../support/mission_repository_fake.dart';

class _CommunityFake extends MissionRepositoryFake {
  String title = 'Proyecto original';
  bool hidden = false;
  int postLoads = 0, postSaves = 0;
  final searches = <(String, String?, int)>[];
  Future<List<CommunityPost>> Function(String, int)? searchResults;
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
    bool discoverOnly = false,
    bool visibleOnly = false,
    int offset = 0,
  }) async {
    if (visibleOnly) {
      searches.add((query, category, offset));
      if (searchResults != null) return searchResults!(query, offset);
      final term = query.toLowerCase();
      return !hidden &&
              (category == null || currentPost.category == category) &&
              (title.toLowerCase().contains(term) ||
                  currentPost.body.toLowerCase().contains(term))
          ? [currentPost]
          : [];
    }
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
    const CommunityProfile(
      id: 'other',
      fullName: 'Café Bruma',
      username: 'cafebruma',
      userType: UserType.business,
    ),
  ].where((p) => ids == null || ids.contains(p.id)).toList();
}

class _PostSocial implements SocialRepository {
  final read = <String?>[];
  final rows = <PostComment>[];
  final target = PostComment(
    id: 'older',
    postId: 'post-1',
    authorId: 'applicant',
    body: 'Un comentario que llegó por notificación.',
    createdAt: DateTime.utc(2026, 9, 1),
  );

  @override
  Future<List<PostComment>> comments(String postId, {int offset = 0}) async =>
      rows.skip(offset).take(30).toList();

  @override
  Future<PostComment?> comment(String id) async =>
      id == target.id ? target : null;

  @override
  Future<Map<String, PostSocialStats>> stats(List<String> postIds) async => {
    for (final id in postIds)
      id: PostSocialStats(postId: id, commentCount: rows.length),
  };

  @override
  Future<String> createComment(
    String postId,
    String body,
    String operationId,
  ) async {
    rows.insert(
      0,
      PostComment(
        id: operationId,
        postId: postId,
        body: body,
        authorId: sampleProfile.id,
        createdAt: DateTime.utc(2026, 9, 3),
      ),
    );
    return operationId;
  }

  @override
  Future<void> deleteComment(String id) async =>
      rows.removeWhere((comment) => comment.id == id);

  @override
  Stream<void> changes(String recipientId) => const Stream.empty();

  @override
  Future<int> unreadCount() async => 0;

  @override
  Future<void> markRead({String? id, DateTime? before}) async => read.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<GoRouter> _open(
  WidgetTester tester,
  _CommunityFake repo,
  String path, {
  bool admin = false,
  bool paginatedHome = false,
  SocialRepository? postSocial,
}) async {
  final profile = Profile.fromJson({
    ...sampleProfile.toJson(),
    'role': admin ? 'admin' : 'user',
  }).copyWith(onboardingStatus: OnboardingStatus.skipped);
  final session = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: FakeProfileRepository()..value = profile,
    communityRepository: repo,
    socialRepository: postSocial,
    homeFeedRepository: paginatedHome
        ? (HomeFeedFake()..entries = [HomeFeedEntry.post(repo.currentPost)])
        : null,
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
  testWidgets('legacy discovery links redirect to live collections', (tester) async {
    final router = await _open(tester, _CommunityFake(), '/home');
    for (final entry in {
      '/explore': '/home',
      '/explore?section=people': '/search/people',
      '/explore?section=showcases': '/search/showcases',
      '/explore?section=saved': '/profile/saved',
      '/explore?from=discover&category=otros': '/search/posts?category=otros&from=discover',
      '/discover?section=saved': '/missions?section=saved',
    }.entries) {
      router.go(entry.key);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.toString(), entry.value);
      expect(find.byTooltip('Explorar'), findsNothing);
    }
  });

  testWidgets('Home search carries category and returns to the same results', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repo = _CommunityFake();
    final router = await _open(tester, repo, '/home', paginatedHome: true);

    expect(find.byTooltip('Filtrar Inicio').hitTestable(), findsOneWidget);
    expect(
      find.byTooltip('Buscar publicaciones').hitTestable(),
      findsOneWidget,
    );
    expect(tester.getSize(find.byTooltip('Buscar publicaciones')).height, 48);
    await _tap(tester, find.text('Arte'));
    await _tap(tester, find.byTooltip('Buscar publicaciones'));
    expect(repo.searches.last, ('', 'arte', 0));
    expect(tester.testTextInput.isVisible, isTrue);

    final field = find.byType(TextField);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(field, 'comunidad');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(repo.searches.last, ('comunidad', 'arte', 0));
    expect(tester.takeException(), isNull);

    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Proyecto original'));
    expect(find.byKey(const Key('detail-post-action-row')), findsOneWidget);
    expect(find.byTooltip('Crear'), findsNothing);
    expect(find.text(repo.currentPost.body), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, 'comunidad');
    expect(find.text('Proyecto original'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Arte'), findsOneWidget);

    await _tap(tester, find.text('Proyecto original'));
    repo.hidden = true;
    router.pop();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, 'comunidad');
    expect(find.text('Proyecto original'), findsNothing);
  });

  testWidgets(
    'post search rejects stale replies and paginates the latest query',
    (tester) async {
      final pending = Completer<List<CommunityPost>>();
      final repo = _CommunityFake()
        ..searchResults = (query, offset) => switch ((query, offset)) {
          ('viejo', _) => pending.future,
          ('nuevo', 0) => Future.value([
            for (var i = 0; i < 30; i++)
              homePost(id: 'test-$i', title: 'Nuevo $i'),
          ]),
          ('nuevo', 30) => Future.value([homePost(title: 'Último resultado')]),
          _ => Future.value([]),
        };
      await _open(tester, repo, '/search/posts');
      final input = find.byType(TextField);
      await tester.enterText(input, 'viejo');
      await tester.pump(const Duration(milliseconds: 300));
      expect(repo.searches, [('viejo', null, 0)]);
      await tester.enterText(input, 'nuevo');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      pending.complete([homePost(title: 'Resultado antiguo')]);
      await tester.pumpAndSettle();
      expect(find.text('Nuevo 0'), findsOneWidget);
      expect(find.text('Resultado antiguo'), findsNothing);
      final more = find.text('Cargar más');
      await tester.scrollUntilVisible(
        more,
        400,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      await _tap(tester, more);
      expect(repo.searches, [
        ('viejo', null, 0),
        ('nuevo', null, 0),
        ('nuevo', null, 30),
      ]);
      expect(find.text('Último resultado'), findsOneWidget);
    },
  );

  testWidgets('post comments open inline, send, and update the count', (
    tester,
  ) async {
    final social = _PostSocial();
    await _open(tester, _CommunityFake(), '/posts/post-1', postSocial: social);
    await _tap(tester, find.byTooltip('Comentarios'));
    expect(find.byType(SocialPanelFrame), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
    await _tap(tester, find.text('Escribir comentario'));
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(find.byType(TextField), 'Quiero participar.');
    await _tap(tester, find.text('Enviar'));
    expect(find.text('Quiero participar.'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byTooltip('Comentarios'),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    await _tap(tester, find.byTooltip('Retirar comentario'));
    await _tap(tester, find.text('Eliminar'));
    expect(find.text('Quiero participar.'), findsNothing);
    expect(
      find.descendant(
        of: find.byTooltip('Comentarios'),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('notification loads an older comment and shows it inline', (
    tester,
  ) async {
    final social = _PostSocial();
    await _open(
      tester,
      _CommunityFake(),
      '/posts/post-1?panel=comments&comment=older&notification=notice',
      postSocial: social,
    );
    expect(find.text(social.target.body).hitTestable(), findsOneWidget);
    expect(find.byType(SocialPanelFrame), findsNothing);
    expect(social.read, ['notice']);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  for (final origin in ['/home', '/profile']) {
    testWidgets('moderating a post refreshes retained $origin on return', (
      tester,
    ) async {
      final repo = _CommunityFake();
      final router = await _open(tester, repo, origin, admin: true);
      if (origin == '/profile') {
        await _tap(tester, find.byTooltip('Menú del perfil'));
      }
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
      await _tap(tester, find.byTooltip('Acciones'));
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
      await _tap(tester, find.byTooltip('Acciones'));
      await _tap(tester, find.text('Guardar'));
      expect(repo.savedPosts, contains('post-1'));
      router.go('/explore?section=saved');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/profile/saved');
      expect(find.text('Proyecto original'), findsOneWidget);
      await _tap(tester, find.byTooltip('Acciones'));
      await _tap(tester, find.text('Quitar guardado'));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
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
      await _tap(tester, find.text('Gestionar misión'));
      await _tap(tester, find.text('Mariana Torres'));
      await tester.pumpAndSettle();
      expect(find.byType(PublicProfileScreen), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.matches.last.matchedLocation,
        '/people/applicant',
      );
      await _backWithAppBar(tester);
      await tester.pumpAndSettle();
      expect(find.byType(MissionManagementScreen), findsOneWidget);
      expect(find.text('Quiero aportar mi experiencia.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
