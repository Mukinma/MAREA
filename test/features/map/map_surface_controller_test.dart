import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:marea/core/config/mapbox_configuration.dart';
import 'package:marea/core/maps/map_surface.dart';
import 'package:marea/features/map/models/mission_map_models.dart';

class _Driver implements MapSurfaceDriver {
  final captures = <Completer<MapViewport>>[];
  @override
  Future<MapViewport> capture() {
    final pending = Completer<MapViewport>();
    captures.add(pending);
    return pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _viewport = MapViewport(
  center: LatLng(19, -99),
  zoom: 15,
  bounds: MapBounds(south: 18, north: 20, west: -100, east: -98),
);

void main() {
  test('older viewport completion cannot overwrite a newer capture', () async {
    final controller = MapSurfaceController();
    final driver = _Driver();
    controller.attach(driver);
    final older = controller.capture();
    final newer = controller.capture();
    driver.captures[1].complete(_viewport);
    expect(await newer, same(_viewport));
    driver.captures[0].complete(_viewport);
    expect(await older, isNull);
    expect(controller.viewport, same(_viewport));
  });
  test('detach and disposal invalidate pending captures', () async {
    for (final dispose in [false, true]) {
      final controller = MapSurfaceController();
      final driver = _Driver();
      controller.attach(driver);
      final pending = controller.capture();
      if (dispose) {
        controller.dispose();
      } else {
        controller.detach(driver);
      }
      driver.captures.single.complete(_viewport);
      expect(await pending, isNull);
      expect(controller.isAttached, isFalse);
      expect(await controller.capture(), isNull);
    }
  });
  test('a secret token or an empty define never configures a public map', () {
    expect(const MapboxConfiguration(accessToken: '').isConfigured, isFalse);
    expect(
      const MapboxConfiguration(accessToken: 'sk.private').isConfigured,
      isFalse,
    );
  });
}
