import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/location/device_location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.baseflow.com/geolocator');
  final calls = <String>[];
  int permission = 0;
  bool enabled = true;
  setUp(() {
    calls.clear();
    permission = 0;
    enabled = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'isLocationServiceEnabled' => enabled,
            'checkPermission' => permission,
            'requestPermission' => permission,
            'getCurrentPosition' => {
              'latitude': 19.43,
              'longitude': -99.13,
              'accuracy': 100.0,
              'altitude': 0.0,
              'heading': 0.0,
              'speed': 0.0,
              'speed_accuracy': 0.0,
              'timestamp': 0,
            },
            _ => false,
          };
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test('opening without permission never prompts', () async {
    await expectLater(
      GeolocatorDeviceLocationService().current(),
      throwsA(
        isA<DeviceLocationFailure>().having(
          (e) => e.kind,
          'kind',
          DeviceLocationFailureKind.permissionRequired,
        ),
      ),
    );
    expect(calls, ['isLocationServiceEnabled', 'checkPermission']);
  });
  test('explicit denied request stops before GPS', () async {
    await expectLater(
      GeolocatorDeviceLocationService().current(requestPermission: true),
      throwsA(
        isA<DeviceLocationFailure>().having(
          (e) => e.kind,
          'kind',
          DeviceLocationFailureKind.denied,
        ),
      ),
    );
    expect(calls, [
      'isLocationServiceEnabled',
      'checkPermission',
      'requestPermission',
    ]);
  });
  test('permanent rejection does not prompt again', () async {
    permission = 1;
    await expectLater(
      GeolocatorDeviceLocationService().current(requestPermission: true),
      throwsA(
        isA<DeviceLocationFailure>().having(
          (e) => e.kind,
          'kind',
          DeviceLocationFailureKind.deniedForever,
        ),
      ),
    );
    expect(calls, ['isLocationServiceEnabled', 'checkPermission']);
  });
  test('disabled service does not request permission', () async {
    enabled = false;
    await expectLater(
      GeolocatorDeviceLocationService().current(requestPermission: true),
      throwsA(
        isA<DeviceLocationFailure>().having(
          (e) => e.kind,
          'kind',
          DeviceLocationFailureKind.disabled,
        ),
      ),
    );
    expect(calls, ['isLocationServiceEnabled']);
  });
  test('granted permission obtains one fix', () async {
    permission = 2;
    final point = await GeolocatorDeviceLocationService().current();
    expect(point.latitude, 19.43);
    expect(point.longitude, -99.13);
    expect(calls.where((c) => c == 'getCurrentPosition').length, 1);
  });
  test('cancelled owner cannot prompt after pending service check', () async {
    final service = Completer<bool>();
    var active = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
          calls.add(call.method);
          return service.future;
        });
    final pending = GeolocatorDeviceLocationService().current(
      requestPermission: true,
      isCurrent: () => active,
    );
    active = false;
    service.complete(true);
    await expectLater(
      pending,
      throwsA(
        isA<DeviceLocationFailure>().having(
          (e) => e.kind,
          'kind',
          DeviceLocationFailureKind.cancelled,
        ),
      ),
    );
    expect(calls, ['isLocationServiceEnabled']);
  });
  test('GPS timeout is recoverable', () async {
    permission = 2;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => switch (call.method) {
            'isLocationServiceEnabled' => true,
            'checkPermission' => 2,
            _ => Completer<Object>().future,
          },
        );
    await expectLater(
      GeolocatorDeviceLocationService(
        positionTimeout: const Duration(milliseconds: 5),
      ).current(),
      throwsA(
        isA<DeviceLocationFailure>().having(
          (e) => e.kind,
          'kind',
          DeviceLocationFailureKind.timeout,
        ),
      ),
    );
  });
}
