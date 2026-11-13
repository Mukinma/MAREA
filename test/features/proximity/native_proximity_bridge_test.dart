import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/proximity/data/native_proximity_bridge.dart';
import 'package:marea/features/proximity/models/proximity_models.dart';

import 'proximity_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/native-proximity');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'status'
              ? {'supported': true, 'enabled': false}
              : null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    channel.setMethodCallHandler(null);
  });

  test(
    'binding preserves foreground state and refresh never asks the service to start',
    () async {
      final bridge = NativeProximityBridge(channel: channel);
      await bridge.bindAccount(accountA, foreground: true);
      expect(calls.last.arguments, {'accountId': accountA, 'foreground': true});
      final expiry = testTime.add(const Duration(days: 1));
      await bridge.configure(accountA, [
        target(exact: false),
        ProximityTarget(
          id: targetId,
          title: 'Mission',
          route: '/missions/$targetId',
          latitude: 0,
          longitude: 0,
          exact: true,
          kind: ProximityTargetKind.mission,
          expiresAt: expiry,
        ),
      ], start: false);
      expect(calls.last.method, 'updateTargets');
      final arguments = calls.last.arguments as Map;
      final places = arguments['targets'] as List;
      expect(places, hasLength(1));
      expect(places.single['expiresAt'], expiry.millisecondsSinceEpoch);
      expect(arguments.containsKey('foreground'), isFalse);
      await bridge.configure(accountA, [target()], start: true);
      expect(calls.last.method, 'start');
      await bridge.bindAccount(null);
      expect(calls.last.arguments, {'accountId': null, 'foreground': false});
    },
  );
}
