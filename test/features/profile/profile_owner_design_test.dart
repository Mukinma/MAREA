import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/presentation/profile_content_sections.dart';
import 'package:marea/features/profile/presentation/profile_sections.dart';
import 'package:marea/features/profile/presentation/profile_waves.dart';
import 'package:marea/features/profile/presentation/settings_screen.dart';
import 'package:marea/features/shell/presentation/marea_mobile_navigation.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/shared/widgets/profile_image.dart';
import '../../support/fakes.dart';
import '../../support/mission_repository_fake.dart';
import '../../support/showcase_repository_fake.dart';
import '../showcase/showcase_flow_test.dart' as flow;

class _Directory extends MissionRepositoryFake {
  _Directory(this.type);
  final UserType type;
  final requestedProfiles = <String>[];
  final requestedMissions = <String?>[];
  @override
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  }) async {
    requestedProfiles.addAll(ids ?? []);
    // Intentionally unordered to exercise the screen's owner-ID check.
    return [
      CommunityProfile.fromJson(sampleProfile.toJson()),
      CommunityProfile(
        id: 'visited',
        fullName: 'Nombre visitado',
        username: 'visitado',
        userType: type,
        bio: 'Descripción del propietario visitado',
        location: 'Ubicación visitada',
        interests: const ['musica'],
        avatarPath: 'visited/avatar.png',
        coverPath: 'visited/cover.png',
        waveColors: const [0xFF123456, 0xFFABCDEF],
        openToCollaboration: type == UserType.creator,
      ),
    ];
  }

  @override
  Future<List<Mission>> missions({
    String? authorId,
    String query = '',
    String? category,
    UserType? targetType,
    String scope = 'all',
    int offset = 0,
  }) async {
    requestedMissions.add(authorId);
    if (offset != 0) return [];
    return [
      missionFixture(author: 'visited', title: 'Misión del propietario'),
      missionFixture(
        author: 'another',
        title: 'Misión ajena que no debe mostrarse',
      ),
    ];
  }
}

void main() {
  testWidgets('profile section actions align to the trailing edge', (
    tester,
  ) async {
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: ProfileSectionHeading(
                  title: 'Misiones destacadas',
                  action: 'Ver todas',
                  onAction: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopRight(find.byType(TextButton)).dx,
        tester.getTopRight(find.byType(ProfileSectionHeading)).dx,
      );
      expect(tester.takeException(), isNull);
    }
  });
  for (final type in [
    UserType.business,
    UserType.entrepreneur,
    UserType.creator,
  ]) {
    testWidgets(
      '${type.name} visitor sees only the visited owner and a read-only menu',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final directory = _Directory(type);
        final showcase = ShowcaseRepositoryFake()..ownerId = 'visited';
        await showcase.save(
          ShowcaseInput(
            kind: type.showcaseKinds.first,
            title: 'Contenido del propietario',
            body: 'Información real de esta ficha',
            category: 'arte',
            status: ShowcaseStatus.published,
          ),
        );
        showcase.ownerId = sampleProfile.id;
        await showcase.save(
          const ShowcaseInput(
            kind: ShowcaseKind.service,
            title: 'Contenido de la cuenta autenticada',
            body: 'No debe aparecer',
            category: 'arte',
            status: ShowcaseStatus.published,
          ),
        );
        final router = await flow.open(
          tester,
          showcase,
          '/people/visited',
          community: directory,
        );
        expect(directory.requestedProfiles, ['visited']);
        expect(find.text('Nombre visitado'), findsOneWidget);
        expect(find.text(sampleProfile.fullName), findsNothing);
        expect(find.text('Música'), findsOneWidget);
        expect(find.text('Editar intereses'), findsNothing);
        expect(find.text('Editar perfil'), findsNothing);
        expect(
          find.byTooltip('Configuración de tu cuenta').hitTestable(),
          findsOneWidget,
        );
        expect(find.byTooltip('Menú del perfil').hitTestable(), findsOneWidget);
        expect(tester.widget<ProfileWaves>(find.byType(ProfileWaves)).colors, [
          0xFF123456,
          0xFFABCDEF,
        ]);
        final media = tester
            .widgetList<ProfileImage>(find.byType(ProfileImage))
            .map((image) => image.path);
        expect(media, containsAll(['visited/avatar.png', 'visited/cover.png']));
        expect(find.byIcon(Icons.verified), findsNothing);
        expect(find.byType(ProfileStatisticsCard), findsOneWidget);
        expect(find.text('Sin datos'), findsNWidgets(4));
        expect(find.byType(MareaMobileNavigation), findsOneWidget);
        await tester.ensureVisible(find.byType(ProfileShowcasePreview));
        expect(find.text(type.showcaseLabel), findsOneWidget);
        expect(find.text('Contenido del propietario'), findsOneWidget);
        expect(find.text('Contenido de la cuenta autenticada'), findsNothing);
        await tester.ensureVisible(find.byType(ProfileMissionsPreview));
        expect(find.text('Misión del propietario'), findsOneWidget);
        expect(find.text('Misión ajena que no debe mostrarse'), findsNothing);
        expect(directory.requestedMissions, everyElement('visited'));
        await tester.ensureVisible(find.text('Ver todas ›'));
        await tester.tap(find.text('Ver todas ›'));
        await tester.pumpAndSettle();
        expect(find.text('Misiones del perfil'), findsOneWidget);
        expect(find.byTooltip('Crear').hitTestable(), findsNothing);
        expect(directory.requestedMissions, everyElement('visited'));
        await tester.tap(find.byTooltip('Cerrar lista'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Ver todo ›'));
        await tester.tap(find.text('Ver todo ›'));
        await tester.pumpAndSettle();
        expect(find.text('Contenido de la cuenta autenticada'), findsNothing);
        expect(find.text('Agregar servicio'), findsNothing);
        await tester.tap(find.byTooltip('Cerrar lista'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('Menú del perfil'));
        await tester.tap(find.byTooltip('Menú del perfil'));
        await tester.pumpAndSettle();
        expect(find.text('Opciones del perfil'), findsOneWidget);
        expect(find.text('Datos profesionales'), findsNothing);
        expect(find.text('Crear misión'), findsNothing);
        expect(find.text('Tus herramientas'), findsNothing);
        await tester.tap(find.byTooltip('Cerrar menú'));
        await tester.pumpAndSettle();
        expect(find.text('Opciones del perfil'), findsNothing);
        await tester.tap(find.byTooltip('Configuración de tu cuenta'));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsScreen), findsOneWidget);
        router.go('/people/visited');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('profile uses the shared mobile navigation', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = await flow.open(
      tester,
      ShowcaseRepositoryFake(),
      '/profile',
    );
    expect(find.byType(MareaMobileNavigation), findsOneWidget);
    expect(find.byTooltip('Crear'), findsNothing);
    await tester.tap(find.byTooltip('Descubrir'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/discover');
    router.go('/profile');
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(MareaMobileNavigation),
        matching: find.text('Inicio'),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(tester.takeException(), isNull);
  });
}
