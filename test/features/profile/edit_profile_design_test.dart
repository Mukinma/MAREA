import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/profile/presentation/edit_profile_screen.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('interest changes save with the existing identity and cover', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeProfileRepository()
      ..value = sampleProfile.copyWith(
        interests: ['arte'],
        coverPreset: 'lavanda',
      );
    final controller = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: repository,
      legalRepository: FakeLegalRepository(),
    );
    await controller.initialize();
    addTearDown(controller.dispose);
    final router = GoRouter(
      initialLocation: '/profile/edit',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, _) => const Scaffold(body: Text('Perfil')),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (_, _) => ProfileFlatStyle(
            child: EditProfileScreen(controller: controller),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();
    final editor = find.byType(EditProfileScreen);
    final relief = find.descendant(
      of: editor,
      matching: find.byWidgetPredicate((widget) {
        if (widget is CustomPaint) {
          return widget.foregroundPainter.runtimeType.toString() == '_InsetRelief';
        }
        return widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            ((widget.decoration as BoxDecoration).boxShadow?.isNotEmpty ?? false);
      }),
    );
    expect(relief, findsNothing);
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const ValueKey('edit-field-Nombre completo')),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      sampleProfile.fullName,
    );
    expect(find.text('Guardar'), findsNothing);
    expect(find.text('Guardar cambios'), findsOneWidget);
    expect(find.text('Tipo de perfil'), findsOneWidget);
    expect(find.byTooltip('Añadir intereses'), findsNothing);
    await tester.ensureVisible(find.text('Editar intereses'));
    await tester.tap(find.text('Editar intereses'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Música'));
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    expect(repository.value.interests, ['arte']);
    await tester.tap(find.byKey(const Key('edit-save-button')));
    await tester.pumpAndSettle();
    expect(repository.value.interests, containsAll(['arte', 'musica']));
    expect(repository.value.fullName, sampleProfile.fullName);
    expect(repository.value.username, sampleProfile.username);
    expect(repository.value.bio, sampleProfile.bio);
    expect(repository.value.coverPreset, 'lavanda');
    expect(repository.value.avatarPath, sampleProfile.avatarPath);
    expect(router.routeInformationProvider.value.uri.path, '/profile');
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
