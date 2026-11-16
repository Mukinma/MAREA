import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/missions/application/mission_catalog_controller.dart';
import 'package:marea/features/location/data/location_repository.dart';
import 'package:marea/features/location/models/location_models.dart';
import 'package:marea/features/map/data/mission_map_repository.dart';
import 'package:marea/features/map/models/mission_map_models.dart';
import 'package:marea/features/profile/models/profile.dart';

void main() {
  testWidgets('debounces typing and discards a late page for the old query', (
    tester,
  ) async {
    final repo = _Community();
    final first = Completer<List<Mission>>();
    repo.responses['mur'] = first.future;
    final controller = _controller(repo);
    addTearDown(controller.dispose);
    controller.start();
    await tester.pump();
    controller.type('mu');
    await tester.pump(const Duration(milliseconds: 150));
    controller.type('mur');
    await tester.pump(const Duration(milliseconds: 299));
    expect(repo.missionQueries, ['']);
    await tester.pump(const Duration(milliseconds: 1));
    expect(repo.missionQueries, ['', 'mur']);
    controller.type('mural');
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.catalog.items.single.title, 'mural');
    first.complete([_mission('mur')]);
    await tester.pump();
    expect(controller.catalog.items.single.title, 'mural');
    controller.type('  ');
    await tester.pump();
    expect(controller.showNearby, isTrue);
    expect(controller.catalog.items.single.title, 'Reciente');
    expect(repo.postCalls, 0);
  });

  testWidgets(
    'filters by category and advances past a raw page with no seats',
    (tester) async {
      final repo = _Community()
        ..missionPages[0] = List.generate(
          30,
          (i) => _mission('full-$i', full: true),
        )
        ..missionPages[30] = [_mission('available')];
      final controller = _controller(repo);
      addTearDown(controller.dispose);
      controller.applyFilters(category: 'arte', radiusKm: 3, target: null);
      await tester.pump();
      expect(repo.missionCalls, [('arte', 0), ('arte', 30)]);
      expect(controller.catalog.items.single.id, 'available');
      expect(controller.catalog.hasMore, isFalse);
    },
  );

  testWidgets(
    'uses actual GPS, orders by distance and marks approximate pins',
    (tester) async {
      final location = _Location()..requiresAction = true;
      final map = _Map();
      final repo = _Community();
      final controller = _controller(repo, location: location, map: map);
      addTearDown(controller.dispose);
      controller.start();
      await tester.pump();
      expect(location.requests, [false]);
      expect(map.calls, 0);
      expect(
        controller.locationFailure?.kind,
        DeviceLocationFailureKind.permissionRequired,
      );
      expect(controller.catalog.items, isNotEmpty);
      await controller.locate(explicit: true);
      expect(location.requests, [false, true]);
      expect(map.calls, 1);
      expect(map.bounds?.isValid, isTrue);
      expect(controller.nearby.map((item) => item.mission.id), [
        'close',
        'farther',
      ]);
      expect(controller.nearby.first.approximate, isTrue);
      expect(controller.nearby.first.meters, closeTo(111, 2));
      controller.applyFilters(category: 'arte', radiusKm: 10, target: null);
      await tester.pump();
      final catalogCalls = repo.missionCalls.length;
      controller.applyFilters(category: 'arte', radiusKm: 1, target: null);
      await tester.pump();
      expect(controller.nearby.map((item) => item.mission.id), ['close']);
      expect(map.filters?.category, 'arte');
      expect(repo.missionCalls, hasLength(catalogCalls));
    },
  );

  testWidgets('refines truncated map results to find the closest missions', (
    tester,
  ) async {
    final map = _Map()
      ..respond = (radius) => radius > 2
          ? MissionMapPage(
              missions: List.generate(
                300,
                (i) => _mission('far-$i', longitude: 179.94),
              ),
              total: 400,
            )
          : MissionMapPage(
              missions: List.generate(
                10,
                (i) => _mission('near-$i', longitude: 179.998 - i * .001),
              ),
              total: 10,
            );
    final controller = _controller(_Community(), map: map);
    addTearDown(controller.dispose);
    controller.start();
    await tester.pump();
    expect(controller.nearby, hasLength(8));
    expect(controller.nearby.first.mission.id, 'near-0');
    expect(map.calls, greaterThan(1));
  });

  testWidgets('a late carousel skips duplicate pages without losing rows', (
    tester,
  ) async {
    final near = _mission('close', longitude: 179.998);
    final pending = Completer<MissionMapPage>();
    final map = _Map()..pending = pending.future;
    final repo = _Community()
      ..missionPages[0] = List.filled(30, near)
      ..missionPages[30] = List.filled(30, near)
      ..missionPages[60] = [_mission('far')];
    final controller = _controller(repo, map: map);
    addTearDown(controller.dispose);
    controller.start();
    await tester.pump();
    expect(controller.visibleMissions.map((mission) => mission.id), ['close']);
    pending.complete(MissionMapPage(missions: [near], total: 1));
    await tester.pump();
    expect(repo.missionCalls.map((call) => call.$2), [0, 30, 60]);
    expect(controller.visibleMissions.map((mission) => mission.id), ['far']);
    expect(controller.catalog.hasMore, isFalse);
    expect(controller.catalog.items.map((mission) => mission.id), [
      'close',
      'far',
    ]);
  });

  testWidgets('exhaustion leaves carousel rows available and load more off', (
    tester,
  ) async {
    final near = _mission('close', longitude: 179.998);
    final map = _Map()
      ..respond = (_) => MissionMapPage(missions: [near], total: 1);
    final repo = _Community()..missionPages[0] = List.filled(30, near);
    final controller = _controller(repo, map: map);
    addTearDown(controller.dispose);
    controller.start();
    await tester.pump();
    expect(repo.missionCalls.map((call) => call.$2), [0, 30]);
    expect(controller.visibleMissions, isEmpty);
    expect(controller.catalog.hasMore, isFalse);
    expect(controller.nearby.single.mission.id, near.id);
    controller.type('close', immediate: true);
    await tester.pump();
    expect(controller.showNearby, isFalse);
    expect(controller.visibleMissions.single.id, near.id);
  });

  testWidgets('start ordering and profile ignore a late recent page', (
    tester,
  ) async {
    final recent = Completer<List<Mission>>();
    final repo = _Community()..responses[''] = recent.future;
    final controller = _controller(repo);
    addTearDown(controller.dispose);
    controller.start();
    await tester.pump();
    controller.applyFilters(
      category: 'musica',
      radiusKm: 3,
      target: UserType.business,
    );
    controller.setOrder(MissionCatalogOrder.startDate);
    await tester.pump();
    recent.complete([_mission('late')]);
    await tester.pump();
    expect(repo.startCalls.single, ('', 'musica', UserType.business, 0));
    expect(controller.visibleMissions.single.id, 'early');
  });

  testWidgets('refreshes GPS without prompting when the user has moved', (
    tester,
  ) async {
    final map = _Map();
    final location = _Location();
    final controller = _controller(_Community(), map: map, location: location);
    addTearDown(controller.dispose);
    controller.start();
    await tester.pump();
    expect(map.bounds?.center.longitude, closeTo(179.999, .00001));
    location.position = const DevicePosition(latitude: 19, longitude: -104);
    await controller.refresh();
    expect(location.requests, [false, false]);
    expect(map.bounds?.center.longitude, closeTo(-104, .00001));
  });

  testWidgets('reverse geocodes only rounded GPS and rejects invalid points', (
    tester,
  ) async {
    final geocoding = _Geocoding();
    final location = _Location()
      ..position = const DevicePosition(
        latitude: 19.05327,
        longitude: -104.31783,
      );
    final controller = MissionCatalogController(
      community: _Community(),
      missionMap: _Map(),
      location: location,
      geocoding: geocoding,
    );
    addTearDown(controller.dispose);
    controller.start();
    await tester.pump();
    expect(geocoding.points.single.latitude, 19.05);
    expect(geocoding.points.single.longitude, -104.32);
    expect(controller.zoneName, 'Manzanillo, Colima');
    location.position = const DevicePosition(latitude: 100, longitude: -104.3);
    await controller.locate();
    expect(controller.hasPosition, isFalse);
    expect(controller.distanceTo(_mission('pin')), isNull);
    expect(geocoding.points, hasLength(1));
    expect(controller.visibleMissions, isNotEmpty);
  });

  testWidgets('searches mission punctuation literally', (tester) async {
    final repo = _Community();
    final controller = _controller(repo);
    addTearDown(controller.dispose);
    controller.type(r'100%_ \\', immediate: true);
    await tester.pump();
    expect(repo.missionQueries, [r'100\%\_ \\\\']);
  });

  testWidgets(
    'saved catalog includes closed missions and reloads after removing one',
    (tester) async {
      final repo = _Community();
      final controller = MissionCatalogController(
        community: repo,
        missionMap: null,
        location: _Location(),
        savedOnly: true,
      );
      addTearDown(controller.dispose);
      controller.start();
      await tester.pump();
      expect(controller.showNearby, isFalse);
      expect(controller.catalog.items.single.status, 'closed');
      expect(controller.isSaved('closed'), isTrue);
      final update = controller.toggleSaved('closed');
      repo.save.complete();
      await update;
      await tester.pump();
      expect(controller.catalog.items, isEmpty);
      expect(repo.savedQueries, ['', '']);
    },
  );

  testWidgets('reverts failed saves and ignores repeated taps in flight', (
    tester,
  ) async {
    final repo = _Community();
    final controller = _controller(repo);
    addTearDown(controller.dispose);
    controller.start();
    await tester.pump();
    final result = controller.toggleSaved('mission');
    expect(controller.isSaved('mission'), isTrue);
    expect(controller.isSaving('mission'), isTrue);
    await controller.toggleSaved('mission');
    expect(repo.saveCalls, 1);
    repo.save.completeError(StateError('offline'));
    expect(await result, isNotNull);
    expect(controller.isSaved('mission'), isFalse);
    expect(controller.isSaving('mission'), isFalse);
  });
}

