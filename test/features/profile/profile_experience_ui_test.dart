import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/profile/presentation/profile_screen.dart';
import 'package:marea/features/profile/presentation/onboarding_screen.dart';
import '../../support/fakes.dart';
import 'package:marea/shared/widgets/primary_button.dart';
import '../../support/test_app.dart';

void main() {
  testWidgets('initial type and preferences require explicit choices', (
    tester,
  ) async {
    final profiles = FakeProfileRepository()
      ..value = sampleProfile.copyWith(
        initialProfileCompletedAt: null,
        onboardingStatus: OnboardingStatus.pending,
      );
    final c = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: profiles,
    );
    await c.initialize();
    addTearDown(c.dispose);
    await tester.pumpWidget(testApp(OnboardingScreen(controller: c)));
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('register-type-business')));
    await tester.pump();
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNotNull,
    );
    expect(find.text('El tipo de perfil queda fijo.'), findsOneWidget);
    expect(find.text('Ahora no'), findsNothing);
  });
  testWidgets(
    'public presentation hides initial interests and exposes private shortcuts',
    (tester) async {
      final profiles = FakeProfileRepository()
        ..value = sampleProfile.copyWith(interests: ['arte']);
      final c = AppSessionController(
        authRepository: FakeAuthRepository(),
        profileRepository: profiles,
      );
      await c.initialize();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        testApp(Scaffold(body: ProfileScreen(controller: c))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Arte'), findsNothing);
      expect(find.text('Guardados'), findsOneWidget);
      expect(find.text('Mis postulaciones'), findsOneWidget);
    },
  );
}
