import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:marea/core/maps/map_surface.dart';
import 'package:marea/core/maps/map_clustering.dart';

void main() {
  MapProjectedPoint point(String id, double x) => MapProjectedPoint(
    MapSurfacePoint(id: id, position: const LatLng(19, -99), label: id),
    Offset(x, 100),
  );
  test(
    'clusters are bounded by their anchor rather than transitive chains',
    () {
      final groups = clusterMapPoints([
        point('d', 120),
        point('b', 40),
        point('c', 80),
        point('a', 0),
      ]);
      expect(groups.map((g) => g.members.map((p) => p.point.id).toList()), [
        ['a', 'b'],
        ['c', 'd'],
      ]);
    },
  );
  test('coincident points retain all real identities', () {
    final groups = clusterMapPoints(List.generate(300, (i) => point('$i', 50)));
    expect(groups.single.members.length, 300);
    expect(groups.single.members.map((p) => p.point.id).toSet().length, 300);
  });
  test('nonfinite projected points never produce selectable clusters', () {
    expect(clusterMapPoints([point('bad', double.nan)]), isEmpty);
  });
}
