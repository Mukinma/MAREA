import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:latlong2/latlong.dart';
import 'package:marea/core/maps/map_surface.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import 'package:marea/features/home_feed/models/home_feed_models.dart';
import 'package:marea/features/home_feed/models/story.dart';
import 'package:marea/features/home_feed/presentation/story_camera_screen.dart';
import 'package:marea/features/home_feed/presentation/story_composer.dart';
import 'package:marea/features/home_feed/presentation/story_viewer.dart';
import 'package:marea/features/home_feed/presentation/follow_button.dart';
import 'package:marea/features/shell/presentation/app_shell.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../../support/fake_map_surface.dart';
import '../../support/fakes.dart';
import '../../support/home_feed_fakes.dart';
import '../../support/test_app.dart';
import '../profile/data/profile_image_picker_test.dart' show png;

class _StoryGallery extends ImagePickerPlatform {
  _StoryGallery(this.image);
  final XFile image;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => image;
}

class _PendingStoryDelete extends StoriesFake {
  final deletion = Completer<void>();

  @override
  Future<void> delete(String id) async {
    await deletion.future;
    await super.delete(id);
  }
}

AppSessionController controller(HomeFeedFake feed, {StoriesFake? stories}) =>
    AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: FakeProfileRepository(),
      communityRepository: HomeCommunityFake(),
      homeFeedRepository: feed,
      storiesRepository: stories,
    );
