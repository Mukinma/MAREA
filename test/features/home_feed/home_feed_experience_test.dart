import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import 'package:marea/features/home_feed/models/home_feed_models.dart';
import 'package:marea/features/home_feed/models/story.dart';
import 'package:marea/features/home_feed/presentation/story_composer.dart';
import 'package:marea/features/home_feed/presentation/story_viewer.dart';
import 'package:marea/features/home_feed/presentation/follow_button.dart';
import 'package:marea/features/shell/presentation/app_shell.dart';
import '../../support/fakes.dart';
import '../../support/home_feed_fakes.dart';
import '../../support/test_app.dart';

AppSessionController controller(HomeFeedFake feed, {StoriesFake? stories}) =>
    AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: FakeProfileRepository(),
      communityRepository: HomeCommunityFake(),
      homeFeedRepository: feed,
      storiesRepository: stories,
    );
void main() {
  for (final width in [360.0, 390.0, 600.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'mixed home and six navigation buttons fit $width at $scale',
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
          expect(find.text('Mariana Torres'), findsWidgets);
          expect(find.byTooltip('Inicio'), findsOneWidget);
          expect(find.byTooltip('Misiones'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.drag(find.byType(ListView).first, const Offset(0, -600));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          session.dispose();
        },
      );
    }
  }
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
  testWidgets('opening a story covers the shell navigation', (tester) async {
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
    await tester.tap(find.text('Mariana Torres'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byTooltip('Pausar historia'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Inicio'), findsNothing);
    expect(find.text('Mi historia'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    session.dispose();
  });
  testWidgets('a failed publish retains text and retries the same operation', (
    tester,
  ) async {
    final stories = StoriesFake()..failPublish = true;
    final session = controller(HomeFeedFake(), stories: stories);
    await tester.pumpWidget(testApp(StoryComposer(controller: session)));
    await tester.enterText(find.byType(TextField), 'Mi primera historia');
    await tester.tap(find.text('Publicar historia'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Mi primera historia',
    );
    await tester.tap(find.text('Publicar historia'));
    await tester.pumpAndSettle();
    expect(stories.published.length, 2);
    expect(stories.published[0].id, stories.published[1].id);
    expect(
      tester.widget<TextField>(find.byType(TextField)).enabled,
      isFalse,
      reason: 'ambiguous retries preserve the submitted payload',
    );
    await tester.pumpWidget(const SizedBox());
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
      await tester.tap(find.byTooltip('Pausar historia'));
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('Primera'), findsOneWidget);
      await tester.tap(find.byTooltip('Historia siguiente'));
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
