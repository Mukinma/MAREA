import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/ar_markers/application/marker_scan_controller.dart';
import 'package:marea/features/ar_markers/data/local_marker_repository.dart';
import 'package:marea/features/ar_markers/presentation/marker_scan_screen.dart';

import 'local_marker_repository_test.dart'
    show MarkerStore, markerJpeg, markerValues;
import 'marker_ui_test.dart' show markerController;

class ScanStore extends MarkerStore {
  @override
  Future<String> saveBytes(String account, String id, Uint8List bytes) async =>
      '/private/$account/$id.jpg';
}

void main() {
  const channel = MethodChannel('test/marker-scan');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'supported' ? true : null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets(
    'only current native tracking shows a card; lost and timeout remove it',
    (tester) async {
      const owner = '11111111-1111-4111-8111-111111111111';
      String? account = owner;
      var now = DateTime.utc(2026, 11, 12);
      final store = ScanStore();
      final repository = LocalMarkerRepository(
        localStore: store,
        currentOwner: () => account,
      );
      final marker = await repository.save(
        owner,
        markerValues(),
        imageBytes: markerJpeg(),
      );
      final events = StreamController<dynamic>.broadcast(sync: true);
      final scan = MarkerScanController(
        repository: repository,
        accountId: owner,
        markerId: marker.id,
        currentAccount: () => account,
        localStore: store,
        channel: channel,
        trackingEvents: events.stream,
        now: () => now,
      );
      await scan.start();
      final session = scan.sessionId;
      Map<String, dynamic> frame({
        String? sessionId,
        String state = 'tracking',
      }) => {
        'sessionId': sessionId ?? session,
        'id': marker.id,
        'state': state,
        'quad': [.2, .3, .8, .3, .8, .6, .2, .6],
      };
      expect(scan.quad, isNull);
      expect(scan.references.single['widthMeters'], .2);
      events.add(frame(sessionId: 'obsolete'));
      expect(scan.quad, isNull);
      events.add(frame());
      expect(scan.quad, isNotNull);
      events.add(frame(state: 'lost'));
      expect(scan.quad, isNull);
      events.add(frame());
      await tester.pump(const Duration(milliseconds: 601));
      expect(scan.quad, isNull);
      expect((await repository.get(owner, marker.id))!.isTested, isFalse);

      // Three seconds must be continuous, with current native frames throughout.
      for (var i = 0; i <= 6; i++) {
        now = now.add(const Duration(milliseconds: 500));
        events.add(frame());
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pump();
      expect((await repository.get(owner, marker.id))!.isTested, isTrue);
      await tester.runAsync(scan.stop);
      expect(calls.where((call) => call.method == 'stop').last.arguments, {
        'sessionId': session,
      });
      expect(scan.quad, isNull);
      await scan.start();
      expect(scan.sessionId, isNot(session));
      events.add(frame());
      expect(scan.quad, isNull);
      account = null;
      events.add(frame(sessionId: scan.sessionId));
      expect(scan.quad, isNull);
      await tester.runAsync(scan.stop);
      scan.dispose();
      await tester.runAsync(events.close);
    },
  );

  testWidgets(
    'interrupted tracking never proves recognition; no callback never proves it',
    (tester) async {
      const owner = '11111111-1111-4111-8111-111111111111';
      var now = DateTime.utc(2026, 11, 12);
      final store = ScanStore();
      final repository = LocalMarkerRepository(
        localStore: store,
        currentOwner: () => owner,
      );
      final marker = await repository.save(
        owner,
        markerValues(),
        imageBytes: markerJpeg(),
      );
      final events = StreamController<dynamic>.broadcast(sync: true);
      final scan = MarkerScanController(
        repository: repository,
        accountId: owner,
        markerId: marker.id,
        currentAccount: () => owner,
        localStore: store,
        channel: channel,
        trackingEvents: events.stream,
        now: () => now,
      );
      await scan.start();
      await tester.pump(const Duration(seconds: 10));
      expect((await repository.get(owner, marker.id))!.isTested, isFalse);
      for (var i = 0; i < 8; i++) {
        now = now.add(const Duration(seconds: 1));
        events.add({
          'sessionId': scan.sessionId,
          'id': marker.id,
          'state': 'tracking',
          'quad': [.2, .3, .8, .3, .8, .6, .2, .6],
        });
        await tester.pump(const Duration(seconds: 1));
      }
      expect((await repository.get(owner, marker.id))!.isTested, isFalse);
      await tester.runAsync(scan.stop);
      scan.dispose();
      await tester.runAsync(events.close);
    },
  );

  testWidgets(
    'tapping a recognized card releases camera; reopening requires a new recognition',
    (tester) async {
      final session = await markerController();
      final owner = session.profile!.id;
      final store = ScanStore();
      final repository = LocalMarkerRepository(
        localStore: store,
        currentOwner: () => session.profile?.id,
      );
      final marker = await repository.save(
        owner,
        markerValues(),
        imageBytes: markerJpeg(),
      );
      final events = StreamController<dynamic>.broadcast(sync: true);
      final scan = MarkerScanController(
        repository: repository,
        accountId: owner,
        markerId: marker.id,
        currentAccount: () => session.profile?.id,
        localStore: store,
        channel: channel,
        trackingEvents: events.stream,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MarkerScanScreen(
            controller: session,
            repository: repository,
            markerId: marker.id,
            scanController: scan,
            cameraBuilder: (_) => const ColoredBox(
              key: Key('native-camera'),
              color: Colors.black,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir cámara'));
      await tester.pumpAndSettle();
      final firstSession = scan.sessionId;
      expect(find.byKey(const Key('native-camera')), findsOneWidget);
      events.add({
        'sessionId': firstSession,
        'id': marker.id,
        'state': 'tracking',
        'quad': [.2, .3, .8, .3, .8, .6, .2, .6],
      });
      await tester.pump();
      await tester.tap(find.text('Toca para abrir el menú'));
      for (
        var i = 0;
        i < 30 && find.text('Abrir menú').evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();
      expect(calls.where((call) => call.method == 'stop').last.arguments, {
        'sessionId': firstSession,
      });
      expect(find.byKey(const Key('native-camera')), findsNothing);
      expect(find.text('Abrir menú'), findsOneWidget);
      Navigator.of(tester.element(find.text('Abrir menú'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir cámara'));
      await tester.pumpAndSettle();
      expect(scan.sessionId, isNot(firstSession));
      expect(find.text('Toca para abrir el menú'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.runAsync(events.close);
    },
  );
}
