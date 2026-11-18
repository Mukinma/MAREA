import 'package:flutter/painting.dart';
import 'map_surface.dart';

class MapProjectedPoint {
  const MapProjectedPoint(this.point, this.offset);
  final MapSurfacePoint point;
  final Offset offset;
}

class MapPointGroup {
  MapPointGroup(this.anchor) : members = [anchor];
  final MapProjectedPoint anchor;
  final List<MapProjectedPoint> members;
}

/// A bounded star, not a transitive component: long chains must remain separate.
List<MapPointGroup> clusterMapPoints(
  List<MapProjectedPoint> points, {
  double radius = 48,
}) {
  final sorted =
      points.where((p) => p.offset.dx.isFinite && p.offset.dy.isFinite).toList()
        ..sort((a, b) => a.point.id.compareTo(b.point.id));
  final groups = <MapPointGroup>[];
  for (final point in sorted) {
    MapPointGroup? target;
    if (point.point.clusterable) {
      for (final group in groups) {
        if (group.anchor.point.clusterable &&
            (point.offset - group.anchor.offset).distance <= radius) {
          target = group;
          break;
        }
      }
    }
    if (target == null) {
      groups.add(MapPointGroup(point));
    } else {
      target.members.add(point);
    }
  }
  return groups;
}
