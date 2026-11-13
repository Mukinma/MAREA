import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/ar_markers/data/marker_repository.dart';
import 'package:marea/features/ar_markers/models/ar_marker.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/map/data/mission_map_repository.dart';
import 'package:marea/features/map/models/mission_map_models.dart';
import 'package:marea/features/proximity/data/app_proximity_targets.dart';
import 'package:marea/features/proximity/application/proximity_engine.dart';
import 'package:marea/features/proximity/models/proximity_models.dart';

import '../../support/fakes.dart';
import 'proximity_fixture.dart';

String id(int n) => '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';

Mission mission(
  int n, {
  bool exact = true,
  bool hidden = false,
  String status = 'open',
  bool expired = false,
}) => Mission(
  id: id(n),
  authorId: 'organizer',
  title: 'Mission $n',
  body: '',
  category: 'art',
  location: 'Here',
  startsAt: DateTime.now().add(Duration(days: expired ? -1 : 2)),
  capacity: 10,
  createdAt: DateTime.now(),
  hidden: hidden,
  status: status,
  coordinates: PostCoordinates(
    latitude: 0,
    longitude: 0,
    precision: exact
        ? PostLocationPrecision.exact
        : PostLocationPrecision.approximate,
  ),
);

ArMarker marker(
  int n, {
  bool tested = true,
  bool exact = true,
  bool active = true,
}) => ArMarker({
  'id': id(n),
  'owner_id': 'owner',
  'name': 'Marker $n',
  'latitude': 0.0,
  'longitude': 0.0,
  'location_exact': exact,
  'active': active,
  'reference_version': 'current',
  'tested_version': tested ? 'current' : 'old',
});

class Maps implements MissionMapRepository {
  List<Mission> items = [];
  Completer<void>? pause;
  MapBounds? lastBounds;
  @override
  Future<MissionMapPage> fetch({
    required MapBounds bounds,
    required MissionMapFilters filters,
    required String query,
    required DateTime now,
  }) async {
    lastBounds = bounds;
    await pause?.future;
    return MissionMapPage(missions: items, total: items.length);
  }
}

class Markers implements MarkerRepository {
  List<ArMarker> owned = [], published = [];
  @override
  Future<List<ArMarker>> listOwned(String account) async => owned;
  @override
  Future<List<ArMarker>> nearbyPublic({
    double? latitude,
    double? longitude,
  }) async => published;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test(
    'loads only open exact missions and active current-tested exact markers',
    () async {
      final maps = Maps()
        ..items = [
          mission(1),
          mission(2, exact: false),
          mission(3, hidden: true),
          mission(4, status: 'closed'),
          mission(5, expired: true),
        ];
      final markers = Markers()
        ..owned = [
          marker(6),
          marker(7, tested: false),
          marker(8, exact: false),
          marker(9, active: false),
        ]
        ..published = [marker(6), marker(10)];
      final session = AppSessionController(
        authRepository: FakeAuthRepository(),
        profileRepository: FakeProfileRepository(),
        missionMapRepository: maps,
        markerRepository: markers,
      );
      await session.initialize();
      addTearDown(session.dispose);
      final targets = await AppProximityTargets(session).load(fix());
      expect(targets.map((t) => t.id), [id(1), id(6), id(10)]);
      expect(targets.every((t) => t.isValid), isTrue);
      expect(targets.first.expiresAt, maps.items.first.startsAt);
      expect(maps.lastBounds!.isValid, isTrue);
    },
  );

  test(
    'account change during a network load discards all previous account places',
    () async {
      final maps = Maps()
        ..pause = Completer<void>()
        ..items = [mission(1)];
      final session = AppSessionController(
        authRepository: FakeAuthRepository(),
        profileRepository: FakeProfileRepository(),
        missionMapRepository: maps,
      );
      await session.initialize();
      addTearDown(session.dispose);
      final operation = AppProximityTargets(session).load(fix());
      final expectation = expectLater(operation, throwsStateError);
      await session.signOut();
      maps.pause!.complete();
      await expectation;
    },
  );

  test(
    'cached mission expiration is enforced even without a server refresh',
    () {
      final destination = ProximityTarget(
        id: targetId,
        title: 'Expired',
        route: '/missions/$targetId',
        latitude: 0,
        longitude: 0,
        exact: true,
        kind: ProximityTargetKind.mission,
        expiresAt: testTime,
      );
      // Native Android has the same boundary test in ProximityMathTest.
      expect(
        ProximityEngine().update(
          targets: [destination],
          fix: fix(),
          now: testTime,
        ),
        isEmpty,
      );
      expect(
        ProximityEngine().update(
          targets: [destination],
          fix: fix(timestamp: testTime.subtract(const Duration(seconds: 1))),
          now: testTime.subtract(const Duration(seconds: 1)),
        ),
        hasLength(1),
      );
    },
  );
}
