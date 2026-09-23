import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/auth/presentation/email_code_screen.dart';
import 'package:marea/features/auth/presentation/login_screen.dart';
import 'package:marea/shared/widgets/marea_text_field.dart';
import '../../support/fakes.dart';
import '../../support/test_app.dart';

class EmailAuth extends FakeAuthRepository {
  Object? loginError;
  Object? sendError;
  String? recoveryDestination;
  Completer<void>? pendingLogin;
  Completer<void>? pendingSend;
  @override
  Future<void> signIn({required String email, required String password}) async {
    await pendingLogin?.future;
    if (loginError != null) throw loginError!;
    await super.signIn(email: email, password: password);
  }

  @override
  Future<void> requestRecovery(String email) async {
    await pendingSend?.future;
    if (sendError != null) throw sendError!;
    recoveryDestination = email;
  }
}

void main() {
  late EmailAuth auth;
  late AppSessionController controller;
  setUp(() {
    auth = EmailAuth()..user = null;
    controller = AppSessionController(
      authRepository: auth,
      profileRepository: FakeProfileRepository(),
    );
  });
  tearDown(() async {
    controller.dispose();
    await auth.close();
  });

  testWidgets('requesting code disables destination editing until response', (
    tester,
  ) async {
    auth.pendingSend = Completer<void>();
    await tester.pumpWidget(
      testApp(EmailCodeScreen(controller: controller, recovery: true)),
    );
    await tester.enterText(
      find.byKey(const Key('code-destination')),
      'ana@example.com',
    );
    await tester.ensureVisible(find.text('Enviar código'));
    await tester.tap(find.text('Enviar código'));
    await tester.pump();
    final editable = tester.widget<TextField>(find.byType(TextField));
    // Complete the pending operation even when the assertion fails.
    auth.pendingSend!.complete();
    await tester.pumpAndSettle();
    expect(editable.enabled, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('pending login prevents switching to another auth screen', (
    tester,
  ) async {
    auth.pendingLogin = Completer<void>();
    auth.loginError = Exception('invalid_credentials');
    await tester.pumpWidget(testApp(LoginScreen(controller: controller)));
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'ana@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'Password123',
    );
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    final recovery = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Olvidé mi contraseña'),
    );
    final register = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Crear una cuenta'),
    );
    final home = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Inicio'),
    );
    auth.pendingLogin!.complete();
    await tester.pumpAndSettle();
    expect(recovery.onPressed, isNull);
    expect(register.onPressed, isNull);
    expect(home.onPressed, isNull);
  });

  testWidgets('address step explains why resending is temporarily disabled', (
    tester,
  ) async {
    await controller.sendCode('ana@example.com', recovery: true);
    await tester.pumpWidget(
      testApp(
        EmailCodeScreen(
          controller: controller,
          recovery: true,
          email: 'ana@example.com',
        ),
      ),
    );
    expect(find.textContaining('Solicitar de nuevo en'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'login confirmation is contextual and clears when email changes',
    (tester) async {
      auth.loginError = Exception('email_not_confirmed');
      await tester.pumpWidget(testApp(LoginScreen(controller: controller)));
      expect(find.text('Confirmar mi correo'), findsNothing);
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'ana@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'Password123',
      );
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmar mi correo'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'otra@example.com',
      );
      await tester.pump();
      expect(find.text('Confirmar mi correo'), findsNothing);
    },
  );

  testWidgets('wrong password does not offer confirmation', (tester) async {
    auth.loginError = Exception('invalid_credentials');
    await tester.pumpWidget(testApp(LoginScreen(controller: controller)));
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'ana@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'Password123',
    );
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar mi correo'), findsNothing);
  });

  testWidgets(
    'confirmation opened without an address starts with requesting a code',
    (tester) async {
      await tester.pumpWidget(
        testApp(EmailCodeScreen(controller: controller, recovery: false)),
      );
      expect(find.byKey(const Key('email-code')), findsNothing);
      expect(find.text('Enviar código'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'recovery locks destination after request and change clears old code',
    (tester) async {
      await tester.pumpWidget(
        testApp(EmailCodeScreen(controller: controller, recovery: true)),
      );
      await tester.enterText(find.byType(MareaTextField), ' ana@example.com ');
      await tester.ensureVisible(find.text('Enviar código'));
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();
      expect(auth.recoveryDestination, 'ana@example.com');
      expect(find.text('ana@example.com'), findsOneWidget);
      expect(find.byType(MareaTextField), findsOneWidget);
      await tester.enterText(find.byKey(const Key('email-code')), '12345678');
      await tester.ensureVisible(find.text('Cambiar correo'));
      await tester.tap(find.text('Cambiar correo'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('email-code')), findsNothing);
      expect(find.text('12345678'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('provider failure stays on email step with no success', (
    tester,
  ) async {
    auth.sendError = Exception('email_address_not_authorized');
    await tester.pumpWidget(
      testApp(EmailCodeScreen(controller: controller, recovery: true)),
    );
    await tester.enterText(find.byType(MareaTextField), 'ana@example.com');
    await tester.ensureVisible(find.text('Enviar código'));
    await tester.tap(find.text('Enviar código'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email-code')), findsNothing);
    expect(controller.successMessage, isNull);
    expect(controller.failure!.message, contains('servicio de correo'));
    await tester.pumpWidget(const SizedBox());
  });

  test('failed send does not start successful-send cooldown', () async {
    auth.sendError = Exception('email_address_not_authorized');
    expect(
      await controller.sendCode('ana@example.com', recovery: true),
      isFalse,
    );
    expect(controller.emailCooldown('ana@example.com', recovery: true), 0);
  });

  test(
    'accepted request starts cooldown and prevents a second request',
    () async {
      expect(
        await controller.sendCode('ana@example.com', recovery: true),
        isTrue,
      );
      expect(
        controller.emailCooldown('ANA@example.com', recovery: true),
        greaterThan(0),
      );
      expect(
        await controller.sendCode('ana@example.com', recovery: true),
        isFalse,
      );
    },
  );

  test('email delivery failure maps to actionable safe feedback', () {
    expect(
      AppFailureMapper.fromMessage(
        'Error sending recovery email: secret',
      ).message,
      allOf(contains('correo'), isNot(contains('secret'))),
    );
  });
}
