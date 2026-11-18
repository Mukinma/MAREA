import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:marea/core/config/mapbox_configuration.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'mapbox_geography.dart';
import 'package:marea/shared/widgets/marea_panel.dart';
import 'map_clustering.dart';
import 'map_overlay.dart';
import 'map_surface.dart';
import 'mapbox_style.dart';
import 'mapbox_interactions.dart';

class MareaMapSurface extends StatelessWidget {
  const MareaMapSurface({required this.options, super.key});
  final MapSurfaceOptions options;
  @override
  Widget build(BuildContext context) {
    final replacement = MapSurfaceScope.maybeOf(context);
    if (replacement != null) return replacement(context, options);
    if (!const MapboxConfiguration().isConfigured) {
      return const ColoredBox(
        color: Color(0xFFF7FAFC),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'El mapa necesita configurar Mapbox.\nPuedes seguir usando MAREA.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    initializeMareaMapbox();
    return _MapboxSurface(options: options);
  }
}

class _MapboxSurface extends StatefulWidget {
  const _MapboxSurface({required this.options});
  final MapSurfaceOptions options;
  @override
  State<_MapboxSurface> createState() => _MapboxSurfaceState();
}

class _MapboxSurfaceState extends State<_MapboxSurface>
    implements MapSurfaceDriver {
  MapSurfaceOptions get options => widget.options;
  mb.MapboxMap? _map;
  Future<void>? _mapSetup;
  bool _cameraReady = false;
  mb.CameraState? _latestCamera;
  bool _presentationGesture = false;
  late final _initialCamera = mb.CameraOptions(
    center: MapboxGeography.point(options.initialCenter),
    zoom: options.initialZoom,
    pitch: options.pitch,
    bearing: 0,
  );
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _sprites = <String>{};
  List<MapPointGroup> _groups = [];
  final _tooltips = <String, GlobalKey<TooltipState>>{};
  String? _hovered;
  MapCameraChangeReason? _cameraReason;
  List<MapProjectedPoint> _expanded = [];
  Timer? _idle, _pointUpdate;
  Size _size = Size.zero;
  bool _styled = false, _moving = false, _loading = true;
  String? _error;
  int _generation = 0, _styleGeneration = 0, _cameraEpoch = 0;
  int? _animationEpoch;
  String? _sourceData;
  bool _updating = false, _updatePending = false;

  @override
  void didUpdateWidget(_MapboxSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.controller != options.controller) {
      oldWidget.options.controller.detach(this);
      options.controller.attach(this);
    }
    if (oldWidget.options.points != options.points) {
      if (_expanded.isNotEmpty) {
        final pointsById = {
          for (final point in options.points) point.id: point,
        };
        _expanded = [
          for (final projected in _expanded)
            if (pointsById[projected.point.id] case final point?)
              MapProjectedPoint(point, projected.offset),
        ];
      }
      _scheduleUpdate();
    }
    if (oldWidget.options.ornamentBottom != options.ornamentBottom) {
      unawaited(_ornaments());
    }
  }

  Future<void> _created(mb.MapboxMap map) async {
    _map = map;
    options.controller.attach(this);
    for (final (stream, reason) in [
      (map.gestures.pan.gestureEvents, MapCameraChangeReason.exploration),
      (map.gestures.zoom.gestureEvents, MapCameraChangeReason.exploration),
      (map.gestures.rotate.gestureEvents, MapCameraChangeReason.presentation),
      (map.gestures.pitch.gestureEvents, MapCameraChangeReason.presentation),
    ]) {
      _subscriptions.add(
        stream.listen((event) {
          if (event.gestureState == mb.GestureState.started) _gesture(reason);
        }),
      );
    }
    _subscriptions.add(
      map.gestures.keyboard.gestureEvents.listen((event) {
        if (event.gestureState == mb.GestureState.started) {
          _gesture(MapCameraChangeReason.presentation);
          return;
        }
        final previous = options.controller.viewport;
        final camera = event.cameraState;
        final center = MapboxGeography.latLng(camera.center);
        if (previous?.center != center || previous?.zoom != camera.zoom) {
          _cameraReason = MapCameraChangeReason.exploration;
        }
      }),
    );
    final setup = _mapSetup = _prepareMap(map);
    try {
      await setup;
    } catch (_) {
      _failure();
    }
  }

  Future<void> _prepareMap(mb.MapboxMap map) async {
    await map.setBounds(
      mb.CameraBoundsOptions(minZoom: 3, maxZoom: 19, maxPitch: 60),
    );
    if (mounted) await _ornaments();
  }

  Future<void> _ornaments() async {
    final map = _map;
    if (map == null) return;
    final compassTop = MediaQuery.paddingOf(context).top + 12;
    try {
      await map.logo.updateSettings(
        mb.LogoSettings(
          enabled: true,
          position: mb.OrnamentPosition.BOTTOM_LEFT,
          marginLeft: 12,
          marginBottom: options.ornamentBottom,
        ),
      );
      await map.attribution.updateSettings(
        mb.AttributionSettings(
          enabled: true,
          iconColor: AppColors.brandNavy.toARGB32(),
          position: mb.OrnamentPosition.BOTTOM_RIGHT,
          marginRight: 12,
          marginBottom: options.ornamentBottom,
        ),
      );
      await map.compass.updateSettings(
        mb.CompassSettings(
          enabled: options.preset != MapVisualPreset.discovery,
          position: mb.OrnamentPosition.TOP_RIGHT,
          marginTop: compassTop,
          marginRight: 12,
        ),
      );
      await map.scaleBar.updateSettings(mb.ScaleBarSettings(enabled: false));
    } catch (_) {
      if (mounted) _failure();
    }
  }

  void _gesture([
    MapCameraChangeReason reason = MapCameraChangeReason.exploration,
  ]) {
    _presentationGesture |= reason == MapCameraChangeReason.presentation;
    // A pinch can emit rotate and zoom starts in either order.
    if (_cameraReason != MapCameraChangeReason.exploration) {
      _cameraReason = reason;
    }
    options.onGesture();
    unawaited(options.controller.cancel());
    if (_expanded.isNotEmpty && mounted) setState(() => _expanded = []);
  }

  Future<void> _styleLoaded() async {
    final map = _map;
    if (map == null) return;
    final generation = ++_styleGeneration;
    ++_generation;
    _styled = false;
    _sprites.clear();
    _sourceData = null;
    try {
      await _mapSetup;
      if (!mounted || generation != _styleGeneration) return;
      // Native views may still have no size in onMapCreated. Apply the camera
      // after the first style is loaded, before exposing the initial viewport.
      if (!_cameraReady) await map.setCamera(_initialCamera);
      if (!mounted || generation != _styleGeneration) return;
      await MareaMapboxStyle.configure(map, preset: options.preset);
      if (!mounted || generation != _styleGeneration) return;
      map.removeInteraction('marea-background');
      map.addInteraction(
        mb.TapInteraction.onMap((context) {
          if (!mounted) return;
          if (_expanded.isNotEmpty) setState(() => _expanded = []);
          options.onTap(MapboxGeography.latLng(context.point));
        }),
        interactionID: 'marea-background',
      );
      registerMareaPointInteractions(
        map,
        onTap: (id) => unawaited(_tap(id)),
        onLongTap: (id) => _tooltips[id]?.currentState?.ensureTooltipVisible(),
      );
      _styled = true;
      setState(() {
        _error = null;
        _loading = false;
      });
      if (!_cameraReady) {
        _cameraReady = true;
        options.onReady();
      }
      options.onLoaded?.call();
      _scheduleUpdate();
    } catch (_) {
      if (mounted && generation == _styleGeneration) _failure();
    }
  }

  void _failure() {
    if (!mounted) return;
    const message =
        'No pudimos cargar el mapa. Revisa tu conexión e inténtalo de nuevo.';
    setState(() {
      _error = message;
      _loading = false;
    });
    options.onError?.call(message);
  }

  void _cameraChanged(mb.CameraState camera) {
    _latestCamera = camera;
    ++_generation;
    if (!_moving && mounted) {
      setState(() {
        _moving = true;
        _expanded = [];
      });
    }
    _idle?.cancel();
    _idle = Timer(const Duration(milliseconds: 180), _settled);
  }

  void _settled() {
    if (!mounted) return;
    _idle?.cancel();
    if (!_moving && _cameraReason == null) return;
    var reason = _cameraReason;
    final before = options.controller.viewport;
    final after = _latestCamera;
    if (_presentationGesture &&
        reason == MapCameraChangeReason.exploration &&
        before != null &&
        after != null &&
        !before.hasSignificantMotion(
          MapboxGeography.latLng(after.center),
          after.zoom,
        )) {
      reason = MapCameraChangeReason.presentation;
    }
    _cameraReason = null;
    _presentationGesture = false;
    if (_moving) setState(() => _moving = false);
    if (_cameraReady) {
      if (reason == MapCameraChangeReason.presentation) {
        unawaited(options.controller.observe().catchError((_) => null));
      } else {
        options.onIdle();
      }
    }
    _scheduleUpdate();
  }

  void _scheduleUpdate() {
    _pointUpdate?.cancel();
    _pointUpdate = Timer(
      const Duration(milliseconds: 30),
      () => unawaited(_updatePoints()),
    );
  }

  Future<void> _updatePoints() async {
    final map = _map;
    if (map == null || !_styled || !mounted || _moving) return;
    if (_updating) {
      _updatePending = true;
      return;
    }
    _updating = true;
    final generation = ++_generation, style = _styleGeneration;
    final points = options.points;
    try {
      final pixels = await map.pixelsForCoordinates(
        points.map((p) => MapboxGeography.point(p.position)).toList(),
      );
      if (!mounted || generation != _generation || style != _styleGeneration) {
        return;
      }
      final visible = (Offset.zero & _size).inflate(48);
      final projected = <MapProjectedPoint>[];
      for (var i = 0; i < points.length; i++) {
        final offset = Offset(pixels[i].x, pixels[i].y);
        // Native Mapbox can project offscreen coordinates to (0, 0).
        if (offset == Offset.zero || !visible.contains(offset)) continue;
        projected.add(MapProjectedPoint(points[i], offset));
      }
      final groups = clusterMapPoints(projected);
      for (final group in groups) {
        final point = group.members.length == 1 ? group.anchor.point : null;
        final sprite = point == null
            ? 'marea-cluster'
            : MareaMapboxStyle.spriteId(point);
        if (_sprites.add(sprite)) {
          await MareaMapboxStyle.addSprite(map, sprite, point: point);
          if (!mounted || style != _styleGeneration) return;
        }
      }
      if (!mounted || generation != _generation || style != _styleGeneration) {
        return;
      }
      final sourceData = jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          for (final group in groups)
            {
              'type': 'Feature',
              'geometry': {
                'type': 'Point',
                'coordinates': [
                  group.anchor.point.position.longitude,
                  group.anchor.point.position.latitude,
                ],
              },
              'properties': {
                'entity_id': group.anchor.point.id,
                'sprite': group.members.length == 1
                    ? MareaMapboxStyle.spriteId(group.anchor.point)
                    : 'marea-cluster',
                if (group.members.length > 1) 'count': group.members.length,
              },
            },
        ],
      });
      if (sourceData != _sourceData) {
        await map.setStyleSourceProperty(
          MareaMapboxStyle.source,
          'data',
          sourceData,
        );
        if (!mounted || style != _styleGeneration) return;
        _sourceData = sourceData;
      }
      if (!mounted || generation != _generation) return;
      setState(() {
        _groups = groups;
        final anchors = groups.map((g) => g.anchor.point.id).toSet();
        _tooltips.removeWhere((id, _) => !anchors.contains(id));
        final ids = points.map((p) => p.id).toSet();
        if (_expanded.any((p) => !ids.contains(p.point.id))) _expanded = [];
      });
    } catch (_) {
      if (mounted && generation == _generation) _failure();
    } finally {
      _updating = false;
      if (_updatePending && mounted) {
        _updatePending = false;
        _scheduleUpdate();
      }
    }
  }

  Future<void> _tap(String? id) async {
    final group = _groups.where((g) => g.anchor.point.id == id).firstOrNull;
    if (group == null) return;
    if (group.members.length == 1) {
      group.anchor.point.onTap?.call();
      return;
    }
    options.onClusterTap?.call();
    final camera = await capture();
    if (!mounted) return;
    final coincident = group.members.every(
      (p) => (p.offset - group.anchor.offset).distance < 2,
    );
    if (!coincident && camera.zoom < 19) {
      await move(
        group.anchor.point.position,
        zoom: math.min(19, camera.zoom + 2),
      );
      return;
    }
    final radius = math.max(56.0, group.members.length * 52 / (2 * math.pi));
    final center = group.anchor.offset;
    final bounds =
        options.controller.usableArea ??
        Rect.fromLTWH(
          24,
          24,
          math.max(0, _size.width - 48),
          math.max(0, _size.height - options.ornamentBottom - 48),
        );
    final area = options.controller.unobstructedRegions(bounds).where((area) {
      return radius * 2 + 48 <= math.min(area.width, area.height);
    }).firstOrNull;
    if (area == null) {
      await showMareaBottomSheet<void>(
        context: context,
        builder: (context) => MapOverlay(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .55,
            child: ListView(
              children: [
                for (final member in group.members)
                  ListTile(
                    leading: Icon(member.point.icon),
                    title: Text(member.point.label),
                    onTap: () {
                      Navigator.pop(context);
                      member.point.onTap?.call();
                    },
                  ),
              ],
            ),
          ),
        ),
      );
      return;
    }
    final bounded = Offset(
      center.dx.clamp(area.left + radius + 24, area.right - radius - 24),
      center.dy.clamp(area.top + radius + 24, area.bottom - radius - 24),
    );
    setState(
      () => _expanded = [
        for (var i = 0; i < group.members.length; i++)
          MapProjectedPoint(
            group.members[i].point,
            bounded +
                Offset(
                  math.cos(i * 2 * math.pi / group.members.length) * radius,
                  math.sin(i * 2 * math.pi / group.members.length) * radius,
                ),
          ),
      ],
    );
  }

  @override
  Future<MapViewport> capture() async {
    final map = _map!;
    final camera = await map.getCameraState();
    final bounds = await map.coordinateBoundsForCameraUnwrapped(
      mb.CameraOptions(
        center: camera.center,
        zoom: camera.zoom,
        pitch: camera.pitch,
        bearing: camera.bearing,
        padding: mb.MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
      ),
    );
    return MapViewport(
      center: MapboxGeography.latLng(camera.center),
      zoom: camera.zoom,
      pitch: camera.pitch,
      bearing: camera.bearing,
      bounds: MapboxGeography.bounds(bounds),
    );
  }

  @override
  Future<void> move(LatLng center, {double? zoom}) async {
    final map = _map;
    if (map == null || !mounted) return;
    _cameraReason = MapCameraChangeReason.exploration;
    _presentationGesture = false;
    await _ease(
      map,
      mb.CameraOptions(center: MapboxGeography.point(center), zoom: zoom),
      duration: 260,
    );
  }

  @override
  Future<void> reveal(LatLng point, Rect area) async {
    final map = _map;
    if (map == null || area.isEmpty || !mounted) return;
    final regions = options.controller.unobstructedRegions(area).toList();
    if (regions.isEmpty) return;
    final epoch = ++_cameraEpoch;
    final pixel = await map.pixelForCoordinate(MapboxGeography.point(point));
    final offset = Offset(pixel.x, pixel.y);
    if (!mounted ||
        epoch != _cameraEpoch ||
        regions.any((r) => r.contains(offset))) {
      return;
    }
    final target = regions
        .map(
          (r) => Offset(
            offset.dx.clamp(r.left, r.right),
            offset.dy.clamp(r.top, r.bottom),
          ),
        )
        .reduce(
          (a, b) => (a - offset).distanceSquared <= (b - offset).distanceSquared
              ? a
              : b,
        );
    final camera = await map.getCameraState();
    final center = await map.pixelForCoordinate(camera.center);
    final next = await map.coordinateForPixel(
      mb.ScreenCoordinate(
        x: center.x + offset.dx - target.dx,
        y: center.y + offset.dy - target.dy,
      ),
    );
    if (!mounted || epoch != _cameraEpoch) return;
    _cameraReason = MapCameraChangeReason.presentation;
    await _ease(map, mb.CameraOptions(center: next), duration: 260);
  }

  @override
  Future<void> updateCamera({double? pitch, double? bearing}) async {
    final map = _map;
    if (map == null || !mounted) return;
    _cameraReason = MapCameraChangeReason.presentation;
    await _ease(
      map,
      mb.CameraOptions(pitch: pitch, bearing: bearing),
      duration: 300,
    );
  }

  Future<void> _ease(
    mb.MapboxMap map,
    mb.CameraOptions camera, {
    required int duration,
  }) async {
    final epoch = ++_cameraEpoch;
    _animationEpoch = epoch;
    final milliseconds = MediaQuery.disableAnimationsOf(context) ? 0 : duration;
    try {
      await map.easeTo(camera, mb.MapAnimationOptions(duration: milliseconds));
      // The SDK returns when it accepts the animation, before it settles.
      if (milliseconds > 0) {
        await Future<void>.delayed(Duration(milliseconds: milliseconds + 20));
      }
    } finally {
      if (_animationEpoch == epoch) _animationEpoch = null;
    }
  }

  @override
  Future<void> cancel() async {
    ++_cameraEpoch;
    // Mapbox also animates native gestures. Cancel only moves we initiated.
    if (_animationEpoch == null) return;
    _animationEpoch = null;
    await _map?.cancelCameraAnimation();
  }

  @override
  Future<void> reload() async {
    if (_map == null) return;
    ++_generation;
    _styled = false;
    setState(() {
      _error = null;
      _loading = true;
      _expanded = [];
    });
    try {
      await _map!.loadStyleURI(mb.MapboxStyles.STANDARD);
    } catch (_) {
      _failure();
    }
  }

  @override
  void dispose() {
    ++_generation;
    ++_styleGeneration;
    _idle?.cancel();
    _pointUpdate?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    options.controller.detach(this);
    // MapWidget's platform implementation owns and disposes the native map.
    _map = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      if (size != _size) {
        _size = size;
        _scheduleUpdate();
      }
      return MouseRegion(
        onExit: (_) {
          _hovered = null;
          Tooltip.dismissAllToolTips();
        },
        onHover: (event) {
          if (_moving) return;
          final group = _groups
              .where(
                (g) => (g.anchor.offset - event.localPosition).distance <= 24,
              )
              .firstOrNull;
          final id = group?.anchor.point.id;
          if (id == _hovered) return;
          _hovered = id;
          Tooltip.dismissAllToolTips();
          if (id != null) _tooltips[id]?.currentState?.ensureTooltipVisible();
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: mb.MapWidget(
                gestureRecognizers: options.captureGestures
                    ? {
                        Factory<OneSequenceGestureRecognizer>(
                          EagerGestureRecognizer.new,
                        ),
                      }
                    : null,
                onMapCreated: (map) => unawaited(_created(map)),
                onStyleLoadedListener: (_) => unawaited(_styleLoaded()),
                onCameraChangeListener: (event) =>
                    _cameraChanged(event.cameraState),
                onMapIdleListener: (_) => _settled(),
                onMapLoadErrorListener: (_) => _failure(),
              ),
            ),
            if (!_moving)
              for (final group in _groups)
                Positioned(
                  left: group.anchor.offset.dx - 24,
                  top: group.anchor.offset.dy - 24,
                  width: 48,
                  height: 48,
                  child: Semantics(
                    button: true,
                    selected: group.anchor.point.selected,
                    label: group.members.length == 1
                        ? (group.anchor.point.semanticsLabel ??
                              group.anchor.point.label)
                        : '${group.members.length} misiones agrupadas',
                    onTap: () => unawaited(_tap(group.anchor.point.id)),
                    child: Tooltip(
                      key: _tooltips.putIfAbsent(
                        group.anchor.point.id,
                        () => GlobalKey<TooltipState>(),
                      ),
                      message: group.members.length == 1
                          ? group.anchor.point.label
                          : '${group.members.length} misiones agrupadas',
                      excludeFromSemantics: true,
                      child: kIsWeb
                          ? const IgnorePointer(child: SizedBox.expand())
                          : GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              excludeFromSemantics: true,
                              onTap: () =>
                                  unawaited(_tap(group.anchor.point.id)),
                              child: const IgnorePointer(
                                child: SizedBox.expand(),
                              ),
                            ),
                    ),
                  ),
                ),
            for (final expanded in _expanded)
              Positioned(
                left: expanded.offset.dx - 24,
                top: expanded.offset.dy - 24,
                width: 48,
                height: 48,
                child: MapOverlay(
                  child:
                      expanded.point.expandedBuilder?.call(context) ??
                      IconButton.filled(
                        tooltip: expanded.point.label,
                        onPressed: expanded.point.onTap,
                        icon: Icon(expanded.point.icon),
                      ),
                ),
              ),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Center(
                child: MapOverlay(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          TextButton(
                            onPressed: reload,
                            child: const Text('Reintentar mapa'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
