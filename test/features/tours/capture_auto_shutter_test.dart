import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/tours/capture/capture_auto_shutter.dart';

void main() {
  test('automatic mode starts enabled and idle', () {
    final shutter = CaptureAutoShutter();
    expect(shutter.enabled, isTrue);
    expect(shutter.paused, isFalse);
    expect(shutter.capturing, isFalse);
  });

  test(
    'inactive camera and unready or stale pose never take a photo',
    () async {
      final shutter = CaptureAutoShutter();
      var photos = 0;
      for (final (active, ready) in [
        (false, false),
        (false, true),
        (true, false),
      ]) {
        await shutter.tick(
          active: active,
          ready: ready,
          capture: () async => photos++,
        );
        expect(shutter.capturing, isFalse);
      }
      expect(photos, 0);
      await shutter.tick(
        active: true,
        ready: true,
        capture: () async => photos++,
      );
      expect(photos, 1);
    },
  );

  test('manual mode and pause suppress an otherwise ready camera', () async {
    final shutter = CaptureAutoShutter();
    var photos = 0;
    shutter.enabled = false;
    await shutter.tick(
      active: true,
      ready: true,
      capture: () async => photos++,
    );
    expect(photos, 0);
    shutter.enabled = true;
    shutter.paused = true;
    await shutter.tick(
      active: true,
      ready: true,
      capture: () async => photos++,
    );
    expect(photos, 0);
    shutter.paused = false;
    await shutter.tick(
      active: true,
      ready: true,
      capture: () async => photos++,
    );
    expect(photos, 1);
    expect(shutter.capturing, isFalse);
  });

  test(
    'pending photograph cannot be duplicated by subsequent sensor ticks',
    () async {
      final shutter = CaptureAutoShutter();
      final pending = Completer<void>();
      var photos = 0;
      final first = shutter.tick(
        active: true,
        ready: true,
        capture: () {
          photos++;
          return pending.future;
        },
      );
      expect(shutter.capturing, isTrue);
      for (var i = 0; i < 10; i++) {
        await shutter.tick(
          active: true,
          ready: true,
          capture: () async => photos++,
        );
      }
      expect(photos, 1);
      pending.complete();
      await first;
      expect(shutter.capturing, isFalse);
      await shutter.tick(
        active: true,
        ready: true,
        capture: () async => photos++,
      );
      expect(photos, 2);
    },
  );

  test('pause during a pending photo persists after its completion', () async {
    final shutter = CaptureAutoShutter();
    final pending = Completer<void>();
    var photos = 0;
    final first = shutter.tick(
      active: true,
      ready: true,
      capture: () {
        photos++;
        return pending.future;
      },
    );
    shutter.paused = true;
    pending.complete();
    await first;
    await shutter.tick(
      active: true,
      ready: true,
      capture: () async => photos++,
    );
    expect(photos, 1);
    expect(shutter.paused, isTrue);
    expect(shutter.capturing, isFalse);
  });

  test(
    'a failed photo pauses automation, reports the error and allows explicit resume',
    () async {
      final shutter = CaptureAutoShutter();
      final failure = StateError('Camera disconnected');
      await expectLater(
        shutter.tick(
          active: true,
          ready: true,
          capture: () async => throw failure,
        ),
        throwsA(same(failure)),
      );
      expect(shutter.capturing, isFalse);
      expect(shutter.paused, isTrue);
      var photos = 0;
      await shutter.tick(
        active: true,
        ready: true,
        capture: () async => photos++,
      );
      expect(photos, 0);
      shutter.paused = false;
      await shutter.tick(
        active: true,
        ready: true,
        capture: () async => photos++,
      );
      expect(photos, 1);
    },
  );

  test(
    'synchronous camera failure also releases the shutter and pauses',
    () async {
      final shutter = CaptureAutoShutter();
      await expectLater(
        shutter.tick(
          active: true,
          ready: true,
          capture: () => throw StateError('Camera disposed'),
        ),
        throwsStateError,
      );
      expect(shutter.capturing, isFalse);
      expect(shutter.paused, isTrue);
    },
  );
}
