import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:marea/features/map/models/mission_map_models.dart';

enum MapViewMode { twoD, threeD }

enum MapCameraChangeReason { exploration, presentation }

enum MapVisualPreset { context, discovery }

class MapSurfacePoint {
  const MapSurfacePoint({
    required this.id,
    required this.position,
    required this.label,
    this.color = const Color(0xFF2EC4B6),
    this.icon = Icons.location_on,
    this.selected = false,
    this.clusterable = true,
    this.onTap,
    this.expandedBuilder,
    this.semanticsLabel,
  });
  final String id, label;
  final String? semanticsLabel;
  final LatLng position;
  final Color color;
  final IconData icon;
  final bool selected, clusterable;
  final VoidCallback? onTap;
  final WidgetBuilder? expandedBuilder;
}

class MapViewport {
  const MapViewport({
    required this.center,
    required this.bounds,
    required this.zoom,
    this.pitch = 0,
    this.bearing = 0,
  });
  final LatLng center;
  final MapBounds bounds;
  final double zoom, pitch, bearing;

  /// A rotation or tilt can change the bounding box without changing the area
  /// the user is exploring. Measure actual center and scale for mixed gestures.
  bool hasSignificantMotion(LatLng nextCenter, double nextZoom) {
    final latitudeShift = (nextCenter.latitude - center.latitude).abs();
    final longitudeShift = MapBounds.normalizeLongitude(
      nextCenter.longitude - center.longitude,
    ).abs();
    final scaleChange = (math.pow(2, zoom - nextZoom) - 1).abs();
    return latitudeShift >= bounds.latitudeSpan * .25 ||
        longitudeShift >= bounds.longitudeSpan * .25 ||
        scaleChange >= .25;
  }
}

abstract interface class MapSurfaceDriver {
  Future<MapViewport> capture();
  Future<void> move(LatLng center, {double? zoom});
  Future<void> reveal(LatLng point, Rect usableArea);
  Future<void> cancel();
  Future<void> reload();
  Future<void> updateCamera({double? pitch, double? bearing});
}

/// The screen owns this handle; the surface owns the platform view.
class MapSurfaceController extends ChangeNotifier {
  MapSurfaceDriver? _driver;
  MapViewport? viewport;
  int _captureGeneration = 0;
  int? _queryCapture;
  bool _disposed = false;
  double _last3DPitch = 45;
  int _cameraOperation = 0;
  bool cameraBusy = false;
  Rect? usableArea;
  Rect? controlsArea;
  MapViewMode get viewMode =>
      (viewport?.pitch ?? 45) <= 5 ? MapViewMode.twoD : MapViewMode.threeD;
  bool get isRotated {
    final bearing = viewport?.bearing ?? 0;
    return ((bearing + 180) % 360 - 180).abs() > 5;
  }

  Future<void> setPerspective(MapViewMode mode) async {
    await _changeCamera(pitch: mode == MapViewMode.twoD ? 0 : _last3DPitch);
  }

  Future<void> resetNorth() async => _changeCamera(bearing: 0);
  Future<void> _changeCamera({double? pitch, double? bearing}) async {
    if (!isAttached) return;
    final operation = ++_cameraOperation;
    cameraBusy = true;
    notifyListeners();
    try {
      await _driver?.updateCamera(pitch: pitch, bearing: bearing);
      if (!_disposed && operation == _cameraOperation) await observe();
    } finally {
      if (!_disposed && operation == _cameraOperation) {
        cameraBusy = false;
        notifyListeners();
      }
    }
  }

  bool get isAttached => !_disposed && _driver != null;

  void attach(MapSurfaceDriver driver) {
    if (_disposed) return;
    ++_captureGeneration;
    _queryCapture = null;
    _driver = driver;
  }

  void detach(MapSurfaceDriver driver) {
    if (_driver != driver) return;
    ++_captureGeneration;
    _queryCapture = null;
    _driver = null;
  }

  Future<MapViewport?> capture() => _capture(forQuery: true);

  /// Camera updates must not supersede a snapshot requested for a query.
  Future<MapViewport?> observe() => _capture(forQuery: false);

  Future<MapViewport?> _capture({required bool forQuery}) async {
    final driver = _driver;
    if (_disposed || driver == null || (!forQuery && _queryCapture != null)) {
      return null;
    }
    final generation = ++_captureGeneration;
    if (forQuery) _queryCapture = generation;
    try {
      final value = await driver.capture();
      if (_disposed || generation != _captureGeneration || driver != _driver) {
        return null;
      }
      final previous = viewport;
      viewport = value;
      if (value.pitch > 5) _last3DPitch = value.pitch.clamp(5, 60);
      if (previous?.pitch != value.pitch ||
          previous?.bearing != value.bearing) {
        notifyListeners();
      }
      return value;
    } finally {
      if (_queryCapture == generation) _queryCapture = null;
    }
  }

  /// Controls sit at the lower right of the usable map. Keep both the area
  /// above them and the area to their left available for focusing a marker.
  Iterable<Rect> unobstructedRegions(Rect bounds) sync* {
    final obstacle = controlsArea?.inflate(24);
    if (obstacle == null || !bounds.overlaps(obstacle)) {
      if (!bounds.isEmpty) yield bounds;
      return;
    }
    if (obstacle.top > bounds.top) {
      yield Rect.fromLTRB(bounds.left, bounds.top, bounds.right, obstacle.top);
    }
    if (obstacle.left > bounds.left) {
      yield Rect.fromLTRB(
        bounds.left,
        bounds.top,
        obstacle.left,
        bounds.bottom,
      );
    }
  }

  Future<void> move(LatLng point, {double? zoom}) async =>
      _driver?.move(point, zoom: zoom);
  Future<void> reveal(LatLng point, Rect area) async =>
      _driver?.reveal(point, area);
  Future<void> cancel() async {
    ++_cameraOperation;
    if (!_disposed && cameraBusy) {
      cameraBusy = false;
      notifyListeners();
    }
    await _driver?.cancel();
  }

  Future<void> reload() async => _driver?.reload();
  @override
  void dispose() {
    _disposed = true;
    ++_captureGeneration;
    _driver = null;
    super.dispose();
  }
}

class MapSurfaceOptions {
  const MapSurfaceOptions({
    required this.controller,
    required this.initialCenter,
    required this.onReady,
    required this.onIdle,
    required this.onGesture,
    required this.onTap,
    this.points = const [],
    this.initialZoom = 15,
    this.pitch = 0,
    this.ornamentBottom = 12,
    this.onError,
    this.onLoaded,
    this.onClusterTap,
    this.preset = MapVisualPreset.context,
  });
  final MapVisualPreset preset;
  final MapSurfaceController controller;
  final LatLng initialCenter;
  final List<MapSurfacePoint> points;
  final double initialZoom, pitch, ornamentBottom;
  final VoidCallback onReady, onIdle, onGesture;
  final ValueChanged<LatLng> onTap;
  final ValueChanged<String>? onError;
  final VoidCallback? onLoaded;
  final VoidCallback? onClusterTap;
}

typedef MapSurfaceBuilder = Widget Function(BuildContext, MapSurfaceOptions);

/// Tests replace only the rendering boundary, retaining the real screen state.
class MapSurfaceScope extends InheritedWidget {
  const MapSurfaceScope({
    required this.builder,
    required super.child,
    super.key,
  });
  final MapSurfaceBuilder builder;
  static MapSurfaceBuilder? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MapSurfaceScope>()?.builder;
  @override
  bool updateShouldNotify(MapSurfaceScope oldWidget) =>
      builder != oldWidget.builder;
}
