import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marea/app.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/legal/legal_policy.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/presentation/edit_profile_screen.dart';
import 'package:marea/shared/widgets/primary_button.dart';
import '../../support/fakes.dart';
import '../../support/test_app.dart';

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'marea.mobile_intro.seen': true,
    }),
  );
  testWidgets(
    'recovery keeps the email and destination from a protected link',
    (tester) async {
      final auth = FakeAuthRepository()..user = null;
      final controller = AppSessionController(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
        legalRepository: FakeLegalRepository(),
      );
      addTearDown(auth.close);
      addTearDown(controller.dispose);
      await controller.initialize();
      final router = AppRouter.create(controller)..go('/missions');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login-email')),
        'ana@example.com',
      );
      await tester.tap(find.text('Olvidé mi contraseña'));
      await tester.pumpAndSettle();
      final uri = router.routeInformationProvider.value.uri;
      expect(uri.path, '/recover-password');
      expect(uri.queryParameters['returnTo'], '/missions');
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('code-destination')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller!.text, 'ana@example.com');
    },
  );
  testWidgets(
    'Google continues through legal acceptance and profile selection',
    (tester) async {
      final auth = FakeAuthRepository()..user = null;
      final profiles = FakeProfileRepository()
        ..value = sampleProfile.copyWith(initialProfileCompletedAt: null);
      final controller = AppSessionController(
        authRepository: auth,
        profileRepository: profiles,
        legalRepository: FakeLegalRepository()..accepted = false,
      );
      addTearDown(auth.close);
      addTearDown(controller.dispose);
      await controller.initialize();
      final router = AppRouter.create(controller)
        ..go('/login?returnTo=%2Fmissions');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      );
      await tester.pumpAndSettle();

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tap(find.byKey(const Key('login-google')));
      expect(find.text('Antes de continuar'), findsOneWidget);
      await tap(find.byKey(const Key('accept-terms')));
      await tap(find.byKey(const Key('confirm-adult')));
      await tap(find.text('Aceptar y continuar'));
      expect(find.text('Elige tu perfil'), findsOneWidget);
      await tap(find.byKey(const Key('register-type-creator')));
      await tap(find.text('Confirmar y entrar'));

      expect(router.routeInformationProvider.value.uri.path, '/missions');
      expect(profiles.value.userType, UserType.creator);
    },
  );
  testWidgets(
    'registration keeps its draft through legal reading and clears outdated acceptance',
    (tester) async {
      final legal = VersionedLegalRepository();
      final c = AppSessionController(
        authRepository: FakeAuthRepository()..user = null,
        profileRepository: FakeProfileRepository(),
        legalRepository: legal,
      );
      await tester.pumpWidget(MareaApp(controller: c));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('welcome-register')));
      await tester.tap(find.byKey(const Key('welcome-register')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('register-type-creator')),
      );
      await tester.tap(find.byKey(const Key('register-type-creator')));
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('register-name')), 'Ana');
      await tester.enterText(find.byKey(const Key('register-username')), 'ana');
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      final email = find.byKey(const Key('register-email'));
      final password = find.byKey(const Key('register-password'));
      await tester.enterText(email, 'ana@example.com');
      await tester.enterText(password, 'test-password-123');
      PrimaryButton submit() => tester.widget(
        find.byWidgetPredicate(
          (w) => w is PrimaryButton && w.label == 'Crear cuenta',
        ),
      );
      expect(submit().onPressed, isNull);
      await tester.ensureVisible(find.byKey(const Key('accept-terms')));
      await tester.tap(find.byKey(const Key('accept-terms')));
      await tester.pump();
      expect(submit().onPressed, isNull);
      await tester.ensureVisible(find.byKey(const Key('confirm-adult')));
      await tester.tap(find.byKey(const Key('confirm-adult')));
      await tester.pump();
      expect(submit().onPressed, isNotNull);
      await tester.ensureVisible(find.text('Aviso de privacidad'));
      await tester.tap(find.text('Aviso de privacidad'));
      await tester.pumpAndSettle();
      expect(find.text('Privacidad de prueba'), findsOneWidget);
      expect(find.text('Versión test-1 · México'), findsOneWidget);
      await tester.tap(find.byTooltip('Atrás'));
      await tester.pumpAndSettle();
      String fieldText(Finder field) => tester
          .widget<TextField>(
            find.descendant(of: field, matching: find.byType(TextField)),
          )
          .controller!
          .text;
      expect(fieldText(email), 'ana@example.com');
      expect(fieldText(password), 'test-password-123');
      expect(submit().onPressed, isNotNull);

      legal.privacyVersion = 'test-2';
      await c.reloadLegal();
      await tester.pumpAndSettle();
      expect(submit().onPressed, isNull);
      CheckboxListTile checkbox(String key) =>
          tester.widget(find.byKey(Key(key)));
      expect(checkbox('accept-terms').value, isFalse);
      expect(checkbox('confirm-adult').value, isTrue);
      legal.privacyVersion = 'test-1';
      await c.reloadLegal();
      await tester.pumpAndSettle();
      expect(checkbox('accept-terms').value, isFalse);
    },
  );
  testWidgets('editing prompts before discarding a modified bio', (
    tester,
  ) async {
    final c = await authenticatedController();
    addTearDown(c.dispose);
    await tester.pumpWidget(testApp(EditProfileScreen(controller: c)));
    await tester.pumpAndSettle();
    final bio = find.byKey(const ValueKey('edit-field-Sobre mí'));
    await tester.ensureVisible(bio);
    await tester.enterText(bio, 'Una bio diferente');
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar tus cambios?'), findsOneWidget);
    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar tus cambios?'), findsNothing);
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: bio, matching: find.byType(TextField)),
          )
          .controller!
          .text,
      'Una bio diferente',
    );
    expect(c.profile!.bio, 'Creo experiencias que conectan la ciudad.');
  });

  testWidgets('a public legal document shows loading until it is ready', (
    tester,
  ) async {
    final auth = FakeAuthRepository()..user = null;
    final legal = _LoadingLegal();
    final controller = AppSessionController(
      authRepository: auth,
      profileRepository: FakeProfileRepository(),
      legalRepository: legal,
    );
    addTearDown(auth.close);
    addTearDown(controller.dispose);
    await controller.initialize();
    final router = AppRouter.create(controller)..go('/terms');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.pump();
    expect(find.text('Cargando documento…'), findsOneWidget);
    expect(find.text('Volver a cargar'), findsNothing);

    legal.response.complete(legal.policy);
    await tester.pumpAndSettle();
    expect(find.text('Términos de prueba'), findsOneWidget);
    expect(find.text('Cargando documento…'), findsNothing);
  });

  testWidgets(
    'account credentials retain confirmation and security code flows',
    (tester) async {
      final auth = _CredentialAuth();
      final controller = AppSessionController(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
        legalRepository: FakeLegalRepository(),
      );
      await controller.initialize();
      addTearDown(controller.dispose);
      addTearDown(auth.close);
      final router = AppRouter.create(controller)..go('/settings');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      );
      await tester.pumpAndSettle();

      Future<void> tap(String text) async {
        final control = find.text(text);
        await tester.ensureVisible(control);
        await tester.tap(control);
        await tester.pumpAndSettle();
      }

      Future<void> fill(String label, String value) async {
        final field = find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.labelText == label,
        );
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
        await tester.pump();
      }

      await tap('Mis datos personales');
      expect(find.text('ana@marea.app'), findsOneWidget);
      await tap('Correo electrónico');
      await fill('Contraseña actual', 'actual-password');
      await fill('Nuevo correo', 'ana-nueva@marea.app');
      await tap('Solicitar cambio de correo');
      expect(auth.emailChange, ('ana-nueva@marea.app', 'actual-password'));
      expect(
        find.textContaining('Revisa tu correo actual y el nuevo'),
        findsOneWidget,
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Mis datos personales'), findsOneWidget);
      expect(find.text('ana@marea.app'), findsOneWidget);

      await tap('Cambiar contraseña');
      await tap('Enviar código por correo');
      expect(auth.codesRequested, 1);
      await fill('Contraseña actual', 'actual-password');
      await fill('Nueva contraseña', 'nueva-password');
      await fill('Confirmar nueva contraseña', 'nueva-password');
      await fill('Código de seguridad', '123456');
      await tap('Guardar contraseña');
      expect(auth.passwordChange, (
        'nueva-password',
        'actual-password',
        '123456',
      ));
      expect(find.text('Contraseña actualizada.'), findsOneWidget);
      controller.clearFeedback();
    },
  );

  testWidgets('account deletion closes its dialog before the session changes', (
    tester,
  ) async {
    final auth = DelayedDeleteAuthRepository();
    final profiles = FakeProfileRepository()
      ..value = sampleProfile.copyWith(
        onboardingStatus: OnboardingStatus.completed,
      );
    final c = AppSessionController(
      authRepository: auth,
      profileRepository: profiles,
      legalRepository: FakeLegalRepository(),
    );
    addTearDown(auth.close);
    await tester.pumpWidget(MareaApp(controller: c));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Configuración'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mis datos personales'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-delete-dialog')));
    await tester.tap(find.byKey(const Key('open-delete-dialog')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('delete-confirmation')),
      'ELIMINAR',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-delete-account')));
    await tester.pump();

    expect(auth.deleteStarted.isCompleted, isFalse);
    expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(auth.deleteStarted.isCompleted, isTrue);
    expect(find.text('¿Eliminar tu cuenta?'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(c.status, AuthStatus.authenticated);

    auth.finishDelete.complete();
    await tester.pumpAndSettle();

    expect(c.status, AuthStatus.unauthenticated);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('sign out reaches login through the session guard', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    final profiles = FakeProfileRepository()
      ..value = sampleProfile.copyWith(
        onboardingStatus: OnboardingStatus.completed,
      );
    final c = AppSessionController(
      authRepository: auth,
      profileRepository: profiles,
      legalRepository: FakeLegalRepository(),
    );
    addTearDown(auth.close);
    await tester.pumpWidget(MareaApp(controller: c));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Configuración'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(c.status, AuthStatus.unauthenticated);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('a deletion network failure remains retryable in settings', (
    tester,
  ) async {
    final auth = FailingDeleteAuthRepository();
    final profiles = FakeProfileRepository()
      ..value = sampleProfile.copyWith(
        onboardingStatus: OnboardingStatus.completed,
      );
    final c = AppSessionController(
      authRepository: auth,
      profileRepository: profiles,
      legalRepository: FakeLegalRepository(),
    );
    addTearDown(auth.close);
    await tester.pumpWidget(MareaApp(controller: c));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Configuración'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mis datos personales'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-delete-dialog')));
    await tester.tap(find.byKey(const Key('open-delete-dialog')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('delete-confirmation')),
      'ELIMINAR',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-delete-account')));
    await tester.pumpAndSettle();

    expect(c.status, AuthStatus.authenticated);
    expect(find.text('Mis datos personales'), findsOneWidget);
    expect(
      find.text('No pudimos conectarnos. Inténtalo nuevamente.'),
      findsOneWidget,
    );
  });
}

class _CredentialAuth extends FakeAuthRepository {
  (String, String)? emailChange;
  (String, String?, String?)? passwordChange;
  int codesRequested = 0;

  @override
  Future<void> changeEmail(String email, String currentPassword) async {
    emailChange = (email, currentPassword);
  }

  @override
  Future<void> changePassword(
    String password, {
    String? currentPassword,
    String? nonce,
  }) async {
    passwordChange = (password, currentPassword, nonce);
  }

  @override
  Future<void> requestReauthentication() async {
    codesRequested++;
  }
}

class _LoadingLegal extends FakeLegalRepository {
  final response = Completer<LegalPolicy>();

  @override
  Future<LegalPolicy> loadPolicy() => response.future;
}

class VersionedLegalRepository extends FakeLegalRepository {
  String privacyVersion = 'test-1';

  @override
  Future<LegalPolicy> loadPolicy() async => LegalPolicy(
    signupEnabled: policy.signupEnabled,
    terms: policy.terms,
    privacy: LegalDocument(
      version: privacyVersion,
      title: policy.privacy!.title,
      body: policy.privacy!.body,
    ),
  );
}

class DelayedDeleteAuthRepository extends FakeAuthRepository {
  final deleteStarted = Completer<void>();
  final finishDelete = Completer<void>();

  @override
  Future<void> deleteAccount() async {
    deleteStarted.complete();
    await finishDelete.future;
    await super.deleteAccount();
  }
}

class FailingDeleteAuthRepository extends FakeAuthRepository {
  @override
  Future<void> deleteAccount() async {
    throw const AppFailure('No pudimos conectarnos. Inténtalo nuevamente.');
  }
}
