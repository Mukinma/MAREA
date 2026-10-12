import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marea/app.dart';
import 'package:marea/core/session/app_session_controller.dart';

import '../../support/fakes.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> openApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppSessionController(
      authRepository: FakeAuthRepository()..user = null,
      profileRepository: FakeProfileRepository(),
    );
    await tester.pumpWidget(MareaApp(controller: controller));
    // Decorative loops deliberately remain active: do not pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets(
    'first mobile launch shows introduction before access buttons',
    (tester) async {
      await openApp(tester);
      expect(find.byKey(const Key('mobile-intro')), findsOneWidget);
      expect(find.textContaining('Tu ciudad'), findsOneWidget);
      expect(find.byKey(const Key('welcome-register')), findsNothing);
      expect(find.byKey(const Key('welcome-login')), findsNothing);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets(
    'four pages finish at welcome and persist across app restarts',
    (tester) async {
      await openApp(tester);
      for (var page = 1; page < 4; page++) {
        await tester.tap(find.byKey(const Key('intro-next')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(
          tester
              .widget<Semantics>(find.byKey(Key('intro-dot-$page')))
              .properties
              .selected,
          isTrue,
        );
      }
      await tester.tap(find.byKey(const Key('intro-next')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('welcome-register')), findsOneWidget);
      expect(find.byKey(const Key('mobile-intro')), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'marea.mobile_intro.seen',
        ),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await openApp(tester);
      expect(find.byKey(const Key('welcome-login')), findsOneWidget);
      expect(find.byKey(const Key('mobile-intro')), findsNothing);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets(
    'skip on a middle page records completion',
    (tester) async {
      await openApp(tester);
      await tester.tap(find.byKey(const Key('intro-dot-2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        tester
            .widget<Semantics>(find.byKey(const Key('intro-dot-2')))
            .properties
            .selected,
        isTrue,
      );
      await tester.tap(find.text('Saltar'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('welcome-login')), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'marea.mobile_intro.seen',
        ),
        isTrue,
      );
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets(
    'desktop retains the original welcome',
    (tester) async {
      await openApp(tester);
      expect(find.byKey(const Key('welcome-register')), findsOneWidget);
      expect(find.byKey(const Key('mobile-intro')), findsNothing);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.linux,
      TargetPlatform.windows,
    }),
  );
}
