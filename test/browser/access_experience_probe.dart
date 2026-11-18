// Visual verification fixture: production widgets and router, isolated fake data.
// flutter run -d web-server -t test/browser/access_experience_probe.dart --web-port 7365
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/auth/presentation/mobile_intro_screen.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../support/fakes.dart';
import '../support/mission_repository_fake.dart';
import '../support/showcase_repository_fake.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  final params = Uri.base.queryParameters;
  final screen = params['screen'] ?? 'welcome';
  final email = params['email'] ?? 'ana@example.com';
  final type =
      UserType.values.where((t) => t.name == params['type']).firstOrNull ??
      UserType.business;
  final auth = FakeAuthRepository();
  if (![
    'profile/setup',
    'profile/preferences',
    'profile',
    'reset-password',
    'password-updated',
    'legal/accept',
    'onboarding',
  ].contains(screen)) {
    auth.user = null;
  }
  final profiles = FakeProfileRepository()
    ..value = sampleProfile.copyWith(
      userType: type,
      fullName: type == UserType.business ? 'Estudio Brisa' : 'Ana López',
      setupStep: int.tryParse(params['step'] ?? '') ?? 0,
    );
  if (screen == 'onboarding') {
    profiles.value = profiles.value.copyWith(initialProfileCompletedAt: null);
  }
  final controller = AppSessionController(
    authRepository: auth,
    profileRepository: profiles,
    legalRepository: FakeLegalRepository()..accepted = screen != 'legal/accept',
    communityRepository: MissionRepositoryFake(),
    showcaseRepository: ShowcaseRepositoryFake(),
  );
  await controller.initialize();
  if (screen == 'reset-password' || screen == 'password-updated') {
    await controller.verifyCode(email, '123456', recovery: true);
  }
  if (screen == 'password-updated') {
    await controller.changePassword('password-for-preview');
  }
  if (screen == 'email-code') {
    await controller.sendCode(email, recovery: false);
  }
  final router = AppRouter.create(controller)
    ..go(
      screen == 'email-code' ? '/check-email' : '/$screen',
      extra: screen == 'email-code' ? email : null,
    );
  Widget routedApp() => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    routerConfig: router,
    locale: const Locale('es', 'MX'),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('es', 'MX')],
  );
  if (screen == 'intro') {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('es', 'MX'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('es', 'MX')],
        home: MobileIntroScreen(
          onComplete: () {
            router.go('/welcome');
            runApp(routedApp());
          },
        ),
      ),
    );
    return;
  }
  runApp(routedApp());
}
