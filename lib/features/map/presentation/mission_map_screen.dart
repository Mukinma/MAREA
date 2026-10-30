import 'package:marea/features/tours/models/tour_models.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:marea/core/config/map_tile_configuration.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/map/application/mission_map_controller.dart';
import 'package:marea/features/map/models/mission_map_models.dart';
import 'package:marea/features/map/presentation/map_filter_sheet.dart';
import 'package:marea/features/map/presentation/map_search_bar.dart';
import 'package:marea/features/map/presentation/mission_map_canvas.dart';
import 'package:marea/features/map/presentation/mission_map_preview.dart';
import 'package:marea/shared/widgets/marea_surface.dart';
import 'package:url_launcher/url_launcher.dart';

class MissionMapScreen extends StatefulWidget {
  const MissionMapScreen({
    required this.session,
    this.locationService = const GeolocatorDeviceLocationService(),
    this.tiles = const MapTileConfiguration(),
    super.key,
  });
  final AppSessionController session;
  final DeviceLocationService locationService;
  final MapTileConfiguration tiles;
  @override
  State<MissionMapScreen> createState() => _MissionMapScreenState();
}

class _MissionMapScreenState extends State<MissionMapScreen>
    with SingleTickerProviderStateMixin {
  late final _state = MissionMapController(widget.session.missionMapRepository);
  final _map = MapController();
  final _search = TextEditingController();
  late final _cameraAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  List<TourRecord> _tours = [];
  bool _showTours = false;
  int _tourGeneration = 0;
  int _tileRevision = 0;
  int _cameraGestureGeneration = 0;
  bool _tileError = false, _tileErrorScheduled = false;
  Timer? _idle;
  bool _ready = false, _locating = false, _manuallyExplored = false;
  DevicePosition? _position;
  DeviceLocationFailure? _locationFailure;
  LatLng? _animationFrom, _animationTo;
  double _zoomFrom = 15;

  LatLng get _initialCenter {
    final p = widget.session.profile;
    final latitude = p?.locationLatitude, longitude = p?.locationLongitude;
    if (latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180) {
      return LatLng(latitude, longitude);
    }
    return const LatLng(19.4326, -99.1332);
  }

  @override
  void initState() {
    super.initState();
    _cameraAnimation.addListener(_animateFrame);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _locate(explicit: false);
    });
  }

  @override
  void dispose() {
    _idle?.cancel();
    _cameraAnimation.dispose();
    _state.dispose();
    _search.dispose();
    _map.dispose();
    super.dispose();
  }

  void _animateFrame() {
    if (!_ready || !mounted || _animationFrom == null || _animationTo == null) {
      return;
    }
    final t = Curves.easeInOut.transform(_cameraAnimation.value);
    final from = _animationFrom!, to = _animationTo!;
    final delta = MapBounds.normalizeLongitude(to.longitude - from.longitude);
    _map.move(
      LatLng(
        from.latitude + (to.latitude - from.latitude) * t,
        MapBounds.normalizeLongitude(from.longitude + delta * t),
      ),
      _zoomFrom + (15 - _zoomFrom) * t,
    );
  }

  MapBounds _bounds() {
    final b = _map.camera.visibleBounds;
    final wide = b.east - b.west >= 360;
    return MapBounds(
      south: b.south.clamp(-90, 90),
      north: b.north.clamp(-90, 90),
      west: wide ? -180 : MapBounds.normalizeLongitude(b.west),
      east: wide ? 180 : MapBounds.normalizeLongitude(b.east),
    );
  }

  void _captureViewport() {
    if (mounted && _ready) _state.updateViewport(_bounds());
  }

  Future<void> _loadTours() async {
    if (!_showTours || !_ready || widget.session.tourRepository == null) return;
    final generation = ++_tourGeneration;
    final center = _map.camera.center;
    try {
      final tours = await widget.session.tourRepository!.list(
        latitude: center.latitude,
        longitude: center.longitude,
      );
      if (!mounted || generation != _tourGeneration || !_showTours) return;
      final bounds = _bounds();
      setState(
        () => _tours = tours.where((t) {
          final lat = t.space['latitude'], lng = t.space['longitude'];
          return lat is num &&
              lng is num &&
              lat >= bounds.south &&
              lat <= bounds.north &&
              (bounds.west <= bounds.east
                  ? lng >= bounds.west && lng <= bounds.east
                  : lng >= bounds.west || lng <= bounds.east);
        }).toList(),
      );
    } catch (e) {
      if (mounted && generation == _tourGeneration) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pudimos cargar los recorridos de esta zona.'),
          ),
        );
      }
    }
  }

  List<Marker> get _tourMarkers => !_showTours
      ? []
      : [
          for (final t in _tours)
            Marker(
              width: 48,
              height: 48,
              point: LatLng(
                (t.space['latitude'] as num).toDouble(),
                (t.space['longitude'] as num).toDouble(),
              ),
              child: IconButton.filled(
                tooltip: 'Explorar ${t.space['name']}',
                icon: const Icon(Icons.panorama_photosphere_outlined),
                onPressed: () => context.push('/tours/${t.id}'),
              ),
            ),
        ];
  void _onReady() {
    _ready = true;
    _captureViewport();
    unawaited(_state.search());
    unawaited(_loadTours());
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      _cameraGestureGeneration++;
      _manuallyExplored = true;
      _cameraAnimation.stop();
    }
    _idle?.cancel();
    _idle = Timer(const Duration(milliseconds: 180), _captureViewport);
  }

  Future<void> _locate({required bool explicit}) async {
    if (_locating) return;
    final gestureGeneration = _cameraGestureGeneration;
    setState(() {
      _locating = true;
      _locationFailure = null;
    });
    try {
      final fix = await widget.locationService.current(
        requestPermission: explicit,
        isCurrent: () => mounted,
      );
      if (!mounted) return;
      setState(() => _position = fix);
      if (!_ready ||
          gestureGeneration != _cameraGestureGeneration ||
          (!explicit && _manuallyExplored)) {
        return;
      }
      _animationFrom = _map.camera.center;
      _animationTo = LatLng(fix.latitude, fix.longitude);
      _zoomFrom = _map.camera.zoom;
      await _cameraAnimation.forward(from: 0).orCancel;
      if (!mounted) return;
      _captureViewport();
      await _state.search();
      await _loadTours();
    } on TickerCanceled {
      // A manual gesture owns the camera immediately.
    } on DeviceLocationFailure catch (failure) {
      if (mounted &&
          explicit &&
          failure.kind != DeviceLocationFailureKind.cancelled) {
        setState(() => _locationFailure = failure);
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onTileError() {
    if (!mounted || _tileError || _tileErrorScheduled) return;
    _tileErrorScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tileErrorScheduled = false;
      if (mounted) setState(() => _tileError = true);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  Future<void> _filters() async {
    final value = await showMapFilterSheet(context, _state.filters);
    if (!mounted || value == null) return;
    _captureViewport();
    await _state.applyFilters(value);
  }

  void _submit(String value) {
    FocusScope.of(context).unfocus();
    _captureViewport();
    unawaited(_state.submitQuery(value));
  }

  Future<void> _settings() async {
    final opened = await widget.locationService.openSettings(
      locationDisabled:
          _locationFailure?.kind == DeviceLocationFailureKind.disabled,
    );
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Puedes cambiar el permiso en los ajustes del navegador o del dispositivo.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) => AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final selected = _state.selected;
        // Scaffold.extendBody publishes the actual dock + safe area height.
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        final previewHeight = math.min(size.maxHeight * .48, 300.0);
        double? distance;
        if (_position != null && selected?.coordinates != null) {
          distance = const Distance().as(
            LengthUnit.Meter,
            LatLng(_position!.latitude, _position!.longitude),
            LatLng(
              selected!.coordinates!.latitude,
              selected.coordinates!.longitude,
            ),
          );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: MissionMapCanvas(
                controller: _map,
                initialCenter: _initialCenter,
                onReady: _onReady,
                onPositionChanged: _onPositionChanged,
                onMapTap: () {
                  FocusScope.of(context).unfocus();
                  _state.select(null);
                },
                missions: _state.page.missions,
                tourMarkers: _tourMarkers,
                selectedId: selected?.id,
                onMissionTap: (id) {
                  FocusScope.of(context).unfocus();
                  _state.select(id);
                },
                position: _position,
                tiles: widget.tiles,
                onClusterTap: () => _state.select(null),
                tileRevision: _tileRevision,
                onTileError: _onTileError,
              ),
            ),
            Positioned.fill(
              child: CustomMultiChildLayout(
                delegate: _MapControlsLayout(
                  bottomInset: bottomInset,
                  desiredPreviewHeight: previewHeight,
                  selected: selected != null,
                ),
                children: [
                  LayoutId(
                    id: _MapControl.header,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MapSearchBar(
                            controller: _search,
                            filtersActive: _state.filters.isActive,
                            onSubmitted: _submit,
                            onFilters: _filters,
                          ),
                          if (widget.session.tourRepository != null)
                            Wrap(
                              spacing: 8,
                              children: [
                                FilterChip(
                                  label: const Text('Locales 360°'),
                                  selected: _showTours,
                                  onSelected: (show) {
                                    setState(() => _showTours = show);
                                    _tourGeneration++;
                                    if (show) _loadTours();
                                  },
                                ),
                                TextButton(
                                  onPressed: () =>
                                      context.push('/tours/nearby'),
                                  child: const Text('Descubrir cerca'),
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          MapQuickFilters(
                            filters: _state.filters,
                            onChanged: (value) {
                              _captureViewport();
                              unawaited(_state.applyFilters(value));
                            },
                          ),
                          if (_state.loading)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                          if (_state.needsAreaSearch)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: FilledButton.icon(
                                onPressed: _state.loading
                                    ? null
                                    : () {
                                        _captureViewport();
                                        _state.search(force: true);
                                      },
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                ),
                                label: const Text('Buscar en esta zona'),
                              ),
                            ),
                          if (_tileError)
                            _notice(
                              'No pudimos cargar el mapa base. Puedes seguir usando los filtros.',
                              action: 'Reintentar',
                              onAction: () => setState(() {
                                _tileError = false;
                                ++_tileRevision;
                              }),
                            ),
                          if (_state.error != null)
                            _notice(
                              _state.error!,
                              action: 'Reintentar',
                              onAction: () => _state.search(force: true),
                            ),
                          if (_locationFailure != null)
                            _notice(
                              _locationFailure!.message,
                              action:
                                  _locationFailure!.kind ==
                                          DeviceLocationFailureKind
                                              .deniedForever ||
                                      _locationFailure!.kind ==
                                          DeviceLocationFailureKind.disabled
                                  ? 'Ajustes'
                                  : 'Cerrar',
                              onAction: () {
                                if (_locationFailure!.kind ==
                                        DeviceLocationFailureKind
                                            .deniedForever ||
                                    _locationFailure!.kind ==
                                        DeviceLocationFailureKind.disabled) {
                                  _settings();
                                } else {
                                  setState(() => _locationFailure = null);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  LayoutId(
                    id: _MapControl.location,
                    child: MareaSurface(
                      color: AppColors.surface,
                      radius: 24,
                      child: IconButton(
                        tooltip: _locating
                            ? 'Buscando ubicación…'
                            : 'Centrar en mi ubicación',
                        onPressed: _locating
                            ? null
                            : () => _locate(explicit: true),
                        icon: const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.actionBlue,
                        ),
                      ),
                    ),
                  ),
                  if (selected != null)
                    LayoutId(
                      id: _MapControl.preview,
                      child: SingleChildScrollView(
                        child: MissionMapPreview(
                          key: ValueKey(selected.id),
                          mission: selected,
                          repository: widget.session.communityRepository,
                          distanceMeters: distance,
                          onClose: () => _state.select(null),
                          onOpen: () async {
                            await context.push('/missions/${selected.id}');
                            if (mounted) await _state.search(force: true);
                          },
                        ),
                      ),
                    ),
                  LayoutId(
                    id: _MapControl.footer,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_state.hasLoaded && !_state.loading) ...[
                            _resultCount(),
                            const SizedBox(height: 8),
                          ],
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Material(
                              color: AppColors.surface.withValues(alpha: .95),
                              borderRadius: BorderRadius.circular(6),
                              child: InkWell(
                                onTap: () => launchUrl(
                                  Uri.parse(widget.tiles.attributionUrl),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    widget.tiles.attribution,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _notice(
    String message, {
    required String action,
    required VoidCallback onAction,
  }) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: MareaSurface(
      color: AppColors.surface,
      radius: 18,
      padding: const EdgeInsets.only(left: 12, right: 4),
      child: Row(
        children: [
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
          TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    ),
  );
  Widget _resultCount() {
    final page = _state.page;
    final text = _state.needsAreaSearch
        ? 'Resultados de la zona anterior'
        : page.total == 0
        ? 'No encontramos misiones por aquí todavía.'
        : page.isTruncated
        ? 'Mostrando ${page.missions.length} de ${page.total} · Acerca el mapa'
        : '${page.total} ${page.total == 1 ? 'misión' : 'misiones'} en esta zona';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandNavy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

enum _MapControl { header, location, preview, footer }

/// Fits overlays between the search tools and the actual responsive dock.
/// Scrollable header/preview/footer retain access when text or insets grow.
class _MapControlsLayout extends MultiChildLayoutDelegate {
  _MapControlsLayout({
    required this.bottomInset,
    required this.desiredPreviewHeight,
    required this.selected,
  });
  final double bottomInset, desiredPreviewHeight;
  final bool selected;

  @override
  void performLayout(Size size) {
    const side = 16.0, gap = 12.0, top = 16.0;
    final width = math.max(0.0, size.width - side * 2);
    final bottom = math.max(top, size.height - bottomInset - 12);
    final location = layoutChild(
      _MapControl.location,
      BoxConstraints.loose(Size(width, 48)),
    );
    // Reserve usable scrolling windows for search and the preview action before
    // allocating space to the informational footer at large text scales.
    const minimumHeaderHeight = 48.0, minimumPreviewHeight = 120.0;
    final footer = layoutChild(
      _MapControl.footer,
      BoxConstraints(
        maxWidth: width,
        maxHeight: math.max(
          0,
          bottom -
              top -
              location.height -
              minimumHeaderHeight -
              (selected ? minimumPreviewHeight + gap * 3 : gap * 2),
        ),
      ),
    );
    final footerTop = bottom - footer.height;
    positionChild(_MapControl.footer, Offset(side, footerTop));
    final headerWidth = math.min(width, 560.0);
    final header = layoutChild(
      _MapControl.header,
      BoxConstraints(
        minWidth: headerWidth,
        maxWidth: headerWidth,
        maxHeight: math.max(
          0,
          footerTop -
              top -
              location.height -
              gap * 2 -
              (selected ? minimumPreviewHeight + gap : 0),
        ),
      ),
    );
    positionChild(
      _MapControl.header,
      Offset((size.width - header.width) / 2, top),
    );
    var locationBottom = footerTop - gap;
    if (selected) {
      final available = math.max(
        0.0,
        footerTop - gap - (top + header.height + gap) - location.height - gap,
      );
      final previewWidth = math.min(width, 520.0);
      final preview = layoutChild(
        _MapControl.preview,
        BoxConstraints(
          minWidth: previewWidth,
          maxWidth: previewWidth,
          maxHeight: math.min(desiredPreviewHeight, available),
        ),
      );
      final previewTop = footerTop - gap - preview.height;
      positionChild(
        _MapControl.preview,
        Offset((size.width - preview.width) / 2, previewTop),
      );
      locationBottom = previewTop - gap;
    }
    positionChild(
      _MapControl.location,
      Offset(
        size.width - side - location.width,
        locationBottom - location.height,
      ),
    );
  }

  @override
  bool shouldRelayout(_MapControlsLayout oldDelegate) =>
      bottomInset != oldDelegate.bottomInset ||
      desiredPreviewHeight != oldDelegate.desiredPreviewHeight ||
      selected != oldDelegate.selected;
}
