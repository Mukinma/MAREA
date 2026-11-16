import 'package:marea/features/tours/presentation/business_ar_screen.dart';
import 'package:marea/features/tours/models/tour_models.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:marea/core/maps/map_surface.dart';
import 'package:marea/core/maps/map_overlay.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/map/application/mission_map_controller.dart';
import 'package:marea/features/map/presentation/map_filter_sheet.dart';
import 'package:marea/features/map/presentation/map_search_bar.dart';
import 'package:marea/features/map/presentation/mission_map_canvas.dart';
import 'package:marea/features/map/presentation/mission_map_preview.dart';
import 'package:marea/shared/widgets/marea_surface.dart';
import 'package:marea/features/map/presentation/map_camera_controls.dart';
import 'package:marea/features/map/models/mission_map_models.dart';

class MissionMapScreen extends StatefulWidget {
  const MissionMapScreen({
    required this.session,
    this.locationService = const GeolocatorDeviceLocationService(),
    this.initialQuery = '',
    this.initialCategory,
    this.showTours = false,
    super.key,
  });
  final AppSessionController session;
  final DeviceLocationService locationService;
  final String initialQuery;
  final String? initialCategory;
  final bool showTours;
  @override
  State<MissionMapScreen> createState() => _MissionMapScreenState();
}

