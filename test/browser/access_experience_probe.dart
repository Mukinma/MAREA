// Visual verification fixture: production widgets and router, isolated fake data.
// flutter run -d web-server -t test/browser/access_experience_probe.dart --web-port 7365
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../support/fakes.dart';
import '../support/mission_repository_fake.dart';
import '../support/showcase_repository_fake.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  final params = Uri.base.queryParameters;
  final screen = params['screen'] ?? 'welcome';
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
  ].contains(screen)) {
    auth.user = null;
  }
  final profiles = FakeProfileRepository()
    ..value = sampleProfile.copyWith(
      userType: type,
      fullName: type == UserType.business ? 'Estudio Brisa' : 'Ana López',
      setupStep: int.tryParse(params['step'] ?? '') ?? 0,
    );
  final controller = AppSessionController(
    authRepository: auth,
    profileRepository: profiles,
    legalRepository: FakeLegalRepository(),
    communityRepository: MissionRepositoryFake(),
    showcaseRepository: ShowcaseRepositoryFake(),
  );
  await controller.initialize();
  if (screen == 'reset-password') {
    await controller.verifyCode('ana@example.com', '123456', recovery: true);
  }
  final router = AppRouter.create(controller)..go('/$screen');
  runApp(
    MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: router,
      locale: const Locale('es', 'MX'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('es', 'MX')],
    ),
  );
}
