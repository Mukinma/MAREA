import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/tours/data/tour_repository.dart';
import 'package:marea/features/tours/models/tour_models.dart';
import 'package:marea/features/tours/presentation/tour_discovery_screen.dart';
import '../../support/fakes.dart';

class DiscoveryTours implements TourRepository {
  final lookups = <(double?, double?)>[];
  bool failFirst = false, failNearby = false;

  @override
  Future<List<TourRecord>> list({
    String? owner,
    double? latitude,
    double? longitude,
  }) async {
    lookups.add((latitude, longitude));
    if (failFirst && lookups.length == 1) throw StateError('Sin conexión');
    if (failNearby && latitude != null) {
      failNearby = false;
      throw StateError('Consulta interrumpida');
    }
    return [
      TourRecord({
        'id': 'far',
        'title': 'Local más lejano',
        'space': {
          'location_label': 'Centro',
          'latitude': 19.4426,
          'longitude': -99.1332,
        },
      }),
      TourRecord({
        'id': 'near',
        'title': 'Local cercano',
        'space': {
          'location_label': 'En esta zona',
          'latitude': 19.4326,
          'longitude': -99.1332,
        },
      }),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DiscoveryLocation implements DeviceLocationService {
  final prompts = <bool>[];
  DeviceLocationFailure? failure;

  @override
  Future<DevicePosition> current({
    bool requestPermission = false,
    bool Function()? isCurrent,
  }) async {
    prompts.add(requestPermission);
    if (failure != null) throw failure!;
    return const DevicePosition(latitude: 19.4326, longitude: -99.1332);
  }

  @override
  Future<bool> openSettings({bool locationDisabled = false}) async => false;
}

Future<void> mountDiscovery(
  WidgetTester tester,
  DiscoveryTours tours,
  DiscoveryLocation location,
) async {
  final controller = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: FakeProfileRepository(),
    tourRepository: tours,
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: TourDiscoveryScreen(
        controller: controller,
        locationService: location,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('nearby lookup is explicit and shows approximate nearest first', (
    tester,
  ) async {
    final tours = DiscoveryTours(), location = DiscoveryLocation();
    await mountDiscovery(tester, tours, location);
    expect(location.prompts, isEmpty);
    expect(tours.lookups, [(null, null)]);

    await tester.tap(find.text('Descubrir cerca de mí'));
    await tester.pumpAndSettle();
    expect(location.prompts, [true]);
    expect(tours.lookups.last, (19.4326, -99.1332));
    expect(find.textContaining('A 0 m aproximadamente'), findsOneWidget);
    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect((tiles.first.title! as Text).data, 'Local cercano');
    expect(find.text('Actualizar cerca de mí'), findsOneWidget);
    await tester.tap(find.byTooltip('Más opciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver todos los locales'));
    await tester.pumpAndSettle();
    expect(tours.lookups.last, (null, null));
    expect(find.textContaining('A 0 m aproximadamente'), findsNothing);
    expect(find.text('Descubrir cerca de mí'), findsOneWidget);
    expect(location.prompts, [true]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retry preserves nearby coordinates and avoids async setState', (
    tester,
  ) async {
    final tours = DiscoveryTours()..failNearby = true;
    await mountDiscovery(tester, tours, DiscoveryLocation());
    await tester.tap(find.text('Descubrir cerca de mí'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(tours.lookups, [
      (null, null),
      (19.4326, -99.1332),
      (19.4326, -99.1332),
    ]);
    expect(find.text('Local cercano'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'initial load can retry and denied GPS retains readable results',
    (tester) async {
      final tours = DiscoveryTours()..failFirst = true;
      final location = DiscoveryLocation()
        ..failure = const DeviceLocationFailure(
          DeviceLocationFailureKind.denied,
        );
      await mountDiscovery(tester, tours, location);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(tours.lookups, [(null, null), (null, null)]);
      await tester.tap(find.text('Descubrir cerca de mí'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Permite la ubicación'), findsOneWidget);
      expect(find.text('Local cercano'), findsOneWidget);
      expect(tours.lookups.length, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
