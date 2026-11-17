import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:marea/core/maps/map_surface.dart';
import 'package:marea/features/map/models/mission_map_models.dart';

class CameraDriver implements MapSurfaceDriver {
  double pitch = 47, bearing = 80, zoom = 15;
  final center = const LatLng(19.43, -99.13);
  @override
  Future<MapViewport> capture() async => MapViewport(
    center: center,
    zoom: zoom,
    pitch: pitch,
    bearing: bearing,
    bounds: const MapBounds(south: 19.4, north: 19.5, west: -99.2, east: -99.1),
  );
  @override
  Future<void> updateCamera({double? pitch, double? bearing}) async {
    this.pitch = pitch ?? this.pitch;
    this.bearing = bearing ?? this.bearing;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'mixed rotation tracks actual exploration rather than the changed bounding box',
    () async {
      final driver = CameraDriver();
      final before = await driver.capture();
      expect(before.hasSignificantMotion(driver.center, 15), isFalse);
      expect(before.hasSignificantMotion(driver.center, 16), isTrue);
      expect(
        before.hasSignificantMotion(const LatLng(19.43, -99.09), 15),
        isTrue,
      );
    },
  );

  test(
    'perspective round trip retains center, zoom, bearing and last 3D pitch',
    () async {
      final driver = CameraDriver();
      final controller = MapSurfaceController()..attach(driver);
      await controller.capture();
      await controller.setPerspective(MapViewMode.twoD);
      expect(controller.viewMode, MapViewMode.twoD);
      expect(driver.pitch, 0);
      await controller.setPerspective(MapViewMode.threeD);
      expect(driver.pitch, 47);
      expect(controller.viewport!.center, driver.center);
      expect(driver.zoom, 15);
      expect(driver.bearing, 80);
      controller.dispose();
    },
  );
  test(
    'north reset changes only orientation and gestures update the mode',
    () async {
      final driver = CameraDriver();
      final controller = MapSurfaceController()..attach(driver);
      await controller.capture();
      await controller.resetNorth();
      expect(driver.bearing, 0);
      expect(driver.pitch, 47);
      driver.pitch = 3;
      await controller.capture();
      expect(controller.viewMode, MapViewMode.twoD);
      expect(controller.viewport!.center, driver.center);
      controller.dispose();
    },
  );
}
