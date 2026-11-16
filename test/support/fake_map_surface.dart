import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:marea/core/maps/map_clustering.dart';
import 'package:marea/core/maps/map_surface.dart';
import 'package:marea/features/map/models/mission_map_models.dart';

Widget fakeMapSurfaceBuilder(BuildContext context, MapSurfaceOptions options) =>
    FakeMapSurface(options: options);

/// Rendering boundary only. No network, GPU, SDK or permission behavior is mocked
/// inside the real screens/controllers/repositories exercised by widget tests.
class FakeMapSurface extends StatefulWidget {
  const FakeMapSurface({required this.options, this.beforeCapture, super.key});
  final MapSurfaceOptions options;
  final Future<void> Function()? beforeCapture;
  @override
  State<FakeMapSurface> createState() => _FakeMapSurfaceState();
}

class _FakeMapSurfaceState extends State<FakeMapSurface>
    implements MapSurfaceDriver {
  MapSurfaceOptions get options => widget.options;
  late LatLng _center = options.initialCenter;
  late double _zoom = options.initialZoom;
  late double _pitch = options.pitch;
  double _bearing = 0;
  Size _size = Size.zero;
  String? _expanded;
  @override
  void initState() {
    super.initState();
    options.controller.attach(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) options.onReady();
    });
  }

  @override
  void dispose() {
    options.controller.detach(this);
    super.dispose();
  }

  @override
  Future<MapViewport> capture() async {
    await widget.beforeCapture?.call();
    return MapViewport(
      center: _center,
      zoom: _zoom,
      pitch: _pitch,
      bearing: _bearing,
      bounds: MapBounds(
        south: _center.latitude - .015,
        north: _center.latitude + .015,
        west: _center.longitude - .015,
        east: _center.longitude + .015,
      ),
    );
  }

  @override
  Future<void> move(LatLng point, {double? zoom}) async {
    setState(() {
      _center = point;
      _zoom = zoom ?? _zoom;
    });
  }

  @override
  Future<void> reveal(LatLng point, Rect area) async {}
  @override
  Future<void> updateCamera({double? pitch, double? bearing}) async {
    _pitch = pitch ?? _pitch;
    _bearing = bearing ?? _bearing;
  }

  @override
  Future<void> cancel() async {}
  @override
  Future<void> reload() async {
    options.onLoaded?.call();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _size = constraints.biggest;
      final groups = clusterMapPoints([
        for (final point in options.points)
          MapProjectedPoint(
            point,
            Offset(
              _size.width / 2 +
                  (point.position.longitude - _center.longitude) *
                      _size.width /
                      .03,
              _size.height / 2 -
                  (point.position.latitude - _center.latitude) *
                      _size.height /
                      .03,
            ),
          ),
      ]);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (tap) => options.onTap(
          LatLng(
            _center.latitude -
                (tap.localPosition.dy - _size.height / 2) * .03 / _size.height,
            _center.longitude +
                (tap.localPosition.dx - _size.width / 2) * .03 / _size.width,
          ),
        ),
        onPanStart: (_) => options.onGesture(),
        onPanUpdate: (pan) => setState(
          () => _center = LatLng(
            _center.latitude,
            _center.longitude - pan.delta.dx * .03 / _size.width,
          ),
        ),
        onPanEnd: (_) => options.onIdle(),
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Color(0xFFF7FAFC))),
            for (final group in groups)
              if (group.members.length == 1)
                _marker(group.anchor, group.anchor.offset)
              else if (_expanded == group.anchor.point.id)
                for (var i = 0; i < group.members.length; i++)
                  _marker(
                    group.members[i],
                    Offset(
                      _size.width / 2 +
                          (i - (group.members.length - 1) / 2) * 65,
                      _size.height / 2 + 50,
                    ),
                  )
              else
                Positioned(
                  left: group.anchor.offset.dx - 24,
                  top: group.anchor.offset.dy - 24,
                  width: 48,
                  height: 48,
                  child: Semantics(
                    label: '${group.members.length} misiones agrupadas',
                    button: true,
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _expanded = group.anchor.point.id),
                      child: Text('${group.members.length}'),
                    ),
                  ),
                ),
            Positioned(
              left: 12,
              bottom: options.ornamentBottom,
              child: const Text(
                'Mapbox · © OpenStreetMap',
                key: Key('map-attribution'),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _marker(MapProjectedPoint item, Offset offset) => Positioned(
    left: math.max(0, offset.dx - 24),
    top: math.max(0, offset.dy - 24),
    width: 48,
    height: 48,
    child:
        item.point.expandedBuilder?.call(context) ??
        IconButton(
          tooltip: item.point.label,
          onPressed: item.point.onTap,
          icon: Icon(item.point.icon),
        ),
  );
}