class _MissionMapScreenState extends State<MissionMapScreen> {
  late final _state = MissionMapController(
    widget.session.missionMapRepository,
    initialQuery: widget.initialQuery,
    filters: MissionMapFilters(category: widget.initialCategory),
  );
  final _map = MapSurfaceController();
  late final _search = TextEditingController(text: _state.query);
  late final _changes = Listenable.merge([_state, _map]);
  List<TourRecord> _tours = [];
  int _tourGeneration = 0;
  int _cameraGestureGeneration = 0;
  bool _ready = false, _locating = false, _manuallyExplored = false;
  DevicePosition? _position;
  ({DevicePosition fix, int gesture})? _pendingLocation;
  DeviceLocationFailure? _locationFailure;
  bool _initialSearchStarted = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _locate(explicit: false);
    });
  }

  @override
  void dispose() {
    _state.dispose();
    _search.dispose();
    _map.dispose();
    super.dispose();
  }

  Future<bool> _captureViewport({bool observing = false}) async {
    if (!mounted || !_ready) return false;
    try {
      final viewport = await (observing ? _map.observe() : _map.capture());
      if (!mounted || viewport == null || !viewport.bounds.isValid) {
        return false;
      }
      _state.updateViewport(viewport.bounds);
      return true;
    } catch (_) {
      // The surface presents recoverable cartographic errors locally.
      return false;
    }
  }

  Future<void> _queryAtViewport(Future<void> Function() query) async {
    if (await _captureViewport() && mounted) {
      _initialSearchStarted = true;
      await query();
    }
  }

  Future<void> _searchArea() =>
      _queryAtViewport(() => _state.search(force: true));

  Future<void> _loadTours() async {
    final repository = widget.session.tourRepository;
    if (!widget.showTours || !_ready || repository == null) return;
    final generation = ++_tourGeneration;
    try {
      final snapshot = await _map.observe();
      if (!mounted || snapshot == null || generation != _tourGeneration) return;
      final center = snapshot.center;
      final tours = await repository.list(
        latitude: center.latitude,
        longitude: center.longitude,
      );
      if (!mounted || generation != _tourGeneration || !widget.showTours) return;
      final bounds = snapshot.bounds;
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

  List<MapSurfacePoint> get _tourMarkers => !widget.showTours
      ? []
      : [
          for (final t in _tours)
            MapSurfacePoint(
              id: 'tour:${t.id}',
              label: 'Explorar ${t.space['name']}',
              position: LatLng(
                (t.space['latitude'] as num).toDouble(),
                (t.space['longitude'] as num).toDouble(),
              ),
              icon: Icons.panorama_photosphere_outlined,
              clusterable: false,
              onTap: () => context.push('/tours/${t.id}'),
            ),
        ];

  Future<void> _onReady() async {
    _ready = true;
    final pending = _pendingLocation;
    _pendingLocation = null;
    if (pending != null && pending.gesture == _cameraGestureGeneration) {
      await _recenter(pending.fix, pending.gesture);
    }
    if (!_initialSearchStarted) await _onIdle();
  }

  Future<void> _onIdle() async {
    final captured = await _captureViewport(observing: true);
    if (!mounted || !captured || _initialSearchStarted) return;
    // A newer idle capture may supersede onReady's asynchronous snapshot.
    // Whichever obtains the first valid viewport owns the initial search.
    _initialSearchStarted = true;
    await _state.search();
    await _loadTours();
  }

  void _onGesture() {
    ++_cameraGestureGeneration;
    _manuallyExplored = true;
  }

  void _selectMission(String id) {
    FocusScope.of(context).unfocus();
    _state.select(id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final area = _map.usableArea;
      if (!mounted || _state.selected?.id != id || area == null) {
        return;
      }
      final point = _state.selected?.coordinates;
      if (point != null) {
        unawaited(_map.reveal(LatLng(point.latitude, point.longitude), area));
      }
    });
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
      if (gestureGeneration != _cameraGestureGeneration ||
          (!explicit && _manuallyExplored)) {
        return;
      }
      if (!_ready) {
        _pendingLocation = (fix: fix, gesture: gestureGeneration);
        return;
      }
      await _recenter(fix, gestureGeneration);
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

  Future<void> _recenter(DevicePosition fix, int gesture) async {
    await _map.move(LatLng(fix.latitude, fix.longitude), zoom: 15);
    if (!mounted || gesture != _cameraGestureGeneration) return;
    final captured = await _captureViewport();
    if (!captured || !mounted || gesture != _cameraGestureGeneration) return;
    _initialSearchStarted = true;
    await _state.search();
    await _loadTours();
  }

  Future<void> _filters() async {
    final value = await showMapFilterSheet(context, _state.filters);
    if (!mounted || value == null) return;
    await _queryAtViewport(() => _state.applyFilters(value));
  }

  Future<void> _submit(String value) async {
    FocusScope.of(context).unfocus();
    await _queryAtViewport(() => _state.submitQuery(value));
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
      animation: _changes,
      builder: (context, _) {
        final selected = _state.selected;
        final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
        final topInset = MediaQuery.paddingOf(context).top;
        final bottomInset = MediaQuery.paddingOf(context).bottom;
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
        final filterCount =
            (_state.filters.category == null ? 0 : 1) +
            (_state.filters.radiusKm == null ? 0 : 1) +
            (_state.filters.date == MissionMapDate.any ? 0 : 1);
        return Stack(
          children: [
            Positioned.fill(
              child: MissionMapCanvas(
                controller: _map,
                initialCenter: _initialCenter,
                onReady: _onReady,
                onIdle: () => unawaited(_onIdle()),
                onGesture: _onGesture,
                onClusterTap: () => _state.select(null),
                ornamentBottom: bottomInset + 12,
                onMapTap: () {
                  FocusScope.of(context).unfocus();
                  _state.select(null);
                },
                missions: _state.page.missions,
                tourMarkers: _tourMarkers,
                selectedId: selected?.id,
                onMissionTap: _selectMission,
                position: _position,
              ),
            ),
            Positioned.fill(
              child: CustomMultiChildLayout(
                delegate: _MapControlsLayout(
                  topInset: topInset,
                  bottomInset: bottomInset,
                  selected: selected != null,
                  keyboardOpen: keyboardOpen,
                  onUsableArea: (area, controls) {
                    _map.usableArea = area;
                    _map.controlsArea = controls;
                  },
                ),
                children: [
                  LayoutId(
                    id: _MapControl.header,
                    child: MapOverlay(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MapSearchBar(
                              controller: _search,
                              filterCount: filterCount,
                              onSubmitted: _submit,
                              onFilters: _filters,
                            ),
                            const SizedBox(height: 4),
                            if (!keyboardOpen &&
                                !(selected != null && size.maxHeight < 650))
                              MapQuickFilters(
                                filters: _state.filters,
                                onChanged: (value) => _queryAtViewport(
                                  () => _state.applyFilters(value),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  LayoutId(
                    id: _MapControl.controls,
                    child: keyboardOpen
                        ? const SizedBox.shrink()
                        : MapOverlay(
                            child: MapCameraControls(
                              controller: _map,
                              ready: _ready,
                              locating: _locating,
                              compact: size.maxHeight < 650,
                              onLocate: () => _locate(explicit: true),
                            ),
                          ),
                  ),
                  LayoutId(
                    id: _MapControl.panel,
                    child: keyboardOpen
                        ? const SizedBox.shrink()
                        : MapOverlay(
                            child: _buildPanel(context, selected, distance),
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

  Widget _buildPanel(
    BuildContext context,
    Mission? selected,
    double? distance,
  ) {
    final locationFailure = _locationFailure;
    final openSettings =
        locationFailure?.kind == DeviceLocationFailureKind.deniedForever ||
        locationFailure?.kind == DeviceLocationFailureKind.disabled;
    final status = <Widget>[
      if (_state.loading) const LinearProgressIndicator(minHeight: 2),
      if (_state.needsAreaSearch) ...[
        TextButton.icon(
          onPressed: _state.loading ? null : _searchArea,
          icon: const Icon(Icons.search_rounded, size: 18),
          label: const Text('Buscar en esta zona'),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
        if (_state.page.missions.isNotEmpty)
          const Text(
            'Los puntos se mantienen hasta actualizar la búsqueda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
      ],
      if (_state.error case final error?)
        _notice(error, action: 'Reintentar', onAction: _searchArea),
      if (locationFailure != null)
        _notice(
          locationFailure.message,
          action: openSettings ? 'Ajustes' : 'Cerrar',
          onAction: openSettings
              ? _settings
              : () => setState(() => _locationFailure = null),
        ),
    ];
    return MareaSurface(
      color: AppColors.surface,
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shadows: const [
        BoxShadow(
          color: Color(0x100B255E),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
      child: selected == null
          ? SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...status,
                  if (_state.error == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _state.hasLoaded
                              ? _resultText
                              : _state.loading
                              ? 'Cargando misiones…'
                              : 'Descubre misiones en el mapa',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.brandNavy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          : MissionMapPreview(
              key: ValueKey(selected.id),
              mission: selected,
              status: status,
              arAction: widget.session.tourRepository == null
                  ? null
                  : BusinessARAction(
                      ownerId: selected.authorId,
                      repository: widget.session.tourRepository!,
                      onOpen: (target) => context.push(
                        Uri(
                          path: '/tours/${target.tour.id}/business-ar',
                          queryParameters: {
                            'owner': selected.authorId,
                            'point': target.point.id,
                          },
                        ).toString(),
                      ),
                    ),
              repository: widget.session.communityRepository,
              distanceMeters: distance,
              onClose: () => _state.select(null),
              onOpen: () async {
                await context.push('/missions/${selected.id}');
                if (mounted) await _searchArea();
              },
            ),
    );
  }

  String get _resultText {
    final page = _state.page;
    if (page.total == 0) {
      return _state.needsAreaSearch
          ? 'Sin misiones en la última búsqueda'
          : 'No encontramos misiones por aquí todavía.';
    }
    if (page.isTruncated) {
      return 'Mostrando ${page.missions.length} de ${page.total} · Acerca el mapa';
    }
    return '${page.total} ${page.total == 1 ? 'misión' : 'misiones'}${_state.needsAreaSearch ? ' en la última búsqueda' : ' en esta zona'}';
  }

  Widget _notice(
    String message, {
    required String action,
    required VoidCallback onAction,
  }) => Row(
    children: [
      Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
      TextButton(onPressed: onAction, child: Text(action)),
    ],
  );
}

enum _MapControl { header, controls, panel }

class _MapControlsLayout extends MultiChildLayoutDelegate {
  _MapControlsLayout({
    required this.topInset,
    required this.bottomInset,
    required this.selected,
    required this.keyboardOpen,
    required this.onUsableArea,
  });
  final double topInset, bottomInset;
  final bool selected, keyboardOpen;
  final void Function(Rect, Rect?) onUsableArea;
  @override
  void performLayout(Size size) {
    const side = 16.0, gap = 12.0, legalHeight = 32.0;
    final top = topInset + 8;
    final bottom = math.max(top, size.height - bottomInset - legalHeight - 12);
    final width = math.max(0.0, size.width - side * 2);
    final headerWidth = math.min(width, 560.0);
    final header = layoutChild(
      _MapControl.header,
      BoxConstraints(
        minWidth: headerWidth,
        maxWidth: headerWidth,
        maxHeight: keyboardOpen
            ? math.max(0, bottom - top)
            : math.max(0, (bottom - top) * (selected ? .28 : .35)),
      ),
    );
    positionChild(
      _MapControl.header,
      Offset((size.width - header.width) / 2, top),
    );
    final controls = layoutChild(
      _MapControl.controls,
      BoxConstraints.loose(
        Size(width, math.max(0, bottom - top - header.height - gap)),
      ),
    );
    final panelWidth = math.min(width, 520.0);
    final panel = layoutChild(
      _MapControl.panel,
      BoxConstraints(
        minWidth: panelWidth,
        maxWidth: panelWidth,
        maxHeight: math.max(
          0,
          math.min(
            selected ? 320.0 : 220.0,
            bottom - top - header.height - controls.height - gap * 3,
          ),
        ),
      ),
    );
    final panelTop = bottom - panel.height;
    positionChild(
      _MapControl.panel,
      Offset((size.width - panel.width) / 2, panelTop),
    );
    final controlsOffset = Offset(
      size.width - side - controls.width,
      math.max(top + header.height + gap, panelTop - gap - controls.height),
    );
    positionChild(_MapControl.controls, controlsOffset);
    onUsableArea(
      Rect.fromLTRB(
        side + 24,
        top + header.height + gap + 24,
        size.width - side - 24,
        math.max(top + header.height + gap + 24, panelTop - gap - 24),
      ),
      controls.isEmpty ? null : controlsOffset & controls,
    );
  }

  @override
  bool shouldRelayout(_MapControlsLayout old) =>
      topInset != old.topInset ||
      bottomInset != old.bottomInset ||
      selected != old.selected ||
      keyboardOpen != old.keyboardOpen;
}
