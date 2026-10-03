import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/map/models/mission_map_models.dart';
import 'package:marea/features/map/data/mission_map_repository.dart';
import 'package:marea/features/map/application/mission_map_controller.dart';

Mission mission(String id) => Mission(
  id: id,
  authorId: 'author',
  title: 'Arte local',
  body: 'Una oportunidad',
  category: 'arte',
  location: 'Centro',
  startsAt: DateTime(2100),
  capacity: 3,
  createdAt: DateTime(2026),
  coordinates: const PostCoordinates(
    latitude: 19.43,
    longitude: -99.13,
    precision: PostLocationPrecision.approximate,
  ),
);

class ControlledMapRepository implements MissionMapRepository {
  final requests = <Completer<MissionMapPage>>[];
  @override
  Future<MissionMapPage> fetch({
    required MapBounds bounds,
    required MissionMapFilters filters,
    required String query,
    required DateTime now,
  }) {
    final request = Completer<MissionMapPage>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  const bounds = MapBounds(south: 19, west: -100, north: 20, east: -99);
  test(
    'small camera movement is stable but a quarter viewport needs search',
    () {
      expect(
        bounds.changedSignificantly(
          const MapBounds(south: 19.1, west: -100, north: 20.1, east: -99),
        ),
        false,
      );
      expect(
        bounds.changedSignificantly(
          const MapBounds(south: 19.25, west: -100, north: 20.25, east: -99),
        ),
        true,
      );
      expect(
        bounds.changedSignificantly(
          const MapBounds(south: 19, west: -100, north: 20.25, east: -99),
        ),
        true,
      );
    },
  );
  test('bounds crossing the date line have a local center', () {
    const crossing = MapBounds(south: -10, west: 170, north: 10, east: -170);
    expect(crossing.longitudeSpan, 20);
    expect(crossing.center.longitude.abs(), 180);
    expect(crossing.isValid, true);
    expect(
      const MapBounds(south: 30, west: 0, north: 20, east: 1).isValid,
      false,
    );
  });
  test('today is a calendar interval and seven days end at local midnight', () {
    final now = DateTime(2026, 9, 29, 21, 30);
    final today = const MissionMapFilters(
      date: MissionMapDate.today,
    ).dateRange(now);
    expect(today.$1, DateTime(2026, 9, 29));
    expect(today.$2, DateTime(2026, 9, 30));
    final week = const MissionMapFilters(
      date: MissionMapDate.next7Days,
    ).dateRange(now);
    expect(week.$2, DateTime(2026, 10, 6));
  });
  test(
    'selection and camera movement do not fetch; repeated load is deduplicated',
    () async {
      final repo = ControlledMapRepository();
      final state = MissionMapController(repo);
      addTearDown(state.dispose);
      state.updateViewport(bounds);
      final first = state.search();
      final duplicate = state.search();
      expect(repo.requests.length, 1);
      repo.requests.single.complete(
        MissionMapPage(missions: [mission('one')], total: 1),
      );
      await first;
      await duplicate;
      state.select('one');
      expect(state.selected?.id, 'one');
      state.updateViewport(
        const MapBounds(south: 20, west: -100, north: 21, east: -99),
      );
      expect(state.needsAreaSearch, true);
      expect(repo.requests.length, 1);
    },
  );
  test('a stale response cannot overwrite newer filters', () async {
    final repo = ControlledMapRepository();
    final state = MissionMapController(repo);
    addTearDown(state.dispose);
    state.updateViewport(bounds);
    final old = state.search();
    final next = state.applyFilters(
      const MissionMapFilters(category: 'musica'),
    );
    repo.requests[1].complete(
      MissionMapPage(missions: [mission('new')], total: 1),
    );
    await next;
    repo.requests[0].complete(
      MissionMapPage(missions: [mission('old')], total: 1),
    );
    await old;
    expect(state.page.missions.single.id, 'new');
    expect(state.loading, false);
  });
  test('failed refresh preserves results, and retry fetches again', () async {
    final repo = ControlledMapRepository();
    final state = MissionMapController(repo);
    addTearDown(state.dispose);
    state.updateViewport(bounds);
    final first = state.search();
    repo.requests[0].complete(
      MissionMapPage(missions: [mission('one')], total: 12),
    );
    await first;
    final refresh = state.search(force: true);
    repo.requests[1].completeError(Exception('network'));
    await refresh;
    expect(state.page.total, 12);
    expect(state.page.missions.single.id, 'one');
    expect(state.error, isNotNull);
    final retry = state.search();
    expect(repo.requests.length, 3);
    repo.requests[2].complete(const MissionMapPage(missions: [], total: 0));
    await retry;
    expect(state.error, isNull);
    expect(state.selected, isNull);
  });
  test('dispose ignores pending results without notifying', () async {
    final repo = ControlledMapRepository();
    final state = MissionMapController(repo);
    state.updateViewport(bounds);
    final pending = state.search();
    state.dispose();
    repo.requests.single.complete(const MissionMapPage(missions: [], total: 0));
    await pending;
  });
}
