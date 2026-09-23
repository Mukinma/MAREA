import 'package:flutter/material.dart';
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
