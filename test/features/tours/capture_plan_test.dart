import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/tours/capture/capture_plan.dart';
import 'package:marea/features/tours/models/tour_models.dart';

// Independent angular projection into a rectilinear image, rather than a
// circular radius around its centre. Off-grid probes exercise image corners.
bool sees(CaptureTarget camera, double yaw, double pitch, double h, double v) {
  final azimuth = (yaw - camera.yaw) * math.pi / 180;
  final elevation = pitch * math.pi / 180;
  final tilt = camera.pitch * math.pi / 180;
  final forward =
      math.cos(elevation) * math.cos(azimuth) * math.cos(tilt) +
      math.sin(elevation) * math.sin(tilt);
  if (forward <= 0) return false;
  final right = math.cos(elevation) * math.sin(azimuth);
  final up =
      math.sin(elevation) * math.cos(tilt) -
      math.cos(elevation) * math.cos(azimuth) * math.sin(tilt);
  return math.atan2(right.abs(), forward) < h * math.pi / 360 &&
      math.atan2(up.abs(), forward) < v * math.pi / 360;
}

void main() {
  for (final (h, v) in [
    (38.0, 60.0),
    (40.0, 60.0),
    (45.0, 65.0),
    (50.0, 70.0),
    (65.0, 50.0),
    (80.0, 100.0),
    (120.0, 120.0),
  ]) {
    test('compact $h × $v plan covers the entire sphere within 40 photos', () {
      final plan = CapturePlan.create(hfov: h, vfov: v);
      expect(plan.targets.length, inInclusiveRange(6, CapturePlan.maxTargets));
      expect(
        plan.targets.map((t) => t.id).toSet(),
        hasLength(plan.targets.length),
      );
      expect(plan.targets.first.yaw, 0);
      expect(plan.targets.first.pitch, 0);
      expect(plan.targets.where((t) => t.pitch == 90), hasLength(1));
      expect(plan.targets.where((t) => t.pitch == -90), hasLength(1));
      for (var pitch = -89.63; pitch < 90; pitch += 3) {
        for (var yaw = -179.63; yaw < 180; yaw += 3) {
          expect(
            plan.targets.any((t) => sees(t, yaw, pitch, h, v)),
            isTrue,
            reason: 'Uncovered direction $yaw/$pitch for $h/$v',
          );
        }
      }
      for (final yaw in [-180.0, -179.99, 179.99, 0.0]) {
        for (final pitch in [-90.0, -89.9, 0.0, 89.9, 90.0]) {
          expect(plan.targets.any((t) => sees(t, yaw, pitch, h, v)), isTrue);
        }
      }
      final pitches = plan.targets.map((t) => t.pitch).toSet().toList()..sort();
      for (var i = 1; i < pitches.length; i++) {
        expect(pitches[i] - pitches[i - 1], lessThanOrEqualTo(v * .75 + 1e-8));
      }
      for (final pitch in pitches.where((p) => p.abs() < 90)) {
        final ring = plan.targets.where((t) => t.pitch == pitch).toList()
          ..sort((a, b) => a.yaw.compareTo(b.yaw));
        for (var i = 0; i < ring.length; i++) {
          final next = ring[(i + 1) % ring.length];
          expect(
            angularDistance(ring[i].yaw, pitch, next.yaw, pitch),
            lessThanOrEqualTo(h * .70 + 1e-8),
          );
        }
      }
    });
  }

  test('typical portrait lens replaces the previous 67-photo plan with 35', () {
    final plan = CapturePlan.create(hfov: 40, vfov: 60);
    expect(plan.targets, hasLength(35));
    expect(CapturePlan.fromJson(plan.toJson()).toJson(), plan.toJson());
  });

  test('measured OPPO portrait lens needs 36 photos rather than 67', () {
    final plan = CapturePlan.create(
      hfov: 39.2791466920366,
      vfov: 64.78388988521341,
    );
    expect(plan.targets, hasLength(36));
    expect(plan.targets.first.pitch, 0);
    expect(plan.targets.any((target) => target.pitch == 90), isTrue);
    expect(plan.targets.any((target) => target.pitch == -90), isTrue);
  });

  test('a narrow lens cannot silently truncate an incomplete sphere to 40', () {
    expect(
      () => CapturePlan.create(hfov: 20, vfov: 20),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', contains('40')),
      ),
    );
    for (final value in [double.nan, double.infinity, 0.0, 121.0]) {
      expect(() => CapturePlan.create(hfov: value, vfov: 60), throwsStateError);
    }
  });

  test(
    'restoring a legacy capture preserves every accepted target identity',
    () {
      final original = {
        'hfov': 40.0,
        'vfov': 60.0,
        'targets': [
          for (var i = 0; i < 67; i++)
            {'id': 'legacy-$i', 'yaw': (i * 5.0) % 360 - 180, 'pitch': 0.0},
        ],
      };
      final restored = CapturePlan.fromJson(original);
      expect(restored.targets, hasLength(67));
      expect(restored.toJson(), original);
      expect(restored.targets[35].id, 'legacy-35');
    },
  );
}
