import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/auth/presentation/access_layout.dart';
import 'package:marea/features/auth/presentation/email_code_screen.dart';
import 'package:marea/features/auth/presentation/login_screen.dart';
import 'package:marea/features/auth/presentation/register_screen.dart';
import 'package:marea/features/auth/presentation/welcome_screen.dart';
import '../../support/fakes.dart';
import '../../support/test_app.dart';

class EmailAuth extends FakeAuthRepository {
  Object? loginError;
  Object? sendError;
  String? recoveryDestination;
  Completer<void>? pendingLogin;
  Completer<void>? pendingGoogle;
  Completer<void>? pendingSend;
  @override
  Future<void> signIn({required String email, required String password}) async {
    await pendingLogin?.future;
    if (loginError != null) throw loginError!;
    await super.signIn(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle({required String redirectTo}) async {
    await pendingGoogle?.future;
    if (loginError != null) throw loginError!;
    await super.signInWithGoogle(redirectTo: redirectTo);
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
      find.widgetWithText(TextButton, '¿Olvidaste tu contraseña?'),
    );
    final register = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Crea tu cuenta'),
    );
    final back = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.arrow_back_rounded),
    );
    auth.pendingLogin!.complete();
    await tester.pumpAndSettle();
    expect(recovery.onPressed, isNull);
    expect(register.onPressed, isNull);
    expect(back.onPressed, isNull);
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

  testWidgets('login submits an existing short password', (tester) async {
    await tester.pumpWidget(testApp(LoginScreen(controller: controller)));
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'ana@example.com',
    );
    await tester.enterText(find.byKey(const Key('login-password')), 'short');
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(controller.email, 'ana@example.com');
  });

  testWidgets('Google loading stays attached to the Google action', (
    tester,
  ) async {
    auth.pendingGoogle = Completer<void>();
    const message = 'No pudimos abrir Google. Intenta de nuevo.';
    auth.loginError = const AppFailure(message);
    await tester.pumpWidget(testApp(LoginScreen(controller: controller)));
    final google = find.byKey(const Key('login-google'));
    await tester.ensureVisible(google);
    await tester.tap(google);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final emailAction = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Iniciar sesión'),
    );
    final googleAction = tester.widget<AccessGoogleButton>(google);
    auth.pendingGoogle!.complete();
    await tester.pumpAndSettle();

    expect(googleAction.isLoading, isTrue);
    expect(emailAction.onPressed, isNull);
    final alert = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(alert.backgroundColor, AppColors.brandNavy);
    expect(find.text(message), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(tester.widget<AccessGoogleButton>(google).onPressed, isNotNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text(message), findsNothing);
  });

  testWidgets(
    'a welcome Google alert does not follow the user into registration',
    (tester) async {
      const message = 'No pudimos abrir Google. Intenta de nuevo.';
      auth.loginError = const AppFailure(message);
      final router = GoRouter(
        initialLocation: '/welcome',
        routes: [
          GoRoute(
            path: '/welcome',
            builder: (_, _) => WelcomeScreen(controller: controller),
          ),
          GoRoute(
            path: '/register',
            builder: (_, _) => RegisterScreen(controller: controller),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final google = find.byKey(const Key('welcome-google'));
      await tester.ensureVisible(google);
      await tester.tap(google);
      await tester.pumpAndSettle();
      final alert = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(alert.backgroundColor, AppColors.brandNavy);
      expect(find.text(message), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      final register = find.byKey(const Key('welcome-register'));
      await tester.ensureVisible(register);
      await tester.tap(register);
      await tester.pumpAndSettle();
      expect(find.text('Tipo de perfil'), findsOneWidget);
      expect(find.text(message), findsNothing);
    },
  );

  testWidgets('recovery starts with the email entered in login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, _) => LoginScreen(controller: controller),
        ),
        GoRoute(
          path: '/recover-password',
          builder: (_, state) => EmailCodeScreen(
            controller: controller,
            recovery: true,
            email: state.extra as String?,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'ana@example.com',
    );
    final recovery = find.text('¿Olvidaste tu contraseña?');
    await tester.ensureVisible(recovery);
    await tester.tap(recovery);
    await tester.pumpAndSettle();
    final field = tester.widget<AccessTextField>(
      find.byKey(const Key('code-destination')),
    );
    expect(field.controller.text, 'ana@example.com');
    expect(tester.takeException(), isNull);
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
      await tester.enterText(
        find.byKey(const Key('code-destination')),
        ' ana@example.com ',
      );
      await tester.ensureVisible(find.text('Enviar código'));
      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();
      expect(auth.recoveryDestination, 'ana@example.com');
      expect(find.text('ana@example.com'), findsOneWidget);
      expect(find.byKey(const Key('code-destination')), findsNothing);
      await tester.enterText(find.byKey(const Key('email-code')), '12345678');
      await tester.ensureVisible(find.text('Usar otro correo'));
      await tester.tap(find.text('Usar otro correo'));
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
    await tester.enterText(
      find.byKey(const Key('code-destination')),
      'ana@example.com',
    );
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
