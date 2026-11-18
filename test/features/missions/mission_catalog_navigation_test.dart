import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/maps/map_surface.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/missions_screen.dart';
import 'package:marea/features/missions/application/mission_catalog_controller.dart';
import 'package:marea/features/missions/presentation/mission_catalog_screen.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/map/data/mission_map_repository.dart';
import 'package:marea/features/map/models/mission_map_models.dart';
import 'package:marea/features/map/presentation/mission_map_screen.dart';
import '../../support/fake_map_surface.dart';
import '../../support/fakes.dart';
import '../../support/mission_repository_fake.dart';

void main() {
  testWidgets('local missions fill the spotlight, preview and catalog once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final near = _photographedMission('near', 'Mural del barrio', -104.31);
    final featured = _photographedMission(
      'featured',
      'Retratos del puerto',
      -104.312,
    );
    final remaining = [
      _photographedMission('third', 'Pinta el malecón', -104.314),
      _photographedMission('fourth', 'Festival del puerto', -104.316),
      _photographedMission(
        'fifth',
        'Retratos en Miramar',
        -104.318,
        category: 'fotografia',
        location: 'Ubicación seleccionada (19.12000, -104.31000)',
      ),
    ];
    final community = _DiscoveryCommunity([featured, near, ...remaining]);
    final session = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: FakeProfileRepository()..value = sampleProfile,
      communityRepository: community,
      missionMapRepository: _Map(missions: [near, featured, ...remaining]),
    );
    await session.initialize();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MissionCatalogScreen(
            session: session,
            locationService: const _Location(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ver misión'), findsOneWidget);
    expect(find.byKey(const Key('nearby-mission-featured')), findsNothing);
    expect(find.byKey(const Key('nearby-mission-fifth')), findsNothing);
    expect(find.byKey(const Key('mission-catalog-card-fifth')), findsOneWidget);
    expect(
      find.text('Por ahora, las misiones disponibles están en tu zona.'),
      findsNothing,
    );
    expect(find.text(near.title), findsOneWidget);
    expect(find.text(featured.title), findsOneWidget);
    expect(
      find.byKey(const Key('mission-catalog-card-featured')),
      findsNothing,
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('featured-mission-featured')),
        matching: find.byTooltip('Guardar'),
      ),
    );
    await tester.pumpAndSettle();
    expect(community.missionSaves, {featured.id});

    await tester.enterText(
      find.byKey(const Key('mission-catalog-search')),
      'Retratos del puerto',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Ver misión'), findsNothing);
    expect(find.text('Cerca de ti'), findsNothing);
    expect(
      find.byKey(const Key('mission-catalog-card-featured')),
      findsOneWidget,
    );
    expect(find.byTooltip('Quitar de guardados'), findsOneWidget);

    await tester.tap(find.byTooltip('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    final photo = find.byKey(const Key('mission-catalog-category-fotografia'));
    await tester.ensureVisible(photo);
    await tester.tap(photo);
    await tester.pumpAndSettle();
    final onlyNearby = find.byKey(const Key('nearby-mission-fifth'));
    expect(onlyNearby, findsOneWidget);
    expect(tester.getSize(onlyNearby).width, closeTo(358, 1));
    expect(find.text('Punto en el mapa'), findsOneWidget);
    expect(find.text('Explorar misiones'), findsNothing);
    expect(find.text('Misión destacada'), findsNothing);
    expect(
      find.descendant(
        of: photo,
        matching: find.byIcon(Icons.camera_alt_outlined),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('filters stay synchronized and survive real route pushes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final community = _Community();
    final map = _Map();
    final session = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: FakeProfileRepository()
        ..value = sampleProfile.copyWith(interests: ['fotografia', 'arte']),
      communityRepository: community,
      missionMapRepository: map,
    );
    await session.initialize();
    final router = AppRouter.create(session)..go('/discover');
    addTearDown(session.dispose);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('es', 'MX')],
        builder: (_, child) =>
            MapSurfaceScope(builder: fakeMapSurfaceBuilder, child: child!),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/missions');
    expect(find.byType(MissionCatalogScreen), findsOneWidget);
    expect(find.text('Publicaciones'), findsNothing);
    expect(find.text('Aún no hay una destacada'), findsOneWidget);
    expect(find.text('2 cupos disponibles'), findsOneWidget);
    expect(find.text(community.value.location), findsOneWidget);
    final search = find.byKey(const Key('mission-catalog-search'));
    final photo = find.byKey(const Key('mission-catalog-category-fotografia'));
    final art = find.byKey(const Key('mission-catalog-category-arte'));
    expect(tester.getTopLeft(photo).dx, greaterThan(tester.getTopLeft(art).dx));
    final artIcon = find.descendant(
      of: art,
      matching: find.byIcon(Icons.palette_outlined),
    );
    final artSurface = find
        .descendant(of: art, matching: find.byType(AnimatedContainer))
        .first;
    final defaultDecoration =
        tester.widget<AnimatedContainer>(artSurface).decoration!
            as BoxDecoration;
    expect(artIcon, findsOneWidget);

    await tester.tap(art);
    await tester.pumpAndSettle();
    final selectedDecoration =
        tester.widget<AnimatedContainer>(artSurface).decoration!
            as BoxDecoration;
    expect(artIcon, findsOneWidget);
    expect(selectedDecoration.color, defaultDecoration.color);
    expect(selectedDecoration.border, isNot(defaultDecoration.border));
    await tester.tap(find.byTooltip('Filtros'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mission-catalog-filter-arte')), findsNothing);
    await tester.ensureVisible(find.text('3 km'));
    await tester.tap(find.text('3 km'));
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pumpAndSettle();
    expect(community.lastCategory, 'arte');
    expect(
      tester
          .widget<Semantics>(
            find.descendant(
              of: art,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics && widget.properties.selected == true,
              ),
            ),
          )
          .properties
          .selected,
      isTrue,
    );

    await tester.enterText(search, 'Pintemos & arte');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(community.lastQuery, 'Pintemos & arte');
    expect(community.lastCategory, 'arte');
    expect(community.postCalls, 0);
    expect(find.text('Cerca de ti'), findsNothing);
    await tester.tap(find.byTooltip('Ordenar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(
        CheckedPopupMenuItem<MissionCatalogOrder>,
        'Por fecha de inicio',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver mapa'));
    await tester.pumpAndSettle();
    expect(find.byType(MissionMapScreen), findsOneWidget);
    expect(map.calls, isNotEmpty);
    expect(map.calls.first, ('Pintemos & arte', 'arte'));
    await tester.tap(find.byTooltip('Misiones'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(search).controller!.text,
      'Pintemos & arte',
    );

    final card = find.byKey(const Key('mission-catalog-card-mission-1'));
    await tester.ensureVisible(card);
    final save = find.descendant(of: card, matching: find.byTooltip('Guardar'));
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(community.missionSaves, {community.value.id});
    final scroll = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const Key('mission-catalog-scroll')),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            ),
          ),
        )
        .position;
    scroll.jumpTo(22);
    await tester.pumpAndSettle();
    final offset = scroll.pixels;
    expect(offset, greaterThan(0));
    final savedMissions = find.byTooltip('Misiones guardadas');
    expect(
      tester.getCenter(savedMissions).dy,
      tester.getCenter(find.byTooltip('Filtros')).dy,
    );
    expect(
      tester.getCenter(savedMissions).dx,
      greaterThan(tester.getCenter(find.byTooltip('Filtros')).dx),
    );
    await tester.tap(savedMissions);
    await tester.pumpAndSettle();
    expect(router.state.uri.queryParameters['section'], 'saved');
    expect(find.text('Misiones guardadas'), findsOneWidget);
    expect(find.text('Cerca de ti'), findsNothing);
    expect(search, findsNothing);
    expect(card, findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(scroll.pixels, offset);
    expect(
      tester.widget<TextField>(search).controller!.text,
      'Pintemos & arte',
    );
    expect(
      find.ancestor(
        of: find.byTooltip('Ordenar'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.value == 'Por fecha de inicio',
        ),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(MissionDetailScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(scroll.pixels, greaterThan(0));
    expect(
      find.descendant(
        of: card,
        matching: find.byTooltip('Quitar de guardados'),
      ),
      findsOneWidget,
    );
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(search).controller!.text,
      'Pintemos & arte',
    );
    await tester.tap(find.byTooltip('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text('Cerca de ti'), findsOneWidget);
    expect(community.postCalls, 0);

    router.go('/missions?section=compatible');
    await tester.pumpAndSettle();
    expect(community.lastTarget, UserType.creator);
    await tester.enterText(search, 'Mural');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver mapa'));
    await tester.pumpAndSettle();
    expect(map.calls.last, ('Mural', null));
    await tester.tap(find.byTooltip('Misiones'));
    await tester.pumpAndSettle();
    expect(router.state.uri.queryParameters['section'], 'compatible');
    expect(tester.widget<TextField>(search).controller!.text, 'Mural');

    router.go('/missions?section=drafts');
    await tester.pumpAndSettle();
    expect(find.byType(PersonalMissionsScreen), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Borradores'))
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

class _Community extends MissionRepositoryFake {
  int postCalls = 0;

  @override
  Future<List<Mission>> missionCatalogByStart({
    String query = '',
    String? category,
    UserType? targetType,
    int offset = 0,
  }) async {
    final page = await super.missionCatalogByStart(
      query: query,
      category: category,
      targetType: targetType,
      offset: offset,
    );
    if (page.isEmpty) return page;
    return [
      ...page,
      for (var i = 0; i < 8; i++)
        Mission(
          id: 'extra-$i',
          authorId: value.authorId,
          title: 'Convocatoria de arte $i',
          body: value.body,
          category: value.category,
          location: 'Casa de la Cultura',
          startsAt: value.startsAt.add(Duration(days: i)),
          capacity: value.capacity,
          createdAt: value.createdAt,
        ),
    ];
  }

  @override
  Future<List<CommunityPost>> posts({
    String? authorId,
    String query = '',
    String? category,
    bool savedOnly = false,
    bool discoverOnly = false,
    int offset = 0,
  }) async {
    postCalls++;
    return [];
  }
}

class _Map implements MissionMapRepository {
  _Map({this.missions = const []});

  final List<Mission> missions;
  final calls = <(String, String?)>[];

  @override
  Future<MissionMapPage> fetch({
    required MapBounds bounds,
    required MissionMapFilters filters,
    required String query,
    required DateTime now,
  }) async {
    calls.add((query, filters.category));
    final matching = missions
        .where(
          (mission) =>
              filters.category == null || mission.category == filters.category,
        )
        .toList();
    return MissionMapPage(missions: matching, total: matching.length);
  }
}

class _Location implements DeviceLocationService {
  const _Location();

  @override
  Future<DevicePosition> current({
    bool requestPermission = false,
    bool Function()? isCurrent,
  }) async => const DevicePosition(latitude: 19.05, longitude: -104.31);

  @override
  Future<bool> openSettings({bool locationDisabled = false}) async => false;
}

class _DiscoveryCommunity extends MissionRepositoryFake {
  _DiscoveryCommunity(this.items);

  final List<Mission> items;

  @override
  Future<List<Mission>> missions({
    String? authorId,
    int offset = 0,
    String query = '',
    String? category,
    UserType? targetType,
    String scope = 'all',
  }) async => offset > 0
      ? []
      : items
            .where(
              (mission) =>
                  (category == null || category == mission.category) &&
                  mission.title.contains(query),
            )
            .toList();

  @override
  Future<String> missionImageUrl(String path) async => '';
}

Mission _photographedMission(
  String id,
  String title,
  double longitude, {
  String category = 'arte',
  String location = 'Manzanillo',
}) => Mission(
  id: id,
  authorId: 'organizer',
  title: title,
  body: '',
  category: category,
  location: location,
  startsAt: DateTime.now().add(const Duration(days: 5)),
  capacity: 2,
  createdAt: DateTime.now(),
  imagePath: '$id.webp',
  coordinates: PostCoordinates(
    latitude: 19.05,
    longitude: longitude,
    precision: PostLocationPrecision.approximate,
  ),
);
