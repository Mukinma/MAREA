import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'map_surface.dart';
import 'mapbox_surface.dart';

/// The same renderer in a precise top-down mode for existing location flows.
class LocationMap extends StatefulWidget {
  const LocationMap({
    required this.point,
    this.controller,
    this.initialZoom = 14,
    this.onReady,
    this.ornamentBottom = 12,
    this.onTap,
    this.onGesture,
    this.captureGestures = false,
    super.key,
  });
  final LatLng point;
  final MapSurfaceController? controller;
  final double initialZoom;
  final double ornamentBottom;
  final VoidCallback? onReady;
  final ValueChanged<LatLng>? onTap;
  final VoidCallback? onGesture;
  final bool captureGestures;
  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  late final _controller = widget.controller ?? MapSurfaceController();
  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MareaMapSurface(
    options: MapSurfaceOptions(
      controller: _controller,
      initialCenter: widget.point,
      initialZoom: widget.initialZoom,
      ornamentBottom: widget.ornamentBottom,
      captureGestures: widget.captureGestures,
      onReady: () => widget.onReady?.call(),
      onIdle: () {},
      onGesture: () => widget.onGesture?.call(),
      onTap: (point) => widget.onTap?.call(point),
      points: [
        MapSurfacePoint(
          id: 'selected-location',
          position: widget.point,
          label: 'Ubicación seleccionada',
          clusterable: false,
          color: Colors.red,
          icon: Icons.location_pin,
        ),
      ],
    ),
  );
}
