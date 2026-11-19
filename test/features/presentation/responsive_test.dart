import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/auth/presentation/login_screen.dart';
import 'package:marea/features/auth/presentation/register_screen.dart';
import 'package:marea/features/auth/presentation/welcome_screen.dart';
import 'package:marea/features/auth/presentation/email_code_screen.dart';
import 'package:marea/features/auth/presentation/security_screen.dart';
import 'package:marea/features/profile/presentation/onboarding_screen.dart';
import 'package:marea/features/profile/presentation/edit_profile_screen.dart';
import 'package:marea/features/profile/presentation/profile_screen.dart';
import 'package:marea/features/shell/presentation/app_shell.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

void main() {
  testWidgets(
    'login shows the skyline and signup link in the mobile viewport',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
      tester.view.padding = tester.view.viewPadding;
      addTearDown(tester.view.reset);
      await (FontLoader('NunitoSans')
            ..addFont(rootBundle.load('assets/fonts/NunitoSans-Regular.ttf'))
            ..addFont(rootBundle.load('assets/fonts/NunitoSans-Bold.ttf'))
            ..addFont(rootBundle.load('assets/fonts/NunitoSans-ExtraBold.ttf')))
          .load();
      final controller = await authenticatedController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(testApp(LoginScreen(controller: controller)));
      await tester.pumpAndSettle();

      final landscape = find.byKey(const ValueKey('login-landscape'));
      final signup = find.text('Crea tu cuenta');
      expect(tester.getSize(landscape).height, greaterThan(100));
      expect(
        tester.getTopLeft(landscape).dy,
        greaterThan(tester.getBottomLeft(find.text('Continuar con Google')).dy),
      );
      expect(tester.getBottomLeft(signup).dy, lessThanOrEqualTo(810));
      expect(
        tester.getBottomLeft(landscape).dy,
        lessThanOrEqualTo(tester.getTopLeft(signup).dy),
      );
      expect(signup.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact login remains usable with large text and a keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final controller = await authenticatedController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      testApp(LoginScreen(controller: controller, allowGoogle: false)),
    );
    expect(find.byKey(const Key('login-google')), findsNothing);
    expect(find.byTooltip('Atrás'), findsOneWidget);

    final reveal = find.byTooltip('Mostrar contraseña');
    await tester.ensureVisible(reveal);
    await tester.tap(reveal);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText).last).obscureText,
      isFalse,
    );

    final submit = find.text('Iniciar sesión');
    await tester.ensureVisible(submit);
    expect(submit.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(600, 800),
    const Size(1024, 768),
    const Size(1366, 768),
    const Size(1440, 900),
  ]) {
    testWidgets('auth and social shell fit ${size.width} × ${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = await authenticatedController();
      addTearDown(controller.dispose);

      for (final screen in [
        const WelcomeScreen(),
        LoginScreen(controller: controller),
        RegisterScreen(controller: controller),
        EmailCodeScreen(controller: controller, recovery: false),
        EmailCodeScreen(controller: controller, recovery: true),
        SecurityScreen(controller: controller),
        SecurityScreen(controller: controller, changeEmail: true),
        OnboardingScreen(controller: controller),
        EditProfileScreen(controller: controller),
        AppShell(
          location: '/profile',
          child: ProfileScreen(controller: controller),
        ),
      ]) {
        await tester.pumpWidget(testApp(screen));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${screen.runtimeType}');
      }
    });
  }
}