MissionCatalogController _controller(
  _Community repository, {
  _Location? location,
  _Map? map,
}) => MissionCatalogController(
  community: repository,
  missionMap: map,
  location: location ?? _Location(),
);

class _Community implements CommunityRepository {
  final responses = <String, Future<List<Mission>>>{};
  final missionPages = <int, List<Mission>>{};
  final missionCalls = <(String?, int)>[];
  final missionQueries = <String>[];
  final savedQueries = <String>[];
  final startCalls = <(String, String?, UserType?, int)>[];
  final savedIds = <String>{'closed'};
  final save = Completer<void>();
  int saveCalls = 0;
  int postCalls = 0;

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

  @override
  Future<List<Mission>> missions({
    String? authorId,
    String query = '',
    String? category,
    UserType? targetType,
    String scope = 'all',
    int offset = 0,
  }) async {
    expectSync(scope, 'discover');
    missionCalls.add((category, offset));
    missionQueries.add(query);
    final response = responses[query];
    if (response != null) return response;
    if (missionPages.isNotEmpty) return missionPages[offset] ?? [];
    return [_mission(query.isEmpty ? 'Reciente' : query)];
  }

  @override
  Future<List<Mission>> missionCatalogByStart({
    String query = '',
    String? category,
    UserType? targetType,
    int offset = 0,
  }) async {
    startCalls.add((query, category, targetType, offset));
    return [_mission('early')];
  }

