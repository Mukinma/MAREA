import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/auth/presentation/login_screen.dart';
import 'package:marea/features/auth/presentation/register_screen.dart';
import 'package:marea/features/auth/presentation/check_email_screen.dart';
import 'package:marea/features/auth/presentation/configuration_screen.dart';
import 'package:marea/features/profile/presentation/edit_profile_screen.dart';
import 'package:marea/features/profile/presentation/profile_screen.dart';
import 'package:marea/features/profile/presentation/settings_screen.dart';
import 'package:marea/features/shell/presentation/app_shell.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';

void main() {
  late AppSessionController controller;

  setUp(() async {
    controller = await authenticatedController();
  });

  tearDown(() => controller.dispose());

  testWidgets('login presents a social welcome and validated credentials', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(LoginScreen(controller: controller)));

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(
      find.text('Descubre personas, proyectos y lugares cerca de ti.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('login-email')), findsOneWidget);
    expect(find.byKey(const Key('login-password')), findsOneWidget);
    expect(find.text('Crear una cuenta'), findsOneWidget);
  });

  testWidgets('register explains the public username identity', (tester) async {
    await tester.pumpWidget(testApp(RegisterScreen(controller: controller)));

    expect(find.text('Crea tu lugar en MAREA'), findsOneWidget);
    expect(
      find.text(
        'Este será el nombre con el que otras personas podrán encontrarte.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('register-username')), findsOneWidget);
    expect(find.text('Crear mi cuenta'), findsOneWidget);
  });

  testWidgets('login exposes natural validation instead of technical errors', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(LoginScreen(controller: controller)));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.text('Escribe tu correo.'), findsOneWidget);
    expect(find.text('Escribe una contraseña.'), findsOneWidget);
  });

  testWidgets('check-email explains the manual return flow', (tester) async {
    await tester.pumpWidget(
      testApp(const CheckEmailScreen(email: 'ana@marea.app')),
    );

    expect(find.text('Revisa tu correo'), findsOneWidget);
    expect(find.textContaining('ana@marea.app'), findsOneWidget);
    expect(find.textContaining('vuelve a MAREA'), findsOneWidget);
  });

  testWidgets('missing configuration is descriptive and does not expose keys', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ConfigurationScreen(message: 'Falta configurar SUPABASE_URL.'),
    );

    expect(find.text('Falta conectar Supabase'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsWidgets);
    expect(find.textContaining('service_role'), findsNothing);
  });

  testWidgets(
    'profile prioritizes social identity and hides technical fields',
    (tester) async {
      await tester.pumpWidget(testApp(ProfileScreen(controller: controller)));

      expect(find.text('Ana López'), findsOneWidget);
      expect(find.text('@ana'), findsOneWidget);
      expect(find.text('Artista / creador'), findsOneWidget);
      expect(find.text('Editar perfil'), findsOneWidget);
      expect(find.text('user'), findsNothing);
      expect(find.text(sampleProfile.id), findsNothing);
    },
  );

  testWidgets('edit profile contains only user-editable social fields', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(EditProfileScreen(controller: controller)));

    expect(find.text('Editar perfil'), findsOneWidget);
    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.text('Nombre de usuario'), findsOneWidget);
    expect(find.text('Tipo de perfil'), findsOneWidget);
    expect(find.text('Bio'), findsOneWidget);
    expect(find.text(sampleProfile.id), findsNothing);
    expect(find.text('role'), findsNothing);
  });

  testWidgets('mobile profile editor keeps save visible and groups the form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp(EditProfileScreen(controller: controller)));

    expect(find.byKey(const Key('edit-media')), findsOneWidget);
    expect(find.byKey(const Key('edit-identity')), findsOneWidget);
    expect(find.byKey(const Key('edit-about')), findsOneWidget);
    expect(find.byKey(const Key('edit-interests')), findsOneWidget);
    expect(find.byKey(const Key('edit-goals')), findsOneWidget);
    expect(
      find.byKey(const Key('edit-save-button')).hitTestable(),
      findsOneWidget,
    );
    expect(find.text('Vista previa'), findsNothing);
  });

  testWidgets('mobile shell has five branded destinations and central create', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      testApp(const AppShell(location: '/home', child: Text('contenido'))),
    );

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Explorar'), findsOneWidget);
    expect(find.text('Misiones'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.byKey(const Key('create-destination')), findsOneWidget);
  });

  testWidgets('desktop shell uses a navigation rail instead of bottom nav', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      testApp(const AppShell(location: '/profile', child: Text('contenido'))),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('pulling main content down refreshes the current app data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var refreshes = 0;

    await tester.pumpWidget(
      testApp(
        AppShell(
          location: '/profile',
          onRefresh: () async => refreshes++,
          child: ListView(
            key: const Key('refresh-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [SizedBox(height: 100, child: Text('contenido'))],
          ),
        ),
      ),
    );

    await tester.drag(
      find.byKey(const Key('refresh-scroll')),
      const Offset(0, 320),
    );
    await tester.pumpAndSettle();

    expect(refreshes, 1);
  });

  testWidgets('dragging main content with a web mouse refreshes it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var refreshes = 0;

    await tester.pumpWidget(
      testApp(
        AppShell(
          location: '/profile',
          onRefresh: () async => refreshes++,
          child: ListView(
            key: const Key('web-refresh-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [SizedBox(height: 100, child: Text('contenido'))],
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.down(
      tester.getCenter(find.byKey(const Key('web-refresh-scroll'))),
    );
    await gesture.moveBy(const Offset(0, 320));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(refreshes, 1);
  });

  testWidgets('pulling settings down reloads session data', (tester) async {
    final auth = FakeAuthRepository();
    final profiles = FakeProfileRepository();
    final refreshController = AppSessionController(
      authRepository: auth,
      profileRepository: profiles,
      legalRepository: FakeLegalRepository(),
    );
    addTearDown(refreshController.dispose);
    addTearDown(auth.close);
    await refreshController.initialize();
    profiles.value = profiles.value.copyWith(fullName: 'Ana actualizada');

    await tester.pumpWidget(
      testApp(SettingsScreen(controller: refreshController)),
    );
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 320));
    await tester.pumpAndSettle();

    expect(refreshController.profile?.fullName, 'Ana actualizada');
  });

  testWidgets('account deletion remains disabled until ELIMINAR is typed', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(SettingsScreen(controller: controller)));
    await tester.ensureVisible(find.byKey(const Key('open-delete-dialog')));
    await tester.tap(find.byKey(const Key('open-delete-dialog')));
    await tester.pumpAndSettle();

    FilledButton button() =>
        tester.widget(find.byKey(const Key('confirm-delete-account')));

    expect(button().onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('delete-confirmation')),
      'ELIMINAR',
    );
    await tester.pump();
    expect(button().onPressed, isNotNull);
  });
}
