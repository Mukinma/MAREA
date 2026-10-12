import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import 'package:marea/features/home_feed/presentation/mission_feed_card.dart';
import 'package:marea/features/community/data/social_repository.dart';
import '../../support/fakes.dart';
import '../../support/home_feed_fakes.dart';

class CardSocial implements SocialRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class PendingPhoto extends HomeCommunityFake {
  @override
  Future<String> imageUrl(String path) => Completer<String>().future;
}

void main() {
  testWidgets('mission save Undo is harmless after its card is removed', (
    tester,
  ) async {
    final repo = HomeCommunityFake();
    final session = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: FakeProfileRepository(),
      communityRepository: repo,
    );
    await session.initialize();
    addTearDown(session.dispose);
    var show = true;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, set) {
              update = set;
              return show
                  ? MissionFeedCard(
                      mission: homeMission(),
                      controller: session,
                      saved: false,
                      onSaved: (_) {},
                      onChanged: () async {},
                    )
                  : const Text('Otra pantalla');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Guardar misión'));
    await tester.pumpAndSettle();
    update(() => show = false);
    await tester.pump();
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(repo.missionSaves, contains('mission'));
  });

  testWidgets('Home photo column lays out while its URL is loading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PostCard(
              post: homePost(imagePath: 'pending'),
              repository: PendingPhoto(),
              socialRepository: CardSocial(),
              viewerId: 'viewer',
              saved: false,
              homePresentation: true,
              onChanged: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Creamos juntos'), findsOneWidget);
  });

  testWidgets('Home posts suppress collaboration while full detail keeps it', (
    tester,
  ) async {
    final repo = HomeCommunityFake();
    final post = homePost();
    // The Home variant must suppress a real allowed collaboration, not its data.
    final session = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: FakeProfileRepository(),
    );
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: PostCard(
            post: post,
            repository: repo,
            socialRepository: CardSocial(),
            viewerId: 'viewer',
            saved: false,
            homePresentation: true,
            onChanged: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(post.title), findsOneWidget);
    expect(find.text('Me interesa colaborar'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PostCard(
              post: post,
              repository: repo,
              socialRepository: CardSocial(),
              viewerId: 'viewer',
              saved: false,
              onChanged: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Me interesa colaborar'), findsOneWidget);
  });

  testWidgets(
    'mission collaboration goes directly to apply and save can undo',
    (tester) async {
      final repo = HomeCommunityFake();
      final controller = AppSessionController(
        authRepository: FakeAuthRepository(),
        profileRepository: FakeProfileRepository(),
        communityRepository: repo,
      );
      await controller.initialize();
      addTearDown(controller.dispose);
      final mission = homeMission();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: SingleChildScrollView(
                child: MissionFeedCard(
                  mission: mission,
                  controller: controller,
                  saved: false,
                  onSaved: (_) {},
                  onChanged: () async {},
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/missions/:id/apply',
            builder: (_, _) =>
                const Scaffold(body: Text('Formulario existente')),
          ),
          GoRoute(
            path: '/missions/:id',
            builder: (_, _) => const Scaffold(body: Text('Detalle existente')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      expect(find.text('Me interesa colaborar'), findsOneWidget);
      expect(find.textContaining('lugares disponibles'), findsNothing);
      await tester.tap(find.byTooltip('Guardar misión'));
      await tester.pumpAndSettle();
      expect(repo.missionSaves, contains(mission.id));
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(repo.missionSaves, isNot(contains(mission.id)));
      await tester.tap(find.text('Me interesa colaborar'));
      await tester.pumpAndSettle();
      expect(find.text('Formulario existente'), findsOneWidget);
    },
  );
}
