// Browser integration fixture: real AppRouter/screens, isolated repositories.
// It does not log into Supabase or add a route to the production application.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../support/fakes.dart';
import '../support/mission_repository_fake.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.ensureSemantics();
  final repo = MissionRepositoryFake()
    ..value = missionFixture(author: sampleProfile.id)
    ..requests = [application()];
  final controller = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: FakeProfileRepository()
      ..value = sampleProfile.copyWith(
        onboardingStatus: OnboardingStatus.skipped,
      ),
    communityRepository: repo,
  );
  await controller.initialize();
  final router = AppRouter.create(controller)..go('/missions/new');
  runApp(
    MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    ),
  );
}
