import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/proximity/application/proximity_controller.dart';
import 'package:marea/features/proximity/data/proximity_services.dart';
import 'package:marea/features/proximity/models/proximity_models.dart';

import 'proximity_fixture.dart';

class LocationFake implements ProximityLocationSource {
  final prompts = <bool>[];
  final positions = StreamController<ProximityFix>.broadcast(sync: true);
  Completer<void>? hold;
  int watches = 0;

  @override
  Future<void> prepare({
    required bool requestPermission,
    required bool Function() isCurrent,
  }) async {
    prompts.add(requestPermission);
    await hold?.future;
  }

  @override
  Stream<ProximityFix> watch() {
    watches++;
    return positions.stream;
  }
}

class TargetsFake implements ProximityTargetSource {
  final fixes = <ProximityFix>[];
  final pending = <Completer<List<ProximityTarget>>>[];
  bool hold = false;
  List<ProximityTarget> items = [target()];

  @override
  Future<List<ProximityTarget>> load(ProximityFix fix) async {
    fixes.add(fix);
    if (!hold) return items;
    final request = Completer<List<ProximityTarget>>();
    pending.add(request);
    return request.future;
  }
}

class NoticesFake implements ProximityNotificationSink {
  final accounts = <String>[];
  final cleared = <String>[];

  @override
  Future<void> present(
    ProximityEncounter encounter, {
    required String accountId,
    required bool Function() isCurrent,
  }) async {
    if (isCurrent()) accounts.add(accountId);
  }

  @override
  Future<void> clearAccount(String accountId) async => cleared.add(accountId);
}

Future<void> drain() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  late LocationFake location;
  late TargetsFake targets;
  late NoticesFake notices;
  late ProximityController controller;
  late DateTime now;

  setUp(() {
    now = testTime;
    location = LocationFake();
    targets = TargetsFake();
    notices = NoticesFake();
    controller = ProximityController(
      location: location,
      targets: targets,
      notifications: notices,
      now: () => now,
    );
  });
  tearDown(() async {
    controller.dispose();
    await location.positions.close();
  });

  Future<void> start() async {
    await controller.setForeground(true);
    expect(await controller.start(accountId: accountA), isTrue);
  }

  test('off by default and only explicit start requests permission', () async {
    expect(controller.enabled, isFalse);
    expect(controller.foreground, isFalse);
    await controller.setAccount(accountA);
    await controller.setForeground(true);
    expect(location.prompts, isEmpty);
    expect(targets.fixes, isEmpty);
    expect(await controller.start(accountId: accountA), isTrue);
    expect(location.prompts, [true]);
    expect(location.watches, 1);
    location.positions.add(fix());
    await drain();
    expect(notices.accounts, [accountA]);
  });

  test(
    'background stops GPS and resumes without prompting or repeating inside',
    () async {
      await start();
      location.positions.add(fix());
      await drain();
      expect(notices.accounts, [accountA]);
      await controller.setForeground(false);
      expect(controller.running, isFalse);
      location.positions.add(fix(meters: 100));
      await drain();
      expect(targets.fixes, hasLength(1));
      now = now.add(const Duration(minutes: 6));
      await controller.setForeground(true);
      expect(location.prompts, [true, false]);
      expect(location.watches, 2);
      location.positions.add(fix(timestamp: now));
      await drain();
      expect(notices.accounts, [accountA]);
    },
  );

  test(
    'account changes disable monitoring and reset only the previous account',
    () async {
      await start();
      location.positions.add(fix());
      await drain();
      await controller.setAccount(accountB);
      expect(controller.enabled, isFalse);
      expect(controller.running, isFalse);
      expect(controller.lastEncounter, isNull);
      expect(notices.cleared, [accountA]);
      location.positions.add(fix());
      await drain();
      expect(notices.accounts, [accountA]);
      expect(await controller.start(accountId: accountB), isTrue);
      location.positions.add(fix());
      await drain();
      expect(notices.accounts, [accountA, accountB]);
    },
  );

  test(
    'stopping during permission request never attaches a late GPS stream',
    () async {
      await controller.setForeground(true);
      location.hold = Completer<void>();
      final starting = controller.start(accountId: accountA);
      await drain();
      expect(controller.starting, isTrue);
      await controller.stop();
      location.hold!.complete();
      expect(await starting, isFalse);
      expect(controller.running, isFalse);
      expect(location.watches, 0);
    },
  );

  for (final action in ['stop', 'background', 'account']) {
    test('a late target lookup after $action cannot create a notice', () async {
      await start();
      targets.hold = true;
      location.positions.add(fix());
      await drain();
      switch (action) {
        case 'stop':
          await controller.stop();
        case 'background':
          await controller.setForeground(false);
        case 'account':
          await controller.setAccount(accountB);
      }
      targets.pending.single.complete([target()]);
      await drain();
      expect(notices.accounts, isEmpty);
      expect(controller.lastEncounter, isNull);
    });
  }

  test('newer GPS discards a late older target response', () async {
    await start();
    targets.hold = true;
    location.positions.add(fix());
    await drain();
    now = now.add(const Duration(seconds: 1));
    location.positions.add(fix(meters: 100, timestamp: now));
    await drain();
    expect(targets.pending, hasLength(2));
    targets.pending.last.complete([target()]);
    await drain();
    targets.pending.first.complete([target()]);
    await drain();
    expect(notices.accounts, isEmpty);
  });

  test(
    'poor accuracy never fetches targets and approximate places never notify',
    () async {
      await start();
      location.positions.add(fix(accuracy: 50));
      await drain();
      expect(targets.fixes, isEmpty);
      targets.items = [target(exact: false)];
      location.positions.add(fix());
      await drain();
      expect(targets.fixes, hasLength(1));
      expect(notices.accounts, isEmpty);
    },
  );

  test(
    'stream failure invalidates pending work and stops monitoring',
    () async {
      await start();
      targets.hold = true;
      location.positions.add(fix());
      await drain();
      final error = StateError('GPS unavailable');
      location.positions.addError(error);
      await drain();
      targets.pending.single.complete([target()]);
      await drain();
      expect(controller.running, isFalse);
      expect(controller.error, same(error));
      expect(notices.accounts, isEmpty);
    },
  );
}
