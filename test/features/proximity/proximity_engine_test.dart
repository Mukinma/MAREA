import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/proximity/application/proximity_engine.dart';
import 'package:marea/features/proximity/models/proximity_models.dart';

import 'proximity_fixture.dart';

void main() {
  test('20 meters is inclusive but distances are never rounded into range', () {
    for (final meters in [0.0, 19.99, 20.0, 20.001, 20.49, 21.0]) {
      final entries = ProximityEngine().update(
        targets: [target()],
        fix: fix(meters: meters),
        now: testTime,
      );
      expect(entries, meters <= 20 ? hasLength(1) : isEmpty, reason: '$meters');
      if (entries.isNotEmpty) {
        expect(entries.single.distanceMeters, closeTo(meters, 0.000001));
      }
    }
  });

  test('requires exact coordinates and canonical typed destinations', () {
    final invalid = [
      target(exact: false),
      target(latitude: double.nan),
      target(longitude: double.infinity),
      target(latitude: 90.1),
      target(longitude: -180.1),
      target(route: 'https://example.com/missions/$targetId'),
      target(route: '/missions/$targetId?redirect=/home'),
      target(route: '/missions/$targetId#scan'),
      target(route: '/ar-markers/$targetId/scan'),
      target(id: 'draft'),
    ];
    expect(
      ProximityEngine().update(targets: invalid, fix: fix(), now: testTime),
      isEmpty,
    );
    final entries = ProximityEngine().update(
      targets: [
        target(),
        target(),
        target(kind: ProximityTargetKind.marker),
      ],
      fix: fix(),
      now: testTime,
    );
    expect(entries, hasLength(2));
  });

  test('accepts accuracy 20 and age 30 seconds including their boundaries', () {
    expect(
      ProximityEngine().update(
        targets: [target()],
        fix: fix(
          accuracy: 20,
          timestamp: testTime.subtract(const Duration(seconds: 30)),
        ),
        now: testTime,
      ),
      hasLength(1),
    );
    for (final invalid in [
      fix(accuracy: 20.001),
      fix(accuracy: double.nan),
      fix(accuracy: double.infinity),
      fix(accuracy: -1),
      fix(timestamp: testTime.subtract(const Duration(milliseconds: 30001))),
      fix(timestamp: testTime.add(const Duration(milliseconds: 1))),
      ProximityFix(
        latitude: 91,
        longitude: 0,
        accuracy: 5,
        timestamp: testTime,
      ),
    ]) {
      expect(
        ProximityEngine().update(
          targets: [target()],
          fix: invalid,
          now: testTime,
        ),
        isEmpty,
      );
    }
  });

  test(
    'jitter never repeats an encounter while still inside the exit radius',
    () {
      final engine = ProximityEngine();
      var now = testTime;
      List<ProximityEncounter> move(double meters) => engine.update(
        targets: [target()],
        fix: fix(meters: meters, timestamp: now),
        now: now,
      );
      expect(move(19), hasLength(1));
      for (final meters in [21.0, 29.0, 20.0, 18.0]) {
        now = now.add(const Duration(minutes: 6));
        expect(move(meters), isEmpty);
      }
      now = now.add(const Duration(seconds: 1));
      expect(move(30), isEmpty);
      now = now.add(const Duration(seconds: 1));
      expect(move(20), hasLength(1));
    },
  );

  test(
    'a clear exit and new entry still observe a minimum five minute cooldown',
    () {
      final engine = ProximityEngine(cooldown: const Duration(seconds: 1));
      var now = testTime;
      List<ProximityEncounter> move(double meters) => engine.update(
        targets: [target()],
        fix: fix(meters: meters, timestamp: now),
        now: now,
      );
      expect(engine.cooldown, const Duration(minutes: 5));
      expect(move(0), hasLength(1));
      now = now.add(const Duration(seconds: 10));
      expect(move(31), isEmpty);
      now = now.add(const Duration(seconds: 10));
      expect(move(0), isEmpty);
      now = now.add(const Duration(minutes: 6));
      expect(move(0), isEmpty);
      expect(move(31), isEmpty);
      expect(move(0), hasLength(1));
    },
  );

  test('invalid or reordered GPS cannot manufacture an exit', () {
    final engine = ProximityEngine();
    expect(
      engine.update(targets: [target()], fix: fix(), now: testTime),
      hasLength(1),
    );
    final now = testTime.add(const Duration(minutes: 6));
    engine.update(
      targets: [target()],
      fix: fix(timestamp: now),
      now: now,
    );
    expect(
      engine.update(
        targets: [target()],
        fix: fix(
          meters: 100,
          timestamp: now.subtract(const Duration(seconds: 1)),
        ),
        now: now,
      ),
      isEmpty,
    );
    engine.update(
      targets: [target()],
      fix: fix(meters: 100, accuracy: 50, timestamp: now),
      now: now,
    );
    expect(
      engine.update(
        targets: [target()],
        fix: fix(timestamp: now),
        now: now,
      ),
      isEmpty,
    );
    engine.reset();
    expect(
      engine.update(
        targets: [target()],
        fix: fix(timestamp: now),
        now: now,
      ),
      hasLength(1),
    );
  });
}
