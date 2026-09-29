import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/community/presentation/missions_screen.dart';
import 'package:marea/features/profile/presentation/edit_profile_screen.dart';
import 'package:marea/features/profile/presentation/settings_screen.dart';
import '../../support/showcase_repository_fake.dart';
import '../../support/mission_repository_fake.dart';
import '../showcase/showcase_flow_test.dart' as flow;
import '../community/missions_screen_test.dart' as missions;

void main() {
  for (final type in UserType.values) {
    testWidgets('${type.name} tools expose only its professional actions', (
      tester,
    ) async {
      await flow.open(tester, ShowcaseRepositoryFake(), '/profile', type: type);
      await flow.tap(tester, find.text('Herramientas'));
      for (final action in [
        'Agregar obra',
        'Agregar producto',
        'Agregar servicio',
      ]) {
        final expected = switch (type) {
          UserType.general => false,
          UserType.creator => action == 'Agregar obra',
          UserType.entrepreneur => action != 'Agregar obra',
          UserType.business => action == 'Agregar servicio',
        };
        final sheetAction = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(action),
        );
        expect(sheetAction, expected ? findsOneWidget : findsNothing);
      }
      await flow.tap(
        tester,
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Crear misión'),
        ),
      );
      expect(find.byType(MissionComposerScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('compact profile edit and settings controls keep working', (
    tester,
  ) async {
    final router = await flow.open(
      tester,
      ShowcaseRepositoryFake(),
      '/profile',
    );
    await flow.tap(tester, find.text('Editar perfil'));
    expect(find.byType(EditProfileScreen), findsOneWidget);
    router.go('/profile');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Configuración'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('professional shortcut opens editable professional fields', (
    tester,
  ) async {
    await flow.open(
      tester,
      ShowcaseRepositoryFake(),
      '/profile',
      type: UserType.business,
    );
    await flow.tap(tester, find.text('Herramientas'));
    await flow.tap(tester, find.text('Datos profesionales'));
    expect(find.text('Enlace de contacto'), findsOneWidget);
    expect(find.text('Nombre completo'), findsNothing);
  });

  testWidgets('publishing a mission from profile tools opens its detail', (
    tester,
  ) async {
    await missions.openRoute(tester, MissionRepositoryFake(), '/profile');
    await flow.tap(tester, find.text('Herramientas'));
    await flow.tap(
      tester,
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Crear misión'),
      ),
    );
    await missions.validComposer(tester);
    await missions.tapVisible(tester, find.text('Publicar misión'));
    expect(find.byType(MissionDetailScreen), findsOneWidget);
    expect(find.text('Nueva misión publicada'), findsOneWidget);
  });
}
