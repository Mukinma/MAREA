import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/auth/data/auth_repository.dart';
import 'package:marea/features/legal/legal_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/auth/presentation/register_screen.dart';
import 'package:marea/features/auth/presentation/email_code_screen.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../../support/fakes.dart';
import '../../support/test_app.dart';

void main() {
  test('initial profile can be confirmed without optional preferences', () {
    for (final type in UserType.values) {
      expect(
        InitialProfileInput(
          userType: type,
          interests: const [],
          goals: const [],
        ).validate(),
        isNull,
      );
    }
  });

  testWidgets('recovery reaches its success screen and then Home', (
    tester,
  ) async {
    final auth = FakeAuthRepository()..user = null;
    final controller = AppSessionController(
      authRepository: auth,
      profileRepository: FakeProfileRepository(),
      legalRepository: FakeLegalRepository(),
    );
    await controller.initialize();
    await controller.verifyCode('ana@example.com', '123456', recovery: true);
    addTearDown(controller.dispose);
    addTearDown(auth.close);
    final router = AppRouter.create(controller)..go('/reset-password');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    expect(find.text('Confirmar nueva contraseña'), findsNothing);
    await tester.enterText(
      find.byKey(const Key('recovery-password')),
      'new-test-password-123',
    );
    await tester.ensureVisible(find.text('Guardar contraseña'));
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/password-updated');
    expect(find.text('Contraseña actualizada'), findsOneWidget);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/home');
    controller.clearFeedback();
  });

  for (final rejection in ['invalid token', 'otp_expired']) {
    testWidgets(
      '$rejection allows code retry and preserves autofill and resend wait',
      (tester) async {
        final auth = CodeAuth()
          ..user = null
          ..rejection = rejection;
        final controller = AppSessionController(
          authRepository: auth,
          profileRepository: FakeProfileRepository(),
          legalRepository: FakeLegalRepository(),
        );
        await controller.initialize();
        await controller.sendCode('ana@example.com', recovery: false);
        addTearDown(controller.dispose);
        addTearDown(auth.close);
        final router = GoRouter(
          initialLocation: '/check-email',
          routes: [
            GoRoute(
              path: '/check-email',
              builder: (_, _) => EmailCodeScreen(
                controller: controller,
                recovery: false,
                email: 'ana@example.com',
              ),
            ),
            GoRoute(
              path: '/home',
              builder: (_, _) =>
                  const Scaffold(body: Text('Inicio verificado')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
        );
        await tester.pumpAndSettle();
        final code = find.byKey(const Key('email-code'));
        final input = find.descendant(
          of: code,
          matching: find.byType(TextField),
        );
        expect(
          tester.widget<TextField>(input).autofillHints,
          contains(AutofillHints.oneTimeCode),
        );
        expect(
          tester
              .widget<TextButton>(
                find.widgetWithText(TextButton, 'Reenviar en 60s'),
              )
              .onPressed,
          isNull,
        );
        await tester.enterText(code, '12345678');
        await tester.ensureVisible(find.text('Verificar código'));
        await tester.tap(find.text('Verificar código'));
        await tester.pumpAndSettle();
        expect(find.text('Código incorrecto o vencido.'), findsOneWidget);
        expect(tester.widget<TextField>(input).controller!.text, '12345678');
        auth.rejection = null;
        await tester.enterText(code, '87654321');
        await tester.tap(find.text('Verificar código'));
        await tester.pumpAndSettle();
        expect(find.text('Inicio verificado'), findsOneWidget);
        expect(auth.verifiedCode, '87654321');
        controller.clearFeedback();
      },
    );
  }

  testWidgets('system back returns to the previous registration step', (
    tester,
  ) async {
    final controller = await authenticatedController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(testApp(RegisterScreen(controller: controller)));
    await tester.ensureVisible(find.byKey(const Key('register-type-general')));
    await tester.tap(find.byKey(const Key('register-type-general')));
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('register-name')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('register-name')), findsNothing);
    expect(find.text('¿Qué perfil quieres crear?'), findsOneWidget);
  });

  testWidgets('an occupied username stays inline on the identity step', (
    tester,
  ) async {
    final controller = await authenticatedController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(testApp(RegisterScreen(controller: controller)));
    await tester.ensureVisible(find.byKey(const Key('register-type-business')));
    await tester.tap(find.byKey(const Key('register-type-business')));
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('register-name')), 'Taller');
    await tester.enterText(find.byKey(const Key('register-username')), 'taken');
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Este usuario ya está ocupado.'), findsOneWidget);
    expect(find.byKey(const Key('register-email')), findsNothing);
  });

  for (final type in UserType.values) {
    testWidgets(
      '${type.name} registration preserves identity and has two unchecked consents',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final auth = RecordingAuth()..user = null;
        final controller = AppSessionController(
          authRepository: auth,
          profileRepository: FakeProfileRepository(),
          legalRepository: FakeLegalRepository(),
        );
        await controller.initialize();
        addTearDown(controller.dispose);
        addTearDown(auth.close);
        final router = GoRouter(
          initialLocation: '/register',
          routes: [
            GoRoute(
              path: '/register',
              builder: (_, _) => RegisterScreen(controller: controller),
            ),
            GoRoute(
              path: '/check-email',
              builder: (_, _) => const Scaffold(body: Text('Correo pendiente')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('register-email')), findsNothing);
        await tester.ensureVisible(
          find.byKey(Key('register-type-${type.name}')),
        );
        await tester.tap(find.byKey(Key('register-type-${type.name}')));
        await tester.ensureVisible(find.text('Continuar'));
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('register-name')),
          'Taller Brisa',
        );
        await tester.enterText(
          find.byKey(const Key('register-username')),
          'taller.brisa',
        );
        await tester.ensureVisible(find.text('Continuar'));
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        expect(find.text('Confirmar contraseña'), findsNothing);
        expect(
          tester
              .widget<CheckboxListTile>(find.byKey(const Key('accept-terms')))
              .value,
          isFalse,
        );
        expect(
          tester
              .widget<CheckboxListTile>(find.byKey(const Key('confirm-adult')))
              .value,
          isFalse,
        );
        await tester.ensureVisible(find.byTooltip('Atrás'));
        await tester.tap(find.byTooltip('Atrás'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(
                find.descendant(
                  of: find.byKey(const Key('register-name')),
                  matching: find.byType(TextField),
                ),
              )
              .controller!
              .text,
          'Taller Brisa',
        );
        await tester.ensureVisible(find.text('Continuar'));
        await tester.ensureVisible(find.text('Continuar'));
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('register-email')),
          'ana@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('register-password')),
          'test-password-123',
        );
        await tester.ensureVisible(find.byKey(const Key('accept-terms')));
        await tester.tap(find.byKey(const Key('accept-terms')));
        await tester.ensureVisible(find.byKey(const Key('confirm-adult')));
        await tester.tap(find.byKey(const Key('confirm-adult')));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('register-continue')));
        auth.rejection = type == UserType.general
            ? 'User already registered'
            : type == UserType.creator
            ? 'weak_password'
            : null;
        await tester.tap(find.byKey(const Key('register-continue')));
        await tester.pumpAndSettle();
        if (auth.rejection != null) {
          final emailError = type == UserType.general;
          final field = find.byKey(
            Key(emailError ? 'register-email' : 'register-password'),
          );
          final message = emailError
              ? 'Ya existe una cuenta con este correo.'
              : 'Elige una contraseña nueva y más segura.';
          expect(
            find.descendant(of: field, matching: find.text(message)),
            findsOneWidget,
          );
          await tester.ensureVisible(field);
          await tester.enterText(
            field,
            emailError ? 'nueva@example.com' : 'stronger-test-password-123',
          );
          auth.rejection = null;
          await tester.ensureVisible(
            find.byKey(const Key('register-continue')),
          );
          await tester.tap(find.byKey(const Key('register-continue')));
          await tester.pumpAndSettle();
        }
        expect(auth.type, type);
        expect(find.text('Correo pendiente'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class RecordingAuth extends FakeAuthRepository {
  UserType? type;
  String? rejection;
  @override
  Future<SignUpOutcome> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
    UserType userType = UserType.general,
    LegalConsent? consent,
  }) async {
    type = userType;
    if (rejection != null) throw StateError(rejection!);
    return SignUpOutcome.confirmationRequired;
  }
}

class CodeAuth extends FakeAuthRepository {
  String? rejection;
  String? verifiedCode;
  @override
  Future<void> verifyCode({
    required String email,
    required String code,
    required bool recovery,
  }) async {
    if (rejection != null) throw StateError(rejection!);
    verifiedCode = code;
    await super.verifyCode(email: email, code: code, recovery: recovery);
  }
}
