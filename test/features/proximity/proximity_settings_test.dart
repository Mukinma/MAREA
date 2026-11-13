import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/proximity/data/native_proximity_bridge.dart';
import 'package:marea/features/proximity/presentation/proximity_settings_screen.dart';

import '../ar_markers/marker_ui_test.dart'
    show markerController, MarkerLocation;

void main() {
  const channel = MethodChannel('test/proximity-settings');
  final calls = <MethodCall>[];
  var always = false;
  var enabled = false;
  setUp(() {
    calls.clear();
    always = false;
    enabled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'start') enabled = true;
          if (call.method == 'stop') enabled = false;
          if (call.method == 'status') {
            return {
              'supported': true,
              'enabled': enabled,
              'running': enabled,
              'precise': true,
              'always': always,
              'notifications': true,
              'count': 0,
            };
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    channel.setMethodCallHandler(null);
  });

  testWidgets(
    'opening settings does not request GPS; explicit activation requires background permission',
    (tester) async {
      final session = await markerController();
      final location = MarkerLocation();
      final bridge = NativeProximityBridge(channel: channel);
      await tester.pumpWidget(
        MaterialApp(
          home: ProximitySettingsScreen(
            controller: session,
            location: location,
            bridge: bridge,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(location.prompts, isEmpty);
      expect(calls.map((c) => c.method), ['status']);
      await tester.tap(find.text('Activar avisos'));
      await tester.pumpAndSettle();
      expect(location.prompts, [true]);
      expect(calls.where((c) => c.method == 'start'), isEmpty);
      expect(find.textContaining('Todo el tiempo'), findsOneWidget);
    },
  );

  testWidgets(
    'authorized activation starts once, stop removes opt-in, and logout hides account data',
    (tester) async {
      always = true;
      final session = await markerController();
      final bridge = NativeProximityBridge(channel: channel);
      await tester.pumpWidget(
        MaterialApp(
          home: ProximitySettingsScreen(
            controller: session,
            location: MarkerLocation(),
            bridge: bridge,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activar avisos'));
      await tester.pumpAndSettle();
      expect(calls.where((c) => c.method == 'start'), hasLength(1));
      expect(
        find.text('Avisos activos para 0 lugares cargados.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Detener avisos'));
      await tester.pumpAndSettle();
      expect(calls.where((c) => c.method == 'stop'), hasLength(1));
      expect(find.text('Activar avisos'), findsOneWidget);
      await session.signOut();
      await tester.pumpAndSettle();
      expect(find.text('Activar avisos'), findsNothing);
      expect(find.text('Abre los avisos desde tu sesión.'), findsOneWidget);
    },
  );
}
