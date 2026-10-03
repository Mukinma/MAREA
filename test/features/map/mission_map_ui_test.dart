import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/map/data/mission_map_repository.dart';
import 'package:marea/features/map/models/mission_map_models.dart';
import 'package:marea/features/map/presentation/mission_map_screen.dart';
import 'package:marea/features/shell/presentation/app_shell.dart';
import '../../support/fakes.dart';
import 'mission_map_test.dart' show mission;

class MapFake implements MissionMapRepository {
  int calls = 0;
  List<MissionMapFilters> filters = [];
  bool empty = false;
  int count = 1;
  @override
  Future<MissionMapPage> fetch({
    required MapBounds bounds,
    required MissionMapFilters filters,
    required String query,
    required DateTime now,
  }) async {
    calls++;
    this.filters.add(filters);
    return empty
        ? const MissionMapPage(missions: [], total: 0)
        : MissionMapPage(
            missions: List.generate(
              count,
              (i) => mission(count == 1 ? 'one' : 'cluster-$i'),
            ),
            total: count,
          );
  }
}

class LocationFake implements DeviceLocationService {
  final prompts = <bool>[];
  Completer<DevicePosition>? pending;
  @override
  Future<DevicePosition> current({
    bool requestPermission = false,
    bool Function()? isCurrent,
  }) async {
    prompts.add(requestPermission);
    if (requestPermission && pending != null) return pending!.future;
    throw const DeviceLocationFailure(
      DeviceLocationFailureKind.permissionRequired,
    );
  }

  @override
  Future<bool> openSettings({bool locationDisabled = false}) async => false;
}

Future<void> withTiles(Future<void> Function() test) => http.runWithClient(
  test,
  () => MockClient(
    (_) async => http.Response.bytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
      200,
      headers: {'content-type': 'image/png'},
    ),
  ),
);
void main() {
  Future<(MapFake, LocationFake)> open(
    WidgetTester tester, {
    double width = 390,
    bool empty = false,
    int count = 1,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MapFake()
      ..empty = empty
      ..count = count;
    final location = LocationFake();
    final session = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: FakeProfileRepository(),
      missionMapRepository: repo,
    );
    addTearDown(session.dispose);
    final router = GoRouter(
      initialLocation: '/map',
      routes: [
        ShellRoute(
          builder: (_, state, child) =>
              AppShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(
              path: '/map',
              builder: (_, _) =>
                  MissionMapScreen(session: session, locationService: location),
            ),
          ],
        ),
        GoRoute(
          path: '/missions/:id',
          builder: (_, state) => Scaffold(
            body: Column(
              children: [
                Text('Detalle ${state.pathParameters['id']}'),
                Builder(
                  builder: (context) => TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Volver'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (repo, location);
  }

  testWidgets('select preview before navigation and retain camera on return', (
    tester,
  ) async {
    await withTiles(() async {
      final (repo, location) = await open(tester);
      expect(location.prompts, [false]);
      expect(find.text('Ver misión'), findsNothing);
      await tester.tap(find.byTooltip('Arte local'));
      await tester.pumpAndSettle();
      expect(find.text('Ver misión'), findsOneWidget);
      expect(find.text('Detalle one'), findsNothing);
      final camera = MapController.of(
        tester.element(find.byType(TileLayer)),
      ).camera.center;
      await tester.tap(find.text('Ver misión'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle one'), findsOneWidget);
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(
        MapController.of(tester.element(find.byType(TileLayer))).camera.center,
        camera,
      );
      expect(repo.calls, 2);
      await tester.tap(find.byTooltip('Cerrar misión'));
      await tester.pumpAndSettle();
      expect(find.text('Ver misión'), findsNothing);
    });
  });
  testWidgets('drag requires explicit zone search and today filter is sent', (
    tester,
  ) async {
    await withTiles(() async {
      final (repo, _) = await open(tester);
      expect(repo.calls, 1);
      await tester.dragFrom(const Offset(150, 400), const Offset(140, 0));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Buscar en esta zona'), findsOneWidget);
      expect(repo.calls, 1);
      await tester.tap(find.text('Buscar en esta zona'));
      await tester.pumpAndSettle();
      expect(repo.calls, 2);
      await tester.tap(find.text('Hoy'));
      await tester.pumpAndSettle();
      expect(repo.filters.last.date, MissionMapDate.today);
    });
  });
  testWidgets('cluster count is real and coincident missions can be selected', (
    tester,
  ) async {
    await withTiles(() async {
      await open(tester, count: 3);
      expect(find.text('3'), findsOneWidget);
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
      if (find.byTooltip('Arte local').hitTestable().evaluate().isEmpty) {
        await tester.tap(find.text('3'));
        await tester.pumpAndSettle();
      }
      expect(find.byTooltip('Arte local').hitTestable(), findsNWidgets(3));
      await tester.tap(find.byTooltip('Arte local').hitTestable().first);
      await tester.pumpAndSettle();
      expect(find.text('Ver misión'), findsOneWidget);
    });
  });
  testWidgets('location permission is requested only by the location action', (
    tester,
  ) async {
    await withTiles(() async {
      final (_, location) = await open(tester);
      expect(location.prompts, [false]);
      await tester.tap(find.byTooltip('Centrar en mi ubicación'));
      await tester.pumpAndSettle();
      expect(location.prompts, [false, true]);
      expect(find.byType(FlutterMap), findsOneWidget);
    });
  });
  testWidgets('a pan cancels recenter from a pending explicit GPS request', (
    tester,
  ) async {
    await withTiles(() async {
      final (repo, location) = await open(tester);
      location.pending = Completer<DevicePosition>();
      await tester.tap(find.byTooltip('Centrar en mi ubicación'));
      await tester.pump();
      await tester.dragFrom(const Offset(150, 400), const Offset(140, 0));
      await tester.pump(const Duration(milliseconds: 300));
      final camera = MapController.of(
        tester.element(find.byType(TileLayer)),
      ).camera.center;
      location.pending!.complete(
        const DevicePosition(latitude: 19.4326, longitude: -99.1332),
      );
      await tester.pumpAndSettle();
      expect(
        MapController.of(tester.element(find.byType(TileLayer))).camera.center,
        camera,
      );
      expect(repo.calls, 1);
    });
  });
  for (final width in [360.0, 390.0, 800.0, 1366.0]) {
    testWidgets('map and empty state stay accessible at $width', (
      tester,
    ) async {
      await withTiles(() async {
        await open(tester, width: width, empty: true, scale: 1.3);
        expect(find.byType(FlutterMap), findsOneWidget);
        expect(
          find.text('No encontramos misiones por aquí todavía.'),
          findsOneWidget,
        );
        expect(find.text('© OpenStreetMap'), findsOneWidget);
        expect(
          find.byTooltip('Centrar en mi ubicación').hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip('Filtros del mapa'));
        await tester.pumpAndSettle();
        expect(find.text('Limpiar filtros'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
