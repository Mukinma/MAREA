import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marea/app.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/auth/data/mobile_intro_store.dart';
import 'package:marea/features/auth/presentation/mobile_intro_screen.dart';
import 'package:marea/features/auth/presentation/welcome_entry_screen.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

class _UnavailableStore implements MobileIntroStore {
  @override
  Future<bool> hasSeenIntro() async => throw StateError('Unavailable');
  @override
  Future<void> markSeenIntro() async => throw StateError('Unavailable');
}

class _PendingStore implements MobileIntroStore {
  final loaded = Completer<bool>();
  @override
  Future<bool> hasSeenIntro() => loaded.future;
  @override
  Future<void> markSeenIntro() async {}
}

void main() {
  setUpAll(() async {
    final fonts = FontLoader('NunitoSans');
    for (final weight in ['Regular', 'SemiBold', 'Bold', 'ExtraBold']) {
      fonts.addFont(rootBundle.load('assets/fonts/NunitoSans-$weight.ttf'));
    }
    await fonts.load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> showIntro(WidgetTester tester, {bool reduced = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: child!,
        ),
        home: MobileIntroScreen(onComplete: () {}),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('preference loading never flashes access buttons', (
    tester,
  ) async {
    final store = _PendingStore();
    await tester.pumpWidget(testApp(WelcomeEntryScreen(store: store)));
    expect(find.byKey(const Key('welcome-register')), findsNothing);
    expect(find.byKey(const Key('mobile-intro')), findsNothing);
    store.loaded.complete(true);
    await tester.pump();
    expect(find.byKey(const Key('welcome-register')), findsOneWidget);
  });

  testWidgets('storage failure still allows skipping to account access', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(WelcomeEntryScreen(store: _UnavailableStore())),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('mobile-intro')), findsOneWidget);
    await tester.tap(find.text('Saltar'));
    await tester.pump();
    expect(find.byKey(const Key('welcome-login')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing an incomplete introduction starts again on page one', (
    tester,
  ) async {
    final store = SharedPreferencesMobileIntroStore();
    await tester.pumpWidget(testApp(WelcomeEntryScreen(store: store)));
    await tester.pump();
    await tester.tap(find.byKey(const Key('intro-dot-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      testApp(WelcomeEntryScreen(store: SharedPreferencesMobileIntroStore())),
    );
    await tester.pump();
    expect(
      tester
          .widget<Semantics>(find.byKey(const Key('intro-dot-0')))
          .properties
          .selected,
      isTrue,
    );
    expect(await store.hasSeenIntro(), isFalse);
  });

  testWidgets('swiping forwards and backwards updates the selected page', (
    tester,
  ) async {
    await showIntro(tester);
    await tester.drag(
      find.byKey(const Key('intro-pages')),
      const Offset(-600, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(
      tester
          .widget<Semantics>(find.byKey(const Key('intro-dot-1')))
          .properties
          .selected,
      isTrue,
    );
    await tester.drag(
      find.byKey(const Key('intro-pages')),
      const Offset(600, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(
      tester
          .widget<Semantics>(find.byKey(const Key('intro-dot-0')))
          .properties
          .selected,
      isTrue,
    );
  });

  testWidgets(
    'reduced motion has no perpetual animation and pages remain usable',
    (tester) async {
      await showIntro(tester, reduced: true);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('intro-dot-1')));
      await tester.pumpAndSettle();
      expect(find.text('Brava'), findsOneWidget);
      final before = tester.getTopLeft(find.text('Brava'));
      await tester.pump(const Duration(seconds: 3));
      expect(tester.getTopLeft(find.text('Brava')), before);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'cards float only on the active page and pause in the background',
    (tester) async {
      await showIntro(tester);
      await tester.tap(find.byKey(const Key('intro-dot-1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));
      final before = tester.getTopLeft(find.text('Brava'));
      await tester.pump(const Duration(milliseconds: 1200));
      expect(tester.getTopLeft(find.text('Brava')).dy, isNot(before.dy));
      // A single active drift controller, with the previous page stopped.
      expect(tester.binding.transientCallbackCount, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final paused = tester.getTopLeft(find.text('Brava'));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.getTopLeft(find.text('Brava')), paused);
      expect(tester.binding.transientCallbackCount, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      expect(tester.getTopLeft(find.text('Brava')).dy, isNot(paused.dy));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('authenticated sessions never show the introduction', (
    tester,
  ) async {
    final controller = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: FakeProfileRepository(),
    );
    await tester.pumpWidget(MareaApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mobile-intro')), findsNothing);
    expect(find.byKey(const Key('welcome-register')), findsNothing);
  });

  testWidgets(
    'completing intro preserves register and login routes on return',
    (tester) async {
      final controller = AppSessionController(
        authRepository: FakeAuthRepository()..user = null,
        profileRepository: FakeProfileRepository(),
        legalRepository: FakeLegalRepository(),
      );
      await controller.initialize();
      addTearDown(controller.dispose);
      final router = AppRouter.create(controller);
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Saltar'));
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('welcome-register')));
      await tester.tap(find.byKey(const Key('welcome-register')));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/register');
      router.go('/welcome');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mobile-intro')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('welcome-login')));
      await tester.tap(find.byKey(const Key('welcome-login')));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/login');
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    for (final scale in [1.0, 1.6, 2.0]) {
      testWidgets(
        'all slides fit ${size.width} × ${size.height} with text scale $scale',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(top: 47, bottom: 34),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: MobileIntroScreen(onComplete: () {}),
            ),
          );
          for (var page = 0; page < 4; page++) {
            await tester.tap(find.byKey(Key('intro-dot-$page')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              tester.getRect(find.byKey(const Key('intro-next'))).bottom,
              lessThanOrEqualTo(size.height - 34),
            );
          }
        },
      );
    }
  }
}
