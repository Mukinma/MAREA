import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/tours/capture/capture_frames.dart';
import 'package:marea/features/tours/capture/capture_plan.dart';

Map<String, dynamic> photo({
  String? status,
  double yaw = 0,
  double pitch = 0,
  String? target,
}) => {
  'width': 720,
  'height': 1280,
  'yaw': yaw,
  'pitch': pitch,
  'roll': 0.0,
  'hfov': 40.0,
  'vfov': 60.0,
  'pose_status': ?status,
  'target_id': ?target,
};

CapturePlan get plan => CapturePlan(40, 60, [
  const CaptureTarget('front', 0, 0),
  const CaptureTarget('right', 90, 0),
  const CaptureTarget('back', -180, 0),
  const CaptureTarget('ceiling', 0, 90),
]);

void main() {
  test(
    'legacy and ready photos need measured pose and valid worker fields',
    () {
      expect(canProcessCaptureFrame(photo()), isTrue);
      expect(canProcessCaptureFrame(photo(status: 'ready')), isTrue);
      for (final status in [
        'unavailable',
        'needs_reference',
        'unknown',
        null,
      ]) {
        final frame = photo()..['pose_status'] = status;
        expect(canProcessCaptureFrame(frame), isFalse, reason: '$status');
      }
      for (final field in ['yaw', 'pitch', 'roll', 'hfov', 'vfov']) {
        for (final value in [null, double.nan, double.infinity, '0', false]) {
          expect(
            canProcessCaptureFrame(photo()..[field] = value),
            isFalse,
            reason: '$field=$value',
          );
        }
      }
    },
  );

  test('worker dimensions are bounded integer values, with a pixel limit', () {
    for (final dimensions in [
      (64, 64),
      (24000, 64),
      (64, 24000),
      (24000, 5000),
    ]) {
      expect(
        canProcessCaptureFrame(
          photo()
            ..['width'] = dimensions.$1
            ..['height'] = dimensions.$2,
        ),
        isTrue,
      );
    }
    for (final dimensions in [
      (63, 64),
      (64, 63),
      (24001, 64),
      (64, 24001),
      (24000, 5001),
      (720.0, 1280),
      (720, 1280.0),
    ]) {
      expect(
        canProcessCaptureFrame(
          photo()
            ..['width'] = dimensions.$1
            ..['height'] = dimensions.$2,
        ),
        isFalse,
      );
    }
  });

  test('pose and rectilinear field-of-view bounds match photos processing', () {
    for (final (field, values) in [
      ('yaw', [-180.0, 179.999999]),
      ('pitch', [-90.0, 90.0]),
      ('roll', [-180.0, 180.0]),
      ('hfov', [1.0, 178.999]),
      ('vfov', [1.0, 178.999]),
    ]) {
      for (final value in values) {
        expect(canProcessCaptureFrame(photo()..[field] = value), isTrue);
      }
    }
    for (final (field, values) in [
      ('yaw', [-180.001, 180.0]),
      ('pitch', [-90.001, 90.001]),
      ('roll', [-180.001, 180.001]),
      ('hfov', [.999, 179.0]),
      ('vfov', [.999, 179.0]),
    ]) {
      for (final value in values) {
        expect(canProcessCaptureFrame(photo()..[field] = value), isFalse);
      }
    }
  });

  test('processable selection keeps original maps and upload checkpoints', () {
    final checkpoint = {'offset': 1024};
    final first = photo()..['upload'] = checkpoint;
    final second = photo(status: 'ready', yaw: 45);
    final selected = processableCaptureFrames([
      first,
      photo(status: 'needs_reference'),
      null,
      second,
    ]);
    expect(selected, hasLength(2));
    expect(selected[0], same(first));
    expect(selected[1], same(second));
    expect(selected[0]['upload'], same(checkpoint));
    selected[0]['path'] = 'actual-upload-path';
    expect(first['path'], 'actual-upload-path');
  });

  test(
    'free photos outside every target remain processable without progress',
    () {
      final free = photo(status: 'ready', yaw: 43);
      expect(canProcessCaptureFrame(free), isTrue);
      expect(
        findCaptureTarget(plan: plan, frames: [], yaw: 43, pitch: 0),
        isNull,
      );
      expect(free.containsKey('target_id'), isFalse);
      expect(
        findCaptureTarget(plan: plan, frames: [free], yaw: 0, pitch: 0)?.id,
        'front',
      );
    },
  );

  test('nearest pending target can be completed out of plan order', () {
    expect(
      findCaptureTarget(plan: plan, frames: [], yaw: 92, pitch: 0)?.id,
      'right',
    );
    expect(
      findCaptureTarget(
        plan: plan,
        frames: [photo(target: 'right')],
        yaw: 92,
        pitch: 0,
      ),
      isNull,
    );
    expect(
      findCaptureTarget(
        plan: plan,
        frames: [photo(status: 'unavailable', target: 'right')],
        yaw: 92,
        pitch: 0,
      )?.id,
      'right',
    );
    final nearTargets = CapturePlan(40, 60, [
      const CaptureTarget('farther', 0, 0),
      const CaptureTarget('closer', 4, 0),
    ]);
    expect(
      findCaptureTarget(plan: nearTargets, frames: [], yaw: 3, pitch: 0)?.id,
      'closer',
    );
  });

  test(
    'target matching accepts polar directions and rejects invalid poses',
    () {
      expect(
        findCaptureTarget(plan: plan, frames: [], yaw: -130, pitch: 86)?.id,
        'ceiling',
      );
      expect(
        findCaptureTarget(plan: plan, frames: [], yaw: 0, pitch: 83),
        isNull,
      );
      expect(
        findCaptureTarget(plan: plan, frames: [], yaw: 6.01, pitch: 0),
        isNull,
      );
      expect(
        findCaptureTarget(plan: null, frames: [], yaw: 0, pitch: 0),
        isNull,
      );
      expect(
        findCaptureTarget(plan: plan, frames: [], yaw: double.nan, pitch: 0),
        isNull,
      );
      expect(
        findCaptureTarget(plan: plan, frames: [], yaw: 0, pitch: 91),
        isNull,
      );
    },
  );

  test(
    'recovering a segment preserves all 35 legacy frames and their data',
    () {
      final legacy = [
        for (var index = 0; index < 35; index++)
          photo(yaw: index * 5.0)
            ..['id'] = 'original-$index'
            ..['local_path'] = 'actual-photo-$index.jpg'
            ..['target_id'] = 'legacy-$index',
      ];
      final recovered = alignCaptureFrames(
        legacy,
        motionSession: 'current',
        yawOffset: 27,
        plan: plan,
      );
      expect(recovered, legacy);
      expect(recovered, hasLength(35));
      for (var index = 0; index < legacy.length; index++) {
        expect(recovered[index], isNot(same(legacy[index])));
      }
    },
  );

  test('alignment repairs only real poses from the current sensor session', () {
    final legacy = photo(target: 'front');
    final pending = photo(status: 'needs_reference')
      ..remove('yaw')
      ..addAll({'pose_session': 'current', 'sensor_yaw': 10.0});
    final otherSession = photo(status: 'needs_reference')
      ..remove('yaw')
      ..addAll({'pose_session': 'previous', 'sensor_yaw': 10.0});
    final missingSensor = photo(status: 'unavailable')
      ..remove('yaw')
      ..['pose_session'] = 'current';
    final recovered = alignCaptureFrames(
      [legacy, pending, otherSession, missingSensor],
      motionSession: 'current',
      yawOffset: 80,
      plan: plan,
    );
    expect(recovered[0], legacy);
    expect(recovered[1]['yaw'], 90);
    expect(recovered[1]['pose_status'], 'ready');
    expect(recovered[1]['target_id'], 'right');
    expect(canProcessCaptureFrame(recovered[1]), isTrue);
    expect(recovered[2], otherSession);
    expect(recovered[3], missingSensor);
    expect(recovered[2].containsKey('yaw'), isFalse);
    expect(recovered[3].containsKey('yaw'), isFalse);
    expect(pending['pose_status'], 'needs_reference');
    expect(pending.containsKey('yaw'), isFalse);
    expect(pending.containsKey('target_id'), isFalse);
  });

  test('realignment clears stale assignments before claiming targets once', () {
    final first = photo(status: 'ready', target: 'front')
      ..addAll({'pose_session': 'current', 'sensor_yaw': 0.0});
    final duplicate = photo(status: 'needs_reference', target: 'right')
      ..addAll({'pose_session': 'current', 'sensor_yaw': 1.0});
    final back = photo(status: 'needs_reference')
      ..addAll({'pose_session': 'current', 'sensor_yaw': 90.0});
    final recovered = alignCaptureFrames(
      [first, duplicate, back],
      motionSession: 'current',
      yawOffset: 90,
      plan: plan,
    );
    expect(recovered[0]['target_id'], 'right');
    expect(recovered[1].containsKey('target_id'), isFalse);
    expect(recovered[2]['target_id'], 'back');
    expect(recovered[2]['yaw'], -180);
    expect(first['target_id'], 'front');
    expect(duplicate['target_id'], 'right');
  });

  test('missing, invalid or incomplete measurements never invent a pose', () {
    final cases = [
      photo(status: 'unavailable')..remove('pitch'),
      photo(status: 'unavailable')..remove('roll'),
      photo(status: 'needs_reference')..['hfov'] = 0,
      photo(status: 'needs_reference')..['vfov'] = 179,
      photo(status: 'needs_reference')..['width'] = 0,
      photo(status: 'needs_reference')..['pitch'] = double.nan,
    ];
    for (final frame in cases) {
      frame
        ..remove('yaw')
        ..addAll({'pose_session': 'current', 'sensor_yaw': 1.0});
    }
    final invalidRaw = photo(status: 'unavailable')
      ..remove('yaw')
      ..addAll({'pose_session': 'current', 'sensor_yaw': double.nan});
    final recovered = alignCaptureFrames(
      [...cases, invalidRaw],
      motionSession: 'current',
      yawOffset: 90,
      plan: plan,
    );
    for (var index = 0; index < recovered.length; index++) {
      expect(recovered[index].containsKey('yaw'), isFalse);
      expect(canProcessCaptureFrame(recovered[index]), isFalse);
    }
  });

  test('invalid recovery offset cannot mutate saved maps', () {
    final saved = photo(status: 'needs_reference')
      ..addAll({'pose_session': 'current', 'sensor_yaw': 10.0});
    final before = Map<String, dynamic>.of(saved);
    expect(
      () => alignCaptureFrames(
        [saved],
        motionSession: 'current',
        yawOffset: double.infinity,
        plan: plan,
      ),
      throwsArgumentError,
    );
    expect(saved, before);
  });
}
