import 'package:marea/features/location/data/location_repository.dart';
import 'package:marea/features/location/models/location_models.dart';
import 'package:marea/core/theme/app_theme.dart';
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

// Fake only the external location boundary; exercise the real picker state.
class _PickerLocations implements LocationRepository {
  Future<Map<String, dynamic>> _request(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('https://test.supabase.co/functions/v1/geocoding'),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) throw StateError('offline');
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<List<LocationPlace>> search(String query) async =>
      ((await _request({'mode': 'search', 'query': query}))['places']
                  as List? ??
              [])
          .map(LocationPlace.fromJson)
          .whereType<LocationPlace>()
          .toList();
  @override
  Future<LocationPlace?> reverse(PostCoordinates point) async =>
      LocationPlace.fromJson(
        (await _request({
          'mode': 'reverse',
          'latitude': point.latitude,
          'longitude': point.longitude,
        }))['place'],
      );
  @override
  Future<LocationCity?> resolveContentCity({
    required String contentKind,
    required String contentId,
    required PostCoordinates coordinates,
  }) async => null;
}

const _geolocator = MethodChannel('flutter.baseflow.com/geolocator');
const _initial = PostLocationSelection(
  label: 'Dirección anterior',
  city: LocationCity(name: 'Ciudad anterior'),
  coordinates: PostCoordinates(
    latitude: 19.43,
    longitude: -99.13,
    precision: PostLocationPrecision.exact,
  ),
);

