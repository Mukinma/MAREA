import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/presentation/profile_setup_screen.dart';
import 'package:marea/features/profile/presentation/onboarding_screen.dart';
import '../../support/fakes.dart';
import '../../support/test_app.dart';

class OutdatedProfiles extends FakeProfileRepository {
  bool outdated = true;
  @override
  Future<Profile> updateCurrentProfile(ProfileUpdateInput input) async {
    if (outdated) {
      throw StateError('PGRST204 setup_step missing from schema cache');
    }
    return super.updateCurrentProfile(input);
  }
}

Future<AppSessionController> session(FakeProfileRepository profiles) async {
  final auth = FakeAuthRepository();
  final controller = AppSessionController(
    authRepository: auth,
    profileRepository: profiles,
  );
  await controller.initialize();
  return controller;
}

void main() {
  testWidgets('guide keeps the draft after a schema failure and can retry', (
    tester,
  ) async {
    final profiles = OutdatedProfiles();
    final controller = await session(profiles);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      testApp(ProfileSetupScreen(controller: controller)),
    );
    final name = find.widgetWithText(TextField, 'Nombre artístico');
    await tester.enterText(name, 'Mi nombre conservado');
    await tester.ensureVisible(find.byKey(const Key('setup-save')));
    await tester.tap(find.byKey(const Key('setup-save')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('El servicio de MAREA necesita actualizarse'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(name).controller!.text,
      'Mi nombre conservado',
    );
    expect(profiles.value.setupStep, 0);
    profiles.outdated = false;
    await tester.ensureVisible(find.byKey(const Key('setup-save')));
    await tester.tap(find.byKey(const Key('setup-save')));
    await tester.pumpAndSettle();
    expect(profiles.value.fullName, 'Mi nombre conservado');
    expect(profiles.value.setupStep, 1);
    controller.clearFeedback();
    await tester.pumpWidget(const SizedBox());
  });
  for (final preferencesOnly in [false, true]) {
    testWidgets(
      'logout disposes the ${preferencesOnly ? "preferences" : "guide"} safely',
      (tester) async {
        final controller = await session(FakeProfileRepository());
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          testApp(
            ProfileSetupScreen(
              controller: controller,
              preferencesOnly: preferencesOnly,
            ),
          ),
        );
        await controller.signOut();
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('changing accounts resets the guide draft', (tester) async {
    final profiles = FakeProfileRepository();
    final controller = await session(profiles);
    addTearDown(controller.dispose);
    final router = AppRouter.create(controller)..go('/profile/setup');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    final name = find.widgetWithText(TextField, 'Nombre artístico');
    await tester.enterText(name, 'Borrador de la primera cuenta');
    profiles.value = Profile.fromJson({
      ...sampleProfile.toJson(),
      'id': 'another-account',
      'full_name': 'Segunda cuenta',
    });
    await controller.refreshProfile();
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(name).controller!.text, 'Segunda cuenta');
    await tester.ensureVisible(find.byKey(const Key('setup-save')));
    await tester.tap(find.byKey(const Key('setup-save')));
    await tester.pumpAndSettle();
    expect(profiles.value.fullName, 'Segunda cuenta');
    controller.clearFeedback();
  });

  testWidgets(
    'saved guide progress resumes after reopening and preferences can be cleared',
    (tester) async {
      final profiles = FakeProfileRepository()
        ..value = sampleProfile.copyWith(
          userType: UserType.general,
          interests: ['arte'],
          goals: ['colaborar'],
        );
      final controller = await session(profiles);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        testApp(ProfileSetupScreen(controller: controller)),
      );
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0,
      );
      await tester.ensureVisible(find.byKey(const Key('setup-save')));
      await tester.tap(find.byKey(const Key('setup-save')));
      await tester.pumpAndSettle();
      expect(profiles.value.setupStep, 1);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0.5,
      );
      expect(find.text('Tus intereses'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        testApp(ProfileSetupScreen(controller: controller)),
      );
      expect(find.text('Tus intereses'), findsOneWidget);
      expect(
        tester
            .widget<PreferenceChips>(find.byType(PreferenceChips).first)
            .selected,
        {'arte'},
      );
      final router = GoRouter(
        initialLocation: '/prefs',
        routes: [
          GoRoute(
            path: '/prefs',
            builder: (_, _) => ProfileSetupScreen(
              controller: controller,
              preferencesOnly: true,
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, _) => const Scaffold(body: Text('Perfil guardado')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arte'));
      await tester.ensureVisible(find.text('Conocer y colaborar'));
      await tester.tap(find.text('Conocer y colaborar'));
      await tester.ensureVisible(find.byKey(const Key('setup-save')));
      await tester.tap(find.byKey(const Key('setup-save')));
      await tester.pumpAndSettle();
      expect(profiles.value.interests, isEmpty);
      expect(profiles.value.goals, isEmpty);
      expect(profiles.value.setupStep, 1);
      expect(profiles.value.userType, UserType.general);
      expect(find.text('Perfil guardado'), findsOneWidget);
      controller.clearFeedback();
    },
  );

  for (final type in UserType.values) {
    testWidgets('${type.name} can leave the guide without completing it', (
      tester,
    ) async {
      final profiles = FakeProfileRepository()
        ..value = sampleProfile.copyWith(userType: type);
      final controller = await session(profiles);
      addTearDown(controller.dispose);
      final router = GoRouter(
        initialLocation: '/setup',
        routes: [
          GoRoute(
            path: '/setup',
            builder: (_, _) => ProfileSetupScreen(controller: controller),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, _) => const Scaffold(body: Text('Mi perfil')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('setup-skip')));
      await tester.tap(find.byKey(const Key('setup-skip')));
      await tester.pumpAndSettle();
      expect(find.text('Mi perfil'), findsOneWidget);
      expect(profiles.value.setupStep, 0);
    });

    testWidgets(
      '${type.name} guide fits small screens, enlarged text and keyboard',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final profiles = FakeProfileRepository()
          ..value = sampleProfile.copyWith(userType: type);
        final controller = await session(profiles);
        addTearDown(controller.dispose);
        for (
          var step = 0;
          step <
              (type == UserType.general
                  ? 2
                  : type == UserType.business
                  ? 4
                  : 3);
          step++
        ) {
          profiles.value = profiles.value.copyWith(setupStep: step);
          await controller.refreshProfile();
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(
            testApp(ProfileSetupScreen(controller: controller)),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byKey(const Key('setup-save')));
          expect(
            find.byKey(const Key('setup-save')).hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull, reason: 'step $step');
        }
      },
    );
  }

  testWidgets(
    'a failed save leaves the guide step and data available for retry',
    (tester) async {
      final profiles = FailingProfiles();
      final controller = await session(profiles);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        testApp(ProfileSetupScreen(controller: controller)),
      );
      final name = find.widgetWithText(TextField, 'Nombre artístico');
      await tester.ensureVisible(name);
      await tester.enterText(name, 'Mi nuevo nombre');
      await tester.ensureVisible(find.byKey(const Key('setup-save')));
      await tester.tap(find.byKey(const Key('setup-save')));
      await tester.pumpAndSettle();
      expect(profiles.value.setupStep, 0);
      expect(
        tester.widget<TextField>(name).controller!.text,
        'Mi nuevo nombre',
      );
      profiles.fail = false;
      await tester.tap(find.byKey(const Key('setup-save')));
      await tester.pumpAndSettle();
      expect(profiles.value.fullName, 'Mi nuevo nombre');
      expect(profiles.value.setupStep, 1);
      controller.clearFeedback();
    },
  );
}

class FailingProfiles extends FakeProfileRepository {
  bool fail = true;
  @override
  Future<Profile> updateCurrentProfile(ProfileUpdateInput input) {
    if (fail) throw Exception('network unavailable');
    return super.updateCurrentProfile(input);
  }
}
