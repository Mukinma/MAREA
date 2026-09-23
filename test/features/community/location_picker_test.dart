import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';

const _geolocator = MethodChannel('flutter.baseflow.com/geolocator');
const _initial = PostLocationSelection(
  label: 'Dirección anterior',
  coordinates: PostCoordinates(latitude: 19.43, longitude: -99.13, precision: PostLocationPrecision.exact),
);

http.Response _place(String label) => http.Response(
  jsonEncode([
    {'display_name': label, 'lat': '19.5', 'lon': '-99.2'},
  ]),
  200,
);

// Keep map tile loading deterministic without external network requests.
http.Response _tile() => http.Response.bytes(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  ),
  200,
  headers: {'content-type': 'image/png'},
);

Future<void> _open(
  WidgetTester tester, {
  PostLocationSelection? initial,
  ValueChanged<PostLocationSelection?>? onSelection,
}) async {
  tester.view.physicalSize = const Size(1000, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final selection = await showCommunityLocationPicker(
                context,
                initial: initial,
              );
              onSelection?.call(selection);
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.tap(find.byTooltip('Buscar'));
  await tester.pump();
}

void main() {
  testWidgets('opening and choosing a map point never requests GPS permission', (
    tester,
  ) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _geolocator,
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(_geolocator, null));
    await http.runWithClient(() async {
      PostLocationSelection? selected;
      await _open(tester, onSelection: (value) => selected = value);
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      map.options.onTap!(
        const TapPosition(Offset.zero, Offset.zero),
        const LatLng(20.123456, -103.123456),
      );
      await tester.pump();
      await tester.tap(find.text('Usar esta ubicación'));
      await tester.pumpAndSettle();
      expect(selected?.coordinates.latitude, 20.123456);
      expect(selected?.coordinates.longitude, -103.123456);
      expect(calls, isEmpty);
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) async => _tile()));
  });

  testWidgets('editing search text invalidates a pending result', (tester) async {
    final pending = Completer<http.Response>();
    await http.runWithClient(() async {
      await _open(tester);
      await _search(tester, 'Centro');
      await tester.enterText(find.byType(TextField), 'Nueva dirección');
      pending.complete(_place('Resultado anterior'));
      await tester.pumpAndSettle();
      expect(find.text('Resultado anterior'), findsNothing);
      expect(find.text('Nueva dirección'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }, () => MockClient((request) async =>
        request.url.path == '/search' ? pending.future : _tile()));
  });

  testWidgets('older search cannot replace newer search results', (tester) async {
    final older = Completer<http.Response>();
    final newer = Completer<http.Response>();
    await http.runWithClient(() async {
      await _open(tester);
      await _search(tester, 'Centro');
      await _search(tester, 'Puerto');
      newer.complete(_place('Puerto nuevo'));
      await tester.pumpAndSettle();
      expect(find.text('Puerto nuevo'), findsOneWidget);
      older.complete(_place('Centro viejo'));
      await tester.pumpAndSettle();
      expect(find.text('Puerto nuevo'), findsOneWidget);
      expect(find.text('Centro viejo'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    }, () => MockClient((request) async {
      if (request.url.path != '/search') return _tile();
      return request.url.queryParameters['q'] == 'Centro'
          ? older.future
          : newer.future;
    }));
  });

  testWidgets('search completion after closing picker is safe', (tester) async {
    final pending = Completer<http.Response>();
    await http.runWithClient(() async {
      await _open(tester);
      await _search(tester, 'Centro');
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      pending.complete(_place('Resultado tardío'));
      await tester.pumpAndSettle();
      expect(find.text('Elegir ubicación'), findsNothing);
      expect(tester.takeException(), isNull);
    }, () => MockClient((request) async =>
        request.url.path == '/search' ? pending.future : _tile()));
  });

  testWidgets('GPS service completion after closing cannot request permission', (
    tester,
  ) async {
    final service = Completer<bool>();
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _geolocator,
      (call) async {
        calls.add(call.method);
        if (call.method == 'isLocationServiceEnabled') return service.future;
        return 0;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(_geolocator, null));
    await http.runWithClient(() async {
      await _open(tester);
      await tester.tap(find.byTooltip('Usar mi ubicación actual'));
      await tester.pump();
      expect(calls, ['isLocationServiceEnabled']);
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      service.complete(true);
      await tester.pumpAndSettle();
      expect(calls, ['isLocationServiceEnabled']);
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) async => _tile()));
  });

  testWidgets('moving an existing point replaces its old address label', (
    tester,
  ) async {
    await http.runWithClient(() async {
      PostLocationSelection? selected;
      await _open(
        tester,
        initial: _initial,
        onSelection: (value) => selected = value,
      );
      expect(find.text('Dirección anterior'), findsOneWidget);
      tester.widget<FlutterMap>(find.byType(FlutterMap)).options.onTap!(
        const TapPosition(Offset.zero, Offset.zero),
        const LatLng(21.5, -104.5),
      );
      await tester.pump();
      expect(find.text('Dirección anterior'), findsNothing);
      await tester.tap(find.text('Usar esta ubicación'));
      await tester.pumpAndSettle();
      expect(selected?.label, 'Ubicación seleccionada (21.500000, -104.500000)');
      expect(selected?.coordinates.latitude, 21.5);
      expect(selected?.coordinates.longitude, -104.5);
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) async => _tile()));
  });
}
