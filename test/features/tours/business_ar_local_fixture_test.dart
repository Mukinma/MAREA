import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/map/models/mission_map_models.dart';
import 'package:marea/features/tours/models/business_ar_target.dart';

import '../../support/business_ar_fixture.dart';
import '../../support/business_ar_reference.dart';

void main() {
  test(
    'local mission and public reference share their organizer, without writes',
    () async {
      final mission = businessARLocalMission();
      final tours = BusinessARLocalTours('http://127.0.0.1/reference.png');
      final targets = BusinessARTarget.fromPublicTours(
        await tours.publicList(mission.authorId),
        mission.authorId,
      );
      expect(mission.isOpen && !mission.isExpired, isTrue);
      expect(targets, hasLength(1));
      expect(targets.single.point.id, businessARLocalPoint);
      expect(targets.single.point.ar!['width_cm'], businessARReferenceWidthCm);
      expect(await tours.publicList('another-owner'), isEmpty);
      final community = BusinessARLocalCommunity(mission);
      expect(await community.missions(authorId: mission.authorId), [mission]);
      expect(await community.missions(scope: 'history'), isEmpty);
      expect(await community.posts(authorId: mission.authorId), isEmpty);
      expect(await community.savedMissionIds(), isEmpty);
      expect(
        await BusinessARLocalShowcase().items(ownerId: mission.authorId),
        isEmpty,
      );
      expect(await tours.requests(), isEmpty);
      expect(
        (await tours.progress(
          businessARLocalTour,
          'local-fixture-public-v1',
        )).revisionId,
        'local-fixture-public-v1',
      );
      expect(
        () => tours.reportAR(
          businessARLocalTour,
          businessARLocalPoint,
          businessARReferenceVersion,
          'android',
          30,
        ),
        throwsA(isA<AppFailure>()),
      );
      expect(
        () => BusinessARLocalCommunity(
          mission,
        ).setMissionStatus(mission.id, 'closed'),
        throwsA(isA<AppFailure>()),
      );
    },
  );

  test('map fixture respects viewport, category and future dates', () async {
    final now = DateTime.utc(2026, 10, 30, 12);
    final map = BusinessARLocalMap(businessARLocalMission(now: now));
    const nearby = MapBounds(
      south: 19.4,
      west: -99.2,
      north: 19.5,
      east: -99.1,
    );
    Future<int> count(
      MapBounds bounds,
      MissionMapFilters filters,
      DateTime at,
    ) async => (await map.fetch(
      bounds: bounds,
      filters: filters,
      query: '',
      now: at,
    )).total;
    expect(await count(nearby, const MissionMapFilters(), now), 1);
    expect(
      await count(nearby, const MissionMapFilters(category: 'musica'), now),
      0,
    );
    expect(
      await count(
        nearby,
        const MissionMapFilters(),
        now.add(const Duration(days: 4)),
      ),
      0,
    );
    expect(
      await count(
        const MapBounds(south: 20, west: -99.2, north: 21, east: -99.1),
        const MissionMapFilters(),
        now,
      ),
      0,
    );
  });

  test(
    'device-local server serves the printable bytes and rejects writes/remote HTTP',
    () async {
      final assets = await BusinessARLocalAssets.start(port: 0);
      final client = BusinessARLoopbackOnly().createHttpClient(null);
      addTearDown(() async {
        client.close(force: true);
        await assets.close();
      });
      final request = await client.getUrl(Uri.parse(assets.referenceUrl));
      final response = await request.close();
      final received = await response.fold<List<int>>(
        [],
        (all, chunk) => all..addAll(chunk),
      );
      expect(response.statusCode, HttpStatus.ok);
      expect(received, orderedEquals(businessARReferencePng()));
      final decoded = image.decodePng(assets.reference)!;
      expect((decoded.width, decoded.height), (1200, 900));
      final post = await client.postUrl(Uri.parse(assets.referenceUrl));
      final rejected = await post.close();
      expect(rejected.statusCode, HttpStatus.methodNotAllowed);
      await rejected.drain<void>();
      await expectLater(
        () => client.getUrl(Uri.parse('https://example.invalid/')),
        throwsA(isA<StateError>()),
      );
    },
  );
}