  @override
  Future<List<Mission>> savedMissions({
    String query = '',
    String? category,
    UserType? targetType,
    int offset = 0,
  }) async {
    savedQueries.add(query);
    return savedIds.contains('closed')
        ? [_mission('closed', status: 'closed')]
        : [];
  }

  @override
  Future<Set<String>> savedMissionIds() async => savedIds.toSet();

  @override
  Future<void> setMissionSaved(String id, bool saved) async {
    saveCalls++;
    await save.future;
    if (saved) {
      savedIds.add(id);
    } else {
      savedIds.remove(id);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Geocoding extends LocationRepository {
  final points = <PostCoordinates>[];

  @override
  Future<LocationPlace?> reverse(PostCoordinates coordinates) async {
    points.add(coordinates);
    return LocationPlace(
      label: 'Manzanillo',
      coordinates: coordinates,
      city: const LocationCity(name: 'Manzanillo', region: 'Colima'),
    );
  }

  @override
  Future<List<LocationPlace>> search(String query) async => [];

  @override
  Future<LocationCity?> resolveContentCity({
    required String contentKind,
    required String contentId,
    required PostCoordinates coordinates,
  }) async => null;
}

class _Location implements DeviceLocationService {
  final requests = <bool>[];
  bool requiresAction = false;
  DevicePosition position = const DevicePosition(
    latitude: 0,
    longitude: 179.999,
  );

  @override
  Future<DevicePosition> current({
    bool requestPermission = false,
    bool Function()? isCurrent,
  }) async {
    requests.add(requestPermission);
    if (requiresAction && !requestPermission) {
      throw const DeviceLocationFailure(
        DeviceLocationFailureKind.permissionRequired,
      );
    }
    return position;
  }

  @override
  Future<bool> openSettings({bool locationDisabled = false}) async => true;
}

class _Map implements MissionMapRepository {
  int calls = 0;
  MapBounds? bounds;
  MissionMapFilters? filters;
  MissionMapPage Function(double)? respond;
  Future<MissionMapPage>? pending;

  @override
  Future<MissionMapPage> fetch({
    required MapBounds bounds,
    required MissionMapFilters filters,
    required String query,
    required DateTime now,
  }) async {
    calls++;
    this.bounds = bounds;
    this.filters = filters;
    if (pending case final value?) return value;
    if (respond case final answer?) return answer(filters.radiusKm!);
    return MissionMapPage(
      missions: [
        _mission('outside', longitude: -179.8),
        _mission('farther', longitude: -179.98),
        _mission('close', longitude: 179.998, approximate: true),
        _mission('unlocated'),
      ],
      total: 4,
    );
  }
}

Mission _mission(
  String id, {
  double? longitude,
  bool approximate = false,
  bool full = false,
  String status = 'open',
}) => Mission(
  id: id,
  authorId: 'other-user',
  title: id,
  body: '',
  category: 'arte',
  location: 'Manzanillo',
  startsAt: DateTime.utc(2100),
  capacity: 1,
  status: status,
  acceptedCount: full ? 1 : 0,
  createdAt: DateTime.utc(2026),
  coordinates: longitude == null
      ? null
      : PostCoordinates(
          latitude: 0,
          longitude: longitude,
          precision: approximate
              ? PostLocationPrecision.approximate
              : PostLocationPrecision.exact,
        ),
);