void main() {
  for (final width in [320.0, 360.0, 390.0, 600.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'home shows only posts and fits navigation at $width and $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final feed = HomeFeedFake()
            ..entries = [
              HomeFeedEntry.post(homePost()),
              HomeFeedEntry.mission(homeMission()),
            ];
          final session = controller(feed);
          await session.initialize();
          await tester.pumpWidget(
            testApp(
              MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1000),
                  textScaler: TextScaler.linear(scale),
                ),
                child: AppShell(
                  location: '/home',
                  controller: session,
                  child: HomeScreen(controller: session),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(feed.requests.single.kind, HomeFeedKind.post);
          expect(find.text(homeMission().title), findsNothing);
          expect(find.byTooltip('Crear'), findsOneWidget);
          expect(find.text('Publicar'), findsNothing);
          expect(find.text('Tu historia'), findsOneWidget);
          expect(find.byKey(const Key('home-stories-surface')), findsOneWidget);
          expect(find.text('Mariana Torres'), findsWidgets);
          expect(find.byTooltip('Inicio'), findsOneWidget);
          expect(find.byTooltip('Misiones'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.drag(
            find.byKey(const Key('home-feed-scroll')),
            const Offset(0, -600),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          session.dispose();
        },
      );
    }
  }
  testWidgets('pagination keeps the post filter and ignores mixed results', (
    tester,
  ) async {
    const next = {'position': 30};
    final feed = HomeFeedFake()
      ..onPage = (_, cursor) async => HomeFeedPage(
        entries: [
          HomeFeedEntry.mission(homeMission()),
          HomeFeedEntry.post(homePost()),
          if (cursor != null)
            HomeFeedEntry.post(
              homePost(id: 'page-two', title: 'Otra publicación'),
            ),
        ],
        cursor: cursor == null ? next : null,
      );
    final session = controller(feed);
    addTearDown(session.dispose);
    await session.initialize();
    await tester.pumpWidget(
      testApp(Scaffold(body: HomeScreen(controller: session))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cargar más'));
    await tester.pumpAndSettle();
    expect(feed.requests.map((filter) => filter.kind), [
      HomeFeedKind.post,
      HomeFeedKind.post,
    ]);
    expect(feed.cursors, [null, next]);
    expect(find.text(homeMission().title), findsNothing);
    expect(find.text(homePost().title), findsOneWidget);
    expect(find.text('Otra publicación'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a post category filters the current view and can be removed', (
    tester,
  ) async {
    final feed = HomeFeedFake()..entries = [HomeFeedEntry.post(homePost())];
    final session = controller(feed);
    addTearDown(session.dispose);
    await session.initialize();
    await tester.pumpWidget(
      testApp(Scaffold(body: HomeScreen(controller: session))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiendo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arte'));
    await tester.pumpAndSettle();
    expect(feed.requests.last.mode, HomeFeedMode.following);
    expect(feed.requests.last.category, 'arte');
    final active = find.byKey(const Key('home-active-category'));
    expect(active, findsOneWidget);
    await tester.tap(find.byTooltip('Quitar filtro de categoría'));
    await tester.pumpAndSettle();
    expect(feed.requests.last.category, isNull);
    expect(active, findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Cerca uses the point and distance selected in Inicio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final feed = HomeFeedFake();
    final session = controller(feed);
    addTearDown(session.dispose);
    await session.initialize();
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) =>
            MapSurfaceScope(builder: fakeMapSurfaceBuilder, child: child!),
        home: Scaffold(body: HomeScreen(controller: session)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerca'));
    await tester.pumpAndSettle();
    expect(feed.requests, hasLength(1));
    await tester.tap(find.text('Elegir punto'));
    await tester.pumpAndSettle();
    tester
        .widget<FakeMapSurface>(find.byType(FakeMapSurface))
        .options
        .onTap(const LatLng(19.15, -104.31));
    await tester.pump();
    await tester.tap(find.text('Usar esta ubicación'));
    await tester.pumpAndSettle();
    expect(feed.requests.last.mode, HomeFeedMode.nearby);
    expect(feed.requests.last.latitude, 19.15);
    expect(feed.requests.last.longitude, -104.31);
    await tester.tap(find.byTooltip('Filtrar Inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25 km'));
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();
    expect(feed.requests.last.kind, HomeFeedKind.post);
    expect(feed.requests.last.radiusKm, 25);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Inicio opens the shared creation choices and the people tab in Explorar',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = controller(HomeFeedFake(), stories: StoriesFake());
      addTearDown(session.dispose);
      await session.initialize();
      final router = AppRouter.create(session)..go('/home');
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Crear'));
      await tester.pumpAndSettle();
      expect(find.text('Historia'), findsOneWidget);
      expect(find.text('Crear misión'), findsOneWidget);
      await tester.tap(find.text('Publicación'));
      await tester.pumpAndSettle();
      expect(find.text('Crear publicación'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Siguiendo'));
      await tester.tap(find.text('Siguiendo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explorar perfiles'));
      await tester.pumpAndSettle();
      expect(find.text('Buscar nombre o usuario'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Crear opens the story camera with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    const camera = MethodChannel('plugins.flutter.io/camera');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(camera, (_) async => <Object>[]);
    addTearDown(() => messenger.setMockMethodCallHandler(camera, null));
    final session = controller(HomeFeedFake(), stories: StoriesFake());
    addTearDown(session.dispose);
    await session.initialize();
    final router = AppRouter.create(session)..go('/home');
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    final create = find.byTooltip('Crear');
    final dock = find.byKey(const Key('mobile-dock'));
    expect(
      tester.getTopLeft(create).dx,
      greaterThan(tester.getTopRight(dock).dx),
    );
    expect(tester.getSize(create).height, greaterThanOrEqualTo(48));
    await tester.tap(create);
    await tester.pumpAndSettle();
    final story = find.widgetWithText(InkWell, 'Historia');
    await tester.ensureVisible(story);
    await tester.tap(story);
    final cameraScreen = find.byType(StoryCameraScreen);
    for (
      var frame = 0;
      frame < 30 && cameraScreen.evaluate().isEmpty;
      frame++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(cameraScreen, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byTooltip('Cerrar cámara').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('transparent dock absorbs taps without hitting the content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var taps = 0;
    await tester.pumpWidget(
      testApp(
        AppShell(
          location: '/home',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox.expand(child: ColoredBox(color: Colors.red)),
          ),
        ),
      ),
    );
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.extendBody, isTrue);
    await tester.tapAt(const Offset(5, 840));
    expect(taps, 0);
    await tester.tapAt(const Offset(5, 600));
    expect(taps, 1);
  });
  testWidgets('switching feed mode discards an older pending response', (
    tester,
  ) async {
    final pending = Completer<HomeFeedPage>();
    final feed = HomeFeedFake()
      ..onPage = (filter, cursor) => filter.mode == HomeFeedMode.forYou
          ? pending.future
          : Future.value(
              HomeFeedPage(
                entries: [
                  HomeFeedEntry.post(homePost(title: 'Contenido seguido')),
                ],
              ),
            );
    final session = controller(feed);
    await tester.pumpWidget(
      testApp(Scaffold(body: HomeScreen(controller: session))),
    );
    await tester.pump();
    await tester.tap(find.text('Siguiendo'));
    await tester.pumpAndSettle();
    pending.complete(
      HomeFeedPage(
        entries: [HomeFeedEntry.post(homePost(title: 'Respuesta antigua'))],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Contenido seguido'), findsOneWidget);
    expect(find.text('Respuesta antigua'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
  testWidgets('sign out discards pending feed and story responses', (
    tester,
  ) async {
    final pendingFeed = Completer<HomeFeedPage>();
    final pendingStories = Completer<StoryBatch>();
    final feed = HomeFeedFake()..onPage = (_, _) => pendingFeed.future;
    final stories = StoriesFake()..onList = () => pendingStories.future;
    final session = controller(feed, stories: stories);
    await session.initialize();
    await tester.pumpWidget(
      testApp(Scaffold(body: HomeScreen(controller: session))),
    );
    await tester.pump();
    await session.signOut();
    pendingFeed.complete(
      HomeFeedPage(
        entries: [HomeFeedEntry.post(homePost(title: 'Sesión anterior'))],
      ),
    );
    final now = DateTime.now();
    pendingStories.complete(
      StoryBatch(
        stories: [
          Story(
            id: 'old',
            authorId: 'other',
            text: 'Historia anterior',
            createdAt: now,
            expiresAt: now.add(const Duration(hours: 24)),
          ),
        ],
        serverTime: now,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sesión anterior'), findsNothing);
    expect(find.text('Mariana Torres'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
  testWidgets('stories keep Crear available and pause behind its menu', (
    tester,
  ) async {
    final now = DateTime.now();
    final stories = StoriesFake()
      ..values.add(
        Story(
          id: 'one',
          authorId: 'other',
          text: 'Mi historia',
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 24)),
        ),
      );
    final session = controller(HomeFeedFake(), stories: stories);
    await session.initialize();
    final router = AppRouter.create(session)..go('/home');
    await tester.pumpWidget(
      MaterialApp.router(theme: ThemeData(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-stories-surface')), findsOneWidget);
    await tester.tap(find.text('Mariana Torres'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Mi historia'), findsOneWidget);
    expect(find.byTooltip('Inicio').hitTestable(), findsNothing);
    await tester.tap(find.byTooltip('Crear').hitTestable());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.tap(find.byTooltip('Cerrar menú de creación'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Mi historia'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    session.dispose();
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets('story image layout keeps overlays visible at $width', (
      tester,
    ) async {
      const height = 844.0;
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime.now();
      final story = Story(
        id: 'photo-story',
        authorId: 'other',
        imagePath: 'photo',
        text: 'Una historia con imagen.',
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      );
      final batch = StoryBatch(stories: [story], serverTime: now);
      final repository = StoriesFake()..values.add(story);
      final session = controller(HomeFeedFake(), stories: repository);
      await tester.pumpWidget(
        testApp(
          StoryViewer(
            stories: batch.stories,
            batch: batch,
            repository: repository,
            profiles: const {
              'other': CommunityProfile(
                id: 'other',
                fullName: 'Mariana Torres',
                username: 'mariana',
                userType: UserType.creator,
              ),
            },
            controller: session,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final frame = tester.getRect(find.byKey(const Key('story-viewer-frame')));
      final username = tester.getRect(find.text('Mariana Torres'));
      final progress = tester.getRect(find.byType(LinearProgressIndicator));
      expect(frame.width, width < 640 ? width : 640);
      expect(frame.height, height);
      expect(username.bottom, lessThan(progress.top));
      expect(progress.bottom, lessThan(height / 2));
      expect(find.text('Una historia con imagen.'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      session.dispose();
    });
  }
  testWidgets(
    'a failed story publish retains the photo and retries the same operation',
    (tester) async {
      final bytes = (await tester.runAsync(() => png(80, 80)))!;
      final original = ImagePickerPlatform.instance;
      ImagePickerPlatform.instance = _StoryGallery(
        XFile.fromData(bytes, name: 'story.png', mimeType: 'image/png'),
      );
      addTearDown(() => ImagePickerPlatform.instance = original);
      final stories = StoriesFake()..failPublish = true;
      final session = controller(HomeFeedFake(), stories: stories);
      await tester.pumpWidget(testApp(StoryComposer(controller: session)));
      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.photo_library_outlined));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      final publish = find.byType(FloatingActionButton);
      await tester.tap(publish);
      await tester.pumpAndSettle();
      expect(stories.published, hasLength(1));
      expect(find.byType(Image), findsOneWidget);
      await tester.tap(publish);
      await tester.pumpAndSettle();
      expect(stories.published.length, 2);
      expect(stories.published[0].id, stories.published[1].id);
      expect(stories.published[0].imagePath, stories.published[1].imagePath);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    },
  );
  testWidgets('Crear cannot interrupt deletion of the current story', (
    tester,
  ) async {
    final now = DateTime.now();
    final stories = _PendingStoryDelete()
      ..values.add(
        Story(
          id: 'own',
          authorId: sampleProfile.id,
          text: 'Mi historia',
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 1)),
        ),
      );
    final session = controller(HomeFeedFake(), stories: stories);
    await session.initialize();
    final router = AppRouter.create(session)..go('/home');
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tú'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final viewer = find.byType(StoryViewer);
    await tester.tap(
      find.descendant(
        of: viewer,
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar historia'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Crear').hitTestable());
    await tester.pumpAndSettle();
    expect(find.byTooltip('Cerrar menú de creación'), findsNothing);
    stories.deletion.complete();
    await tester.pumpAndSettle();
    expect(viewer, findsNothing);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    session.dispose();
  });
  testWidgets(
    'story viewer marks shown content seen and supports pause and next',
    (tester) async {
      final stories = StoriesFake();
      final now = DateTime.now();
      final batch = StoryBatch(
        stories: [
          Story(
            id: 'one',
            authorId: 'other',
            text: 'Primera',
            createdAt: now,
            expiresAt: now.add(const Duration(hours: 24)),
          ),
          Story(
            id: 'two',
            authorId: 'other',
            text: 'Segunda',
            createdAt: now,
            expiresAt: now.add(const Duration(hours: 24)),
          ),
        ],
        serverTime: now,
      );
      final session = controller(HomeFeedFake(), stories: stories);
      await tester.pumpWidget(
        testApp(
          StoryViewer(
            stories: batch.stories,
            batch: batch,
            repository: stories,
            profiles: const {},
            controller: session,
          ),
        ),
      );
      await tester.pump();
      expect(stories.viewed, contains('one'));
      await tester.pump(const Duration(milliseconds: 500));
      final frame = tester.getRect(find.byKey(const Key('story-viewer-frame')));
      final gesture = await tester.startGesture(
        Offset(frame.left + 12, frame.top + frame.height * .5),
      );
      await tester.pump(const Duration(milliseconds: 600));
      final indicator = find.byType(LinearProgressIndicator).first;
      final progress = tester.widget<LinearProgressIndicator>(indicator).value;
      await tester.pump(const Duration(seconds: 6));
      expect(tester.widget<LinearProgressIndicator>(indicator).value, progress);
      await gesture.up();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.pump();
      expect(stories.viewed, contains('two'));
      expect(find.text('Segunda'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    },
  );
  testWidgets('opening the story menu pauses playback', (tester) async {
    final stories = StoriesFake();
    final now = DateTime.now();
    final batch = StoryBatch(
      stories: [
        Story(
          id: 'one',
          authorId: 'other',
          text: 'Primera',
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 24)),
        ),
        Story(
          id: 'two',
          authorId: 'other',
          text: 'Segunda',
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 24)),
        ),
      ],
      serverTime: now,
    );
    final session = controller(HomeFeedFake(), stories: stories);
    await tester.pumpWidget(
      testApp(
        StoryViewer(
          stories: batch.stories,
          batch: batch,
          repository: stories,
          profiles: const {},
          controller: session,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Primera'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });
  testWidgets('resuming the app keeps stories paused behind a profile', (
    tester,
  ) async {
    final stories = StoriesFake();
    final now = DateTime.now();
    final batch = StoryBatch(
      stories: [
        Story(
          id: 'one',
          authorId: 'other',
          text: 'Primera',
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 24)),
        ),
      ],
      serverTime: now,
    );
    final session = controller(HomeFeedFake(), stories: stories);
    final router = GoRouter(
      initialLocation: '/base',
      routes: [
        GoRoute(
          path: '/base',
          builder: (_, _) => const Scaffold(body: Text('Base')),
        ),
        GoRoute(
          path: '/viewer',
          builder: (_, _) => StoryViewer(
            stories: batch.stories,
            batch: batch,
            repository: stories,
            profiles: const {},
            controller: session,
          ),
        ),
        GoRoute(
          path: '/people/:id',
          builder: (_, _) => const Scaffold(body: Text('Perfil abierto')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    router.push('/viewer');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.tap(find.text('Historia'));
    await tester.pump(const Duration(milliseconds: 500));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Perfil abierto'), findsOneWidget);
    final playback =
        tester
                .widget<AnimatedBuilder>(
                  find.byWidgetPredicate(
                    (widget) =>
                        widget is AnimatedBuilder &&
                        widget.animation is AnimationController &&
                        (widget.animation as AnimationController).duration ==
                            const Duration(seconds: 5),
                    skipOffstage: false,
                  ),
                )
                .animation
            as AnimationController;
    expect(
      playback.isAnimating,
      isFalse,
      reason:
          'the controller stays paused even when its ticker is muted by the route',
    );
    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Primera'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    session.dispose();
  });
  testWidgets('following does not show success when persistence fails', (
    tester,
  ) async {
    final feed = HomeFeedFake()..failFollow = true;
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: FollowButton(repository: feed, authorId: 'other'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguir'));
    await tester.pumpAndSettle();
    expect(find.text('Seguir'), findsOneWidget);
    expect(find.text('Siguiendo'), findsNothing);
    feed.failFollow = false;
    await tester.tap(find.text('Seguir'));
    await tester.pumpAndSettle();
    expect(find.text('Siguiendo'), findsOneWidget);
  });
}
