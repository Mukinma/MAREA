import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:marea/core/maps/mapbox_geography.dart';

void main() {
  test(
    'Mapbox uses longitude then latitude and round-trips the real point',
    () {
      const original = LatLng(19.4326, -99.1332);
      final point = MapboxGeography.point(original);
      expect(point.coordinates.lng, -99.1332);
      expect(point.coordinates.lat, 19.4326);
      expect(MapboxGeography.latLng(point), original);
    },
  );
  test(
    'unwrapped bounds keep date-line crossings and whole-world coverage',
    () {
      final crossing = MapboxGeography.bounds(
        mb.CoordinateBounds(
          southwest: mb.Point(coordinates: mb.Position(170, -10)),
          northeast: mb.Point(coordinates: mb.Position(190, 10)),
          infiniteBounds: false,
        ),
      );
      expect(crossing.west, 170);
      expect(crossing.east, -170);
      expect(crossing.longitudeSpan, 20);
      final world = MapboxGeography.bounds(
        mb.CoordinateBounds(
          southwest: mb.Point(coordinates: mb.Position(-200, -80)),
          northeast: mb.Point(coordinates: mb.Position(200, 80)),
          infiniteBounds: false,
        ),
      );
      expect(world.west, -180);
      expect(world.east, 180);
      expect(world.isValid, isTrue);
    },
  );
}
