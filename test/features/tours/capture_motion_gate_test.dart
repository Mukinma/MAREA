import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/tours/capture/capture_motion_gate.dart';
import 'package:marea/features/tours/capture/capture_plan.dart';

final _epoch = DateTime.utc(2026, 11, 2);
DateTime at(int milliseconds) =>
    _epoch.add(Duration(milliseconds: milliseconds));
const _target = CaptureTarget('front', 0, 0);

void sample(
  CaptureMotionGate gate,
  int milliseconds, {
  double yaw = 0,
  double pitch = 0,
  CaptureTarget? target = _target,
}) =>
    gate.update(yaw: yaw, pitch: pitch, target: target, now: at(milliseconds));

void hold(CaptureMotionGate gate, {int start = 0}) {
  for (final elapsed in [0, 200, 400, 500]) {
    sample(gate, start + elapsed);
  }
}

void main() {
  test('one matching pose cannot stand in for continuous sensor updates', () {
    final gate = CaptureMotionGate();
    expect(gate.aimed, isFalse);
    expect(gate.isFresh(at(0)), isFalse);
    expect(gate.isSteady(at(0)), isFalse);

    sample(gate, 0);
    expect(gate.aimed, isTrue);
    expect(gate.isFresh(at(299)), isTrue);
    expect(gate.isFresh(at(300)), isFalse);
    expect(gate.isSteady(at(200)), isFalse);
    expect(gate.isSteady(at(500)), isFalse);
  });

  test(
    'recent samples held on target enable at 500 ms and expire at 300 ms',
    () {
      final gate = CaptureMotionGate();
      sample(gate, 0);
      sample(gate, 200);
      sample(gate, 400);
      expect(gate.isSteady(at(499)), isFalse);
      sample(gate, 500);
      expect(gate.isSteady(at(500)), isTrue);
      expect(gate.isSteady(at(799)), isTrue);
      expect(gate.isSteady(at(800)), isFalse);
    },
  );

  test('an identical pose after a sensor gap needs a new stable window', () {
    for (final gap in [300, 1200]) {
      final gate = CaptureMotionGate();
      hold(gate);
      final resumed = 500 + gap;
      sample(gate, resumed);
      expect(gate.isFresh(at(resumed)), isTrue);
      expect(gate.isSteady(at(resumed)), isFalse);
      for (final elapsed in [200, 400, 500]) {
        sample(gate, resumed + elapsed);
      }
      expect(gate.isSteady(at(resumed + 500)), isTrue);
    }
  });

  test('reset prevents a new camera session inheriting an accepted pose', () {
    final gate = CaptureMotionGate();
    hold(gate);
    gate.reset();
    expect(gate.aimed, isFalse);
    expect(gate.isFresh(at(510)), isFalse);
    sample(gate, 510);
    expect(gate.isSteady(at(510)), isFalse);
    hold(gate, start: 510);
    expect(gate.isSteady(at(1010)), isTrue);
  });

  test('a changed target id or angles starts another stable window', () {
    for (final target in [
      const CaptureTarget('different-point', 0, 0),
      const CaptureTarget('front', 1, 0),
      const CaptureTarget('front', 0, 1),
    ]) {
      final gate = CaptureMotionGate();
      hold(gate);
      sample(gate, 600, target: target);
      expect(gate.aimed, isTrue);
      expect(gate.isSteady(at(600)), isFalse);
      for (final elapsed in [200, 400, 500]) {
        sample(gate, 600 + elapsed, target: target);
      }
      expect(gate.isSteady(at(1100)), isTrue);
    }
  });

  test('an equivalent target object preserves its stable window', () {
    final gate = CaptureMotionGate();
    hold(gate);
    sample(gate, 600, target: const CaptureTarget('front', 0, 0));
    expect(gate.isSteady(at(600)), isTrue);
  });

  test('leaving and returning to the target requires another hold', () {
    final gate = CaptureMotionGate();
    hold(gate);
    sample(gate, 600, yaw: 6.1);
    expect(gate.aimed, isFalse);
    expect(gate.isFresh(at(600)), isTrue);
    expect(gate.isSteady(at(600)), isFalse);
    sample(gate, 700, yaw: 5.9);
    expect(gate.aimed, isTrue);
    expect(gate.isSteady(at(700)), isFalse);
    for (final elapsed in [200, 400, 500]) {
      sample(gate, 700 + elapsed, yaw: 5.9);
    }
    expect(gate.isSteady(at(1200)), isTrue);
  });

  test('motion inside the target still resets the stability hold', () {
    final gate = CaptureMotionGate();
    hold(gate);
    sample(gate, 600, yaw: 1.6);
    expect(gate.aimed, isTrue);
    expect(gate.isSteady(at(600)), isFalse);
    sample(gate, 800, yaw: 1.6);
    sample(gate, 1000, yaw: 1.6);
    sample(gate, 1100, yaw: 1.6);
    expect(gate.isSteady(at(1100)), isTrue);
    sample(gate, 1200, yaw: 2.9);
    expect(gate.isSteady(at(1200)), isTrue);
  });

  test('wrapping yaw and polar yaw changes use spherical distance', () {
    final wrapping = CaptureMotionGate();
    const seam = CaptureTarget('seam', -180, 0);
    sample(wrapping, 0, yaw: 179.7, target: seam);
    sample(wrapping, 200, yaw: -179.8, target: seam);
    sample(wrapping, 400, yaw: 179.9, target: seam);
    sample(wrapping, 500, yaw: -180, target: seam);
    expect(wrapping.aimed, isTrue);
    expect(wrapping.isSteady(at(500)), isTrue);

    for (final pitch in [-90.0, 90.0]) {
      final polar = CaptureMotionGate();
      final target = CaptureTarget('pole', 0, pitch);
      for (final (time, yaw) in [
        (0, 0.0),
        (200, 180.0),
        (400, -120.0),
        (500, 90.0),
      ]) {
        sample(polar, time, yaw: yaw, pitch: pitch, target: target);
      }
      expect(polar.aimed, isTrue);
      expect(polar.isSteady(at(500)), isTrue);
    }
  });

  test('invalid samples and targets cannot keep an earlier accepted pose', () {
    for (final invalid in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      for (final field in ['yaw', 'pitch', 'targetYaw', 'targetPitch']) {
        final gate = CaptureMotionGate();
        hold(gate);
        sample(
          gate,
          600,
          yaw: field == 'yaw' ? invalid : 0,
          pitch: field == 'pitch' ? invalid : 0,
          target: CaptureTarget(
            'front',
            field == 'targetYaw' ? invalid : 0,
            field == 'targetPitch' ? invalid : 0,
          ),
        );
        expect(gate.aimed, isFalse);
        expect(gate.isFresh(at(600)), isFalse);
        expect(gate.isSteady(at(600)), isFalse);
        sample(gate, 700);
        expect(gate.isSteady(at(700)), isFalse);
      }
    }
  });

  test(
    'no selected target prevents acceptance and clears the stable window',
    () {
      final gate = CaptureMotionGate();
      hold(gate);
      sample(gate, 600, target: null);
      expect(gate.aimed, isFalse);
      expect(gate.isSteady(at(600)), isFalse);
      sample(gate, 700);
      expect(gate.isSteady(at(700)), isFalse);
    },
  );

  test('a backwards clock cannot reuse future stability', () {
    final gate = CaptureMotionGate();
    hold(gate);
    expect(gate.isFresh(at(499)), isFalse);
    expect(gate.isSteady(at(499)), isFalse);
    sample(gate, 100);
    expect(gate.isFresh(at(100)), isTrue);
    expect(gate.isSteady(at(100)), isFalse);
    for (final time in [300, 500, 600]) {
      sample(gate, time);
    }
    expect(gate.isSteady(at(600)), isTrue);
  });
}