http.Response _place(String label) => http.Response(
  jsonEncode({
    'places': [
      {
        'label': label,
        'latitude': 19.5,
        'longitude': -99.2,
        'city': {'name': 'Ciudad nueva'},
      },
    ],
  }),
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
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final selection = await showCommunityLocationPicker(
                context,
                initial: initial,
                repository: _PickerLocations(),
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
  await tester.pump();
  await tester.tap(find.byTooltip('Buscar'));
  await tester.pump();
}

void main() {
  testWidgets(
    'opening and choosing a map point never requests GPS permission',
    (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _geolocator,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          _geolocator,
          null,
        ),
      );
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
    },
  );

  testWidgets('editing search text invalidates a pending result', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    await http.runWithClient(
      () async {
        await _open(tester);
        await _search(tester, 'Centro');
        await tester.enterText(find.byType(TextField), 'Nueva dirección');
        pending.complete(_place('Resultado anterior'));
        await tester.pumpAndSettle();
        expect(find.text('Resultado anterior'), findsNothing);
        expect(find.text('Nueva dirección'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
      () => MockClient(
        (request) async =>
            request.url.path.endsWith('/geocoding') &&
                jsonDecode(request.body)['mode'] == 'search'
            ? pending.future
            : _tile(),
      ),
    );
  });

  testWidgets('older search cannot replace newer search results', (
    tester,
  ) async {
    final older = Completer<http.Response>();
    final newer = Completer<http.Response>();
    await http.runWithClient(
      () async {
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
      },
      () => MockClient((request) async {
        if (!request.url.path.endsWith('/geocoding') ||
            jsonDecode(request.body)['mode'] != 'search') {
          return _tile();
        }
        return jsonDecode(request.body)['query'] == 'Centro'
            ? older.future
            : newer.future;
      }),
    );
  });

  testWidgets('search completion after closing picker is safe', (tester) async {
    final pending = Completer<http.Response>();
    await http.runWithClient(
      () async {
        await _open(tester);
        await _search(tester, 'Centro');
        await tester.tap(find.byTooltip('Cerrar'));
        await tester.pumpAndSettle();
        pending.complete(_place('Resultado tardío'));
        await tester.pumpAndSettle();
        expect(find.text('Elegir ubicación'), findsNothing);
        expect(tester.takeException(), isNull);
      },
      () => MockClient(
        (request) async =>
            request.url.path.endsWith('/geocoding') &&
                jsonDecode(request.body)['mode'] == 'search'
            ? pending.future
            : _tile(),
      ),
    );
  });

  testWidgets(
    'GPS service completion after closing cannot request permission',
    (tester) async {
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
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          _geolocator,
          null,
        ),
      );
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
    },
  );

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
      expect(
        selected?.label,
        'Ubicación seleccionada (21.500000, -104.500000)',
      );
      expect(selected?.coordinates.latitude, 21.5);
      expect(selected?.coordinates.longitude, -104.5);
      expect(selected?.city, isNull);
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) async => _tile()));
  });
  testWidgets('offline city lookup can be retried for the current point', (
    tester,
  ) async {
    var attempts = 0;
    await http.runWithClient(
      () async {
        await _open(tester);
        tester.widget<FlutterMap>(find.byType(FlutterMap)).options.onTap!(
          const TapPosition(Offset.zero, Offset.zero),
          const LatLng(19.5, -99.2),
        );
        await tester.pumpAndSettle();
        expect(find.text('Reintentar ubicación'), findsOneWidget);
        await tester.tap(find.text('Reintentar ubicación'));
        await tester.pumpAndSettle();
        expect(find.text('Dirección recuperada'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      },
      () => MockClient((request) async {
        if (!request.url.path.endsWith('/geocoding')) return _tile();
        attempts++;
        if (attempts == 1) return http.Response('offline', 503);
        return http.Response(
          jsonEncode({
            'place': {
              'label': 'Dirección recuperada',
              'latitude': 19.5,
              'longitude': -99.2,
              'city': {'name': 'Ciudad recuperada'},
            },
          }),
          200,
        );
      }),
    );
  });

  testWidgets(
    'approximate selection resolves the city of its stored rounded point',
    (tester) async {
      await http.runWithClient(
        () async {
          PostLocationSelection? selected;
          await _open(
            tester,
            initial: const PostLocationSelection(
              label: 'Full address',
              coordinates: PostCoordinates(
                latitude: 19.434567,
                longitude: -99.134567,
                precision: PostLocationPrecision.exact,
              ),
              city: LocationCity(name: 'Exact city'),
            ),
            onSelection: (value) => selected = value,
          );
          await tester.tap(find.text('Aproximada'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Usar esta ubicación'));
          await tester.pumpAndSettle();
          expect(selected?.coordinates.latitude, 19.43);
          expect(selected?.city?.name, 'Approximate city');
        },
        () => MockClient((request) async {
          if (!request.url.path.endsWith('/geocoding')) return _tile();
          final body = jsonDecode(request.body);
          expect(body['latitude'], 19.43);
          expect(body['longitude'], -99.13);
          return http.Response(
            jsonEncode({
              'place': {
                'label': 'Rounded area',
                'latitude': 19.43,
                'longitude': -99.13,
                'city': {'name': 'Approximate city'},
              },
            }),
            200,
          );
        }),
      );
    },
  );

  testWidgets(
    'late reverse lookup cannot restore the previous points address or city',
    (tester) async {
      final old = Completer<http.Response>();
      final current = Completer<http.Response>();
      await http.runWithClient(
        () async {
          PostLocationSelection? selected;
          await _open(tester, onSelection: (value) => selected = value);
          final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
          map.options.onTap!(
            const TapPosition(Offset.zero, Offset.zero),
            const LatLng(19, -98),
          );
          await tester.pump();
          map.options.onTap!(
            const TapPosition(Offset.zero, Offset.zero),
            const LatLng(20, -99),
          );
          current.complete(
            http.Response(
              jsonEncode({
                'place': {
                  'label': 'Current address',
                  'latitude': 20,
                  'longitude': -99,
                  'city': {'name': 'Current city'},
                },
              }),
              200,
            ),
          );
          await tester.pumpAndSettle();
          old.complete(
            http.Response(
              jsonEncode({
                'place': {
                  'label': 'Old address',
                  'latitude': 19,
                  'longitude': -98,
                  'city': {'name': 'Old city'},
                },
              }),
              200,
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Old address'), findsNothing);
          await tester.tap(find.text('Usar esta ubicación'));
          await tester.pumpAndSettle();
          expect(selected?.label, 'Current address');
          expect(selected?.city?.name, 'Current city');
          expect(selected?.coordinates.latitude, 20);
        },
        () => MockClient((request) async {
          if (!request.url.path.endsWith('/geocoding')) return _tile();
          return jsonDecode(request.body)['latitude'] == 19
              ? old.future
              : current.future;
        }),
      );
    },
  );
}
