import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:marea/features/map/models/mission_map_models.dart';

/// Keep GeoJSON's longitude/latitude order at the SDK boundary.
abstract final class MapboxGeography {
  static mb.Point point(LatLng p) =>
      mb.Point(coordinates: mb.Position(p.longitude, p.latitude));
  static LatLng latLng(mb.Point p) => LatLng(
    p.coordinates.lat.toDouble(),
    MapBounds.normalizeLongitude(p.coordinates.lng.toDouble()),
  );
  static MapBounds bounds(mb.CoordinateBounds bounds) {
    final west = bounds.southwest.coordinates.lng.toDouble();
    final east = bounds.northeast.coordinates.lng.toDouble();
    return MapBounds(
      south: bounds.southwest.coordinates.lat.toDouble().clamp(-90, 90),
      north: bounds.northeast.coordinates.lat.toDouble().clamp(-90, 90),
      west: east - west >= 360 ? -180 : MapBounds.normalizeLongitude(west),
      east: east - west >= 360 ? 180 : MapBounds.normalizeLongitude(east),
    );
  }
}
