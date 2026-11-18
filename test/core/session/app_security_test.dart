import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/auth/data/auth_repository.dart';
import 'package:marea/features/auth/presentation/account_security_screen.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

class _ProtectedAuth extends FakeAuthRepository
    implements AuthSecurityRepository {
  bool challenge = true;
  bool networkFailure = false;
  bool recoveryIntention = false;
  int otherSignOuts = 0;
  bool enrolled = true;

  @override
  Future<void> requireAppSession() async {
    if (networkFailure) throw const AppFailure('Servicio no disponible.');
    if (challenge) {
      throw const AppFailure(
        'Completa el segundo paso.',
        kind: AppFailureKind.mfaRequired,
      );
    }
  }

  @override
  Future<bool> restoreRecoveryIntent() async => recoveryIntention;
  @override
  Future<void> rememberRecoveryIntent(bool value) async {
    recoveryIntention = value;
  }

  @override
  Future<List<AuthenticatorFactor>> authenticatorFactors() async => [
    if (enrolled) const AuthenticatorFactor(id: 'primary', name: 'Principal'),
  ];
  @override
  Future<AuthenticatorEnrollment> enrollAuthenticator() async =>
      const AuthenticatorEnrollment(
        id: 'primary',
        uri: 'otpauth://totp/MAREA:test?secret=JBSWY3DPEHPK3PXP&issuer=MAREA',
        secret: 'JBSWY3DPEHPK3PXP',
      );
  @override
  Future<void> verifyAuthenticator(String id, String code) async {
    if (code == '123456') {
      challenge = false;
      enrolled = true;
    } else {
      throw const AppFailure('Código incorrecto.');
    }
  }

  @override
  Future<void> removeAuthenticator(String id) => throw UnimplementedError();
  @override
  Future<void> signOutOtherSessions() async {
    otherSignOuts++;
  }
}

void main() {
  testWidgets('security enrollment fits at 320 dp with 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final auth = _ProtectedAuth()
      ..challenge = false
      ..enrolled = false;
    final controller = AppSessionController(
      authRepository: auth,
      profileRepository: FakeProfileRepository(),
      legalRepository: FakeLegalRepository(),
    );
    addTearDown(auth.close);
    addTearDown(controller.dispose);
    await controller.initialize();
    await tester.pumpWidget(
      testApp(AccountSecurityScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    final start = find.text('Activar verificación');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    final qr = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label ==
              'Código QR para configurar tu autenticador',
    );
    expect(qr, findsOneWidget);
    final reveal = find.text('Mostrar clave manual');
    await tester.ensureVisible(reveal);
    await tester.tap(reveal);
    await tester.pumpAndSettle();
    expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);

    final field = find.widgetWithText(TextField, 'Código de autenticación');
    await tester.ensureVisible(field);
    await tester.enterText(field, '000000');
    await tester.pump();
    final activate = find.text('Verificar y activar');
    await tester.ensureVisible(activate);
    await tester.tap(activate);
    await tester.pumpAndSettle();
    expect(controller.failure?.message, 'Código incorrecto.');

    await tester.ensureVisible(field);
    await tester.enterText(field, '123456');
    await tester.pump();
    await tester.ensureVisible(activate);
    await tester.tap(activate);
    await tester.pumpAndSettle();
    expect(find.text('Principal'), findsOneWidget);
    expect(qr, findsNothing);
    expect(tester.takeException(), isNull);
  });

  test(
    'second factor gates restored recovery until verification succeeds',
    () async {
      final auth = _ProtectedAuth()..recoveryIntention = true;
      final controller = AppSessionController(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
        legalRepository: FakeLegalRepository(),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(controller.needsMfa, isTrue);
      expect(controller.profile, isNull);
      expect(controller.isRecovering, isTrue);
      expect(
        await controller.verifyAuthenticator('primary', '000000'),
        isFalse,
      );
      expect(controller.needsMfa, isTrue);
      expect(await controller.verifyAuthenticator('primary', '123456'), isTrue);
      expect(controller.needsMfa, isFalse);
      expect(controller.profile, isNotNull);
      expect(controller.isRecovering, isTrue);
      expect(await controller.changePassword('password-new'), isTrue);
      expect(auth.recoveryIntention, isFalse);
    },
  );

  test('network failures deny restored access and can be retried', () async {
    final auth = _ProtectedAuth()..networkFailure = true;
    final controller = AppSessionController(
      authRepository: auth,
      profileRepository: FakeProfileRepository(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(controller.needsMfa, isTrue);
    expect(controller.securityCheckFailed, isTrue);
    expect(controller.profile, isNull);
    auth
      ..networkFailure = false
      ..challenge = false;
    await controller.recheckAppSession();
    expect(controller.needsMfa, isFalse);
    expect(controller.status, AuthStatus.authenticated);
    expect(await controller.signOutOtherSessions(), isTrue);
    expect(auth.otherSignOuts, 1);
    expect(controller.status, AuthStatus.authenticated);
  });
}
