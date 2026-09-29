import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/app.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/presentation/edit_profile_screen.dart';
import 'package:marea/shared/widgets/primary_button.dart';
import '../../support/fakes.dart';
import '../../support/test_app.dart';

void main() {
  testWidgets(
    'welcome leads to registration and requires both unchecked declarations',
    (tester) async {
      final c = AppSessionController(
        authRepository: FakeAuthRepository()..user = null,
        profileRepository: FakeProfileRepository(),
        legalRepository: FakeLegalRepository(),
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
      await tester.tap(find.text('Aviso de privacidad'));
      await tester.pumpAndSettle();
      expect(find.text('Privacidad de prueba'), findsOneWidget);
    },
  );
  testWidgets('editing prompts before discarding a modified bio', (
    tester,
  ) async {
    final c = await authenticatedController();
    addTearDown(c.dispose);
    await tester.pumpWidget(testApp(EditProfileScreen(controller: c)));
    await tester.pumpAndSettle();
    final bio = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Bio',
    );
    await tester.ensureVisible(bio);
    await tester.enterText(bio, 'Una bio diferente');
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar tus cambios?'), findsOneWidget);
    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(c.profile!.bio, 'Creo experiencias que conectan la ciudad.');
  });

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
    expect(find.text('Configuración'), findsOneWidget);
    expect(
      find.text('No pudimos conectarnos. Inténtalo nuevamente.'),
      findsOneWidget,
    );
  });
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
