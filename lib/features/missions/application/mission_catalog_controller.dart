import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/features/location/data/location_repository.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/map/data/mission_map_repository.dart';
import 'package:marea/features/map/models/mission_map_models.dart';
import 'package:marea/features/profile/models/profile.dart';

enum MissionCatalogOrder { recent, startDate }

class MissionCatalogPage {
  final List<Mission> _items = [];
  int _offset = 0;
  bool _started = false;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  List<Mission> get items => List.unmodifiable(_items);
  bool get waiting => !_started || _loading;
  bool get hasMore => _started && _hasMore;
  String? get error => _error;
}

typedef NearbyMission = ({Mission mission, double meters, bool approximate});

class MissionCatalogController extends ChangeNotifier {
  MissionCatalogController({
    required this.community,
    required this.missionMap,
    required this.location,
    this.geocoding,
    this.savedOnly = false,
    UserType? initialTarget,
  }) : _target = initialTarget;

  final CommunityRepository? community;
  final MissionMapRepository? missionMap;
  final DeviceLocationService location;
  final LocationRepository? geocoding;
  final bool savedOnly;

  static const radii = [1.0, 3.0, 5.0, 10.0];
  static const defaultRadius = 10.0;
  static const _debounce = Duration(milliseconds: 300);
  static const _earthRadiusKm = 6371.0088;
  static const _distance = Haversine();
  static const _nearbyLimit = 8;

  String _query = '';
  String? _category;
  double _radiusKm = defaultRadius;
  UserType? _target;
  MissionCatalogOrder _order = MissionCatalogOrder.recent;
  bool _disposed = false;
  Timer? _timer;
  MissionCatalogPage _catalog = MissionCatalogPage();

  DevicePosition? _position;
  String? _zoneName;
  (double, double)? _zonePoint;
  DeviceLocationFailure? _locationFailure;
  bool _locating = false;
  int _nearGeneration = 0;
  bool _nearStarted = false;
  bool _nearLoading = false;
  String? _nearError;
  List<NearbyMission> _nearby = const [];

  Set<String>? _savedMissions;
  final _saving = <String>{};
  int _savedGeneration = 0;
  int _saveRevision = 0;

  String get query => _query;
  String? get category => _category;
  double get radiusKm => _radiusKm;
  UserType? get target => _target;
  MissionCatalogOrder get order => _order;
  String? get zoneName => _zoneName;
  bool get hasPosition => _position != null;
  bool get showNearby => _query.isEmpty && !savedOnly;
  MissionCatalogPage get catalog => _catalog;
  NearbyMission? distanceTo(Mission mission) {
    final position = _position;
    final pin = mission.coordinates;
    if (position == null || pin == null || !pin.isValid) return null;
    return (
      mission: mission,
      meters: _distanceMeters(
        LatLng(position.latitude, position.longitude),
        pin,
      ),
      approximate: pin.precision == PostLocationPrecision.approximate,
    );
  }

  bool get nearbyWaiting =>
      _locating || (_position != null && (!_nearStarted || _nearLoading));
  DeviceLocationFailure? get locationFailure => _locationFailure;
  String? get nearError => _nearError;
  List<NearbyMission> get nearby => _nearby;

  void start() {
    unawaited(loadCatalog());
    unawaited(reloadSaved());
    if (!savedOnly) unawaited(locate());
  }

  void type(String value, {bool immediate = false}) {
    final query = value.trim();
    if (query == _query) {
      if (immediate && _timer != null) {
        _cancelTimer();
        unawaited(loadCatalog());
      }
      return;
    }

    _cancelTimer();
    _query = query;
    _catalog = MissionCatalogPage();
    _notify();

    if (query.isEmpty || immediate) {
      unawaited(loadCatalog());
      _resumeNearby();
    } else {
      _timer = Timer(_debounce, () {
        _timer = null;
        unawaited(loadCatalog());
      });
    }
  }

  void setOrder(MissionCatalogOrder value) {
    if (savedOnly || value == _order) return;
    _order = value;
    _reloadCatalog();
  }

  void applyFilters({
    required String? category,
    required double radiusKm,
    required UserType? target,
  }) {
    final catalogChanged = category != _category || target != _target;
    if (!catalogChanged && radiusKm == _radiusKm) return;

    _category = category;
    _radiusKm = radiusKm;
    _target = target;
    _resetNearby();
    if (catalogChanged) {
      _reloadCatalog();
    } else {
      _notify();
    }
    _resumeNearby();
  }

  void _reloadCatalog() {
    _cancelTimer();
    _catalog = MissionCatalogPage();
    unawaited(loadCatalog());
  }

  void _resumeNearby() {
    if (showNearby && _position != null && !_locating && !_nearStarted) {
      unawaited(loadNearby());
    }
  }

  void _resetNearby() {
    ++_nearGeneration;
    _nearStarted = false;
    _nearLoading = false;
    _nearError = null;
    _nearby = const [];
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    _cancelTimer();
    _catalog = MissionCatalogPage();
    if (showNearby) _resetNearby();
    await Future.wait([loadCatalog(), reloadSaved(), if (showNearby) locate()]);
  }

  Future<void> loadCatalog() async {
    final page = _catalog;
    if (_disposed || page._loading || !page._hasMore) return;
    final repo = community;
    page._started = true;
    if (repo == null) {
      page._error = 'El catálogo de misiones no está disponible.';
      _notify();
      return;
    }

    final query = _literalMissionQuery(_query);
    final category = _category;
    final target = _target;
    final order = _order;
    page._loading = true;
    page._error = null;
    _notify();
    try {
      final knownIds = page._items.map((mission) => mission.id).toSet();
      final initialCount = page._items.length;
      do {
        final raw = await switch ((savedOnly, order)) {
          (true, _) => repo.savedMissions(
            query: query,
            category: category,
            targetType: target,
            offset: page._offset,
          ),
          (false, MissionCatalogOrder.startDate) => repo.missionCatalogByStart(
            query: query,
            category: category,
            targetType: target,
            offset: page._offset,
          ),
          _ => repo.missions(
            query: query,
            category: category,
            targetType: target,
            scope: 'discover',
            offset: page._offset,
          ),
        };
        if (_disposed || !identical(page, _catalog)) return;
        if (savedOnly && _saving.isEmpty) {
          (_savedMissions ??= {}).addAll(raw.map((mission) => mission.id));
        }
        page._offset += raw.length;
        page._hasMore = raw.length == SupabaseCommunityRepository.pageSize;
        page._items.addAll(
          raw.where((mission) {
            final visible =
                savedOnly ||
                (mission.isOpen && !mission.isExpired && !mission.isFull);
            return visible && knownIds.add(mission.id);
          }),
        );
      } while (page._hasMore && page._items.length == initialCount);
    } catch (_) {
      if (!_disposed && identical(page, _catalog)) {
        page._error = 'No pudimos cargar las misiones.';
      }
    } finally {
      if (!_disposed && identical(page, _catalog)) {
        page._loading = false;
        _notify();
      }
    }
  }

  // list_missions applies LEFT(query_text, 100) before composing its LIKE
  // pattern. Keep each escaped code point within that same server limit.
  static String _literalMissionQuery(String query) {
    final escaped = StringBuffer();
    var remaining = 100;
    for (final rune in query.runes) {
      final character = String.fromCharCode(rune);
      final needsEscape =
          character == '%' || character == '_' || character == r'\';
      remaining -= needsEscape ? 2 : 1;
      if (remaining < 0) break;
      if (needsEscape) escaped.write(r'\');
      escaped.write(character);
    }
    return escaped.toString();
  }

  Future<void> locate({bool explicit = false}) async {
    if (_disposed || _locating) return;
    _locating = true;
    _locationFailure = null;
    _notify();
    try {
      final position = await location.current(
        requestPermission: explicit,
        isCurrent: () => !_disposed,
      );
      if (_disposed) return;
      if (!position.latitude.isFinite ||
          !position.longitude.isFinite ||
          position.latitude.abs() > 90 ||
          position.longitude.abs() > 180) {
        throw const DeviceLocationFailure(
          DeviceLocationFailureKind.unavailable,
        );
      }
      _position = position;
      unawaited(_resolveZone(position));
      _resetNearby();
    } on DeviceLocationFailure catch (error) {
      if (!_disposed) {
        _position = null;
        _zoneName = null;
        _zonePoint = null;
        _resetNearby();
        _locationFailure = error;
      }
    } finally {
      _locating = false;
      _notify();
    }
    if (showNearby && _position != null) await loadNearby();
  }

  Future<void> _resolveZone(DevicePosition position) async {
    final repository = geocoding;
    if (repository == null) return;
    final point = (
      (position.latitude * 100).round() / 100.0,
      (position.longitude * 100).round() / 100.0,
    );
    if (point == _zonePoint) return;
    _zonePoint = point;
    _zoneName = null;
    try {
      final place = await repository.reverse(
        PostCoordinates(
          latitude: point.$1,
          longitude: point.$2,
          precision: PostLocationPrecision.approximate,
        ),
      );
      if (_disposed || _zonePoint != point) return;
      final city = place?.city;
      if (city == null) {
        _zonePoint = null;
        return;
      }
      _zoneName = {
        city.name,
        if (city.region?.trim() case final String region when region.isNotEmpty)
          region,
      }.join(', ');
      _notify();
    } catch (_) {
      if (!_disposed && _zonePoint == point) _zonePoint = null;
    }
  }

  Future<void> loadNearby() async {
    final position = _position;
    if (_disposed || position == null || _nearLoading) return;
    final generation = ++_nearGeneration;
    final radius = _radiusKm;
    final category = _category;
    final target = _target;
    _nearStarted = true;
    _nearLoading = true;
    _nearError = null;
    _notify();
    try {
      final repo = missionMap;
      if (repo == null) {
        _nearError = 'Las misiones cercanas no están disponibles.';
        return;
      }
      final center = LatLng(position.latitude, position.longitude);
      var requestedRadius = radius;
      var lowerRadius = 0.0;
      var upperRadius = radius;
      final known = <String, NearbyMission>{};
      final now = DateTime.now();
      for (var attempt = 0; attempt < 6; attempt++) {
        final bounds = _bounds(center, requestedRadius);
        final result = await repo.fetch(
          bounds: bounds,
          filters: MissionMapFilters(
            category: category,
            // The repository's circle is centered on the bounding box.
            radiusKm: (bounds.center.latitude - center.latitude).abs() < 1e-8
                ? requestedRadius
                : null,
          ),
          query: '',
          now: now,
        );
        if (_disposed || generation != _nearGeneration) return;

        final matches = _rankNearby(
          result.missions.where(
            (mission) =>
                target == null ||
                mission.targetType == null ||
                mission.targetType == target,
          ),
          center,
          requestedRadius,
          now,
        );
        if (!result.isTruncated &&
            (attempt == 0 || matches.length >= _nearbyLimit)) {
          final unique = {for (final item in matches) item.mission.id: item};
          _nearby = List.unmodifiable(unique.values.take(_nearbyLimit));
          return;
        }

        known.addEntries(
          matches.map((item) => MapEntry(item.mission.id, item)),
        );
        final ranked = known.values.toList()..sort(_compareDistance);
        _nearby = List.unmodifiable(ranked.take(_nearbyLimit));

        // The map RPC caps by start date. A smaller, complete circle with
        // enough candidates proves that none of the omitted rows are closer.
        if (result.isTruncated) {
          upperRadius = requestedRadius;
        } else {
          lowerRadius = requestedRadius;
        }
        if (upperRadius - lowerRadius <= .001) break;
        final farthestKnown = _nearby.length == _nearbyLimit
            ? (_nearby.last.meters + 1) / 1000
            : upperRadius;
        requestedRadius =
            farthestKnown > lowerRadius && farthestKnown < upperRadius
            ? farthestKnown
            : (lowerRadius + upperRadius) / 2;
      }
    } catch (_) {
      if (!_disposed && generation == _nearGeneration) {
        _nearError = 'No pudimos cargar las misiones cercanas.';
      }
    } finally {
      if (!_disposed && generation == _nearGeneration) {
        _nearLoading = false;
        _notify();
      }
    }
  }

  static double _distanceMeters(LatLng center, PostCoordinates pin) =>
      _distance.distance(center, LatLng(pin.latitude, pin.longitude)) *
      (_earthRadiusKm * 1000 / equatorRadius);

  static List<NearbyMission> _rankNearby(
    Iterable<Mission> missions,
    LatLng center,
    double radiusKm,
    DateTime now,
  ) {
    final withinRadius = <NearbyMission>[];
    for (final mission in missions) {
      final pin = mission.coordinates;
      if (pin == null ||
          !pin.isValid ||
          !mission.isOpen ||
          !mission.startsAt.isAfter(now) ||
          mission.isFull) {
        continue;
      }
      final meters = _distanceMeters(center, pin);
      if (meters <= radiusKm * 1000) {
        withinRadius.add((
          mission: mission,
          meters: meters,
          approximate: pin.isApproximate,
        ));
      }
    }
    return withinRadius..sort(_compareDistance);
  }

  static int _compareDistance(NearbyMission a, NearbyMission b) {
    final distance = a.meters.compareTo(b.meters);
    return distance != 0 ? distance : a.mission.id.compareTo(b.mission.id);
  }

  static MapBounds _bounds(LatLng center, double radiusKm) {
    const degrees = 180 / math.pi;
    final angle = radiusKm / _earthRadiusKm;
    final latitudeDelta = angle * degrees;
    final south = math.max(-90.0, center.latitude - latitudeDelta);
    final north = math.min(90.0, center.latitude + latitudeDelta);
    if (south == -90 || north == 90) {
      return MapBounds(south: south, west: -180, north: north, east: 180);
    }
    final longitudeDelta =
        math.asin(math.sin(angle) / math.cos(center.latitude / degrees)) *
        degrees;
    return MapBounds(
      south: south,
      west: MapBounds.normalizeLongitude(center.longitude - longitudeDelta),
      north: north,
      east: MapBounds.normalizeLongitude(center.longitude + longitudeDelta),
    );
  }

  Future<bool> openLocationSettings() => location.openSettings(
    locationDisabled:
        _locationFailure?.kind == DeviceLocationFailureKind.disabled,
  );

  Future<void> refreshMission(String id) async {
    final repo = community;
    final page = _catalog;
    final nearbyGeneration = _nearGeneration;
    if (_disposed || repo == null) return;
    try {
      final mission = await repo.mission(id);
      if (_disposed || !identical(page, _catalog)) return;
      final index = page._items.indexWhere((item) => item.id == id);
      final available =
          mission != null &&
          mission.isOpen &&
          !mission.isExpired &&
          !mission.isFull;
      if (index != -1) {
        if (mission != null && (available || savedOnly)) {
          page._items[index] = mission;
        } else {
          page._items.removeAt(index);
        }
      }
      if (nearbyGeneration == _nearGeneration &&
          _nearby.any((item) => item.mission.id == id)) {
        final position = _position;
        if (position != null) {
          final center = LatLng(position.latitude, position.longitude);
          _nearby = List.unmodifiable(
            _rankNearby(
              [
                for (final item in _nearby)
                  if (item.mission.id != id) item.mission,
                if (mission != null &&
                    (_category == null || mission.category == _category) &&
                    (_target == null ||
                        mission.targetType == null ||
                        mission.targetType == _target))
                  mission,
              ],
              center,
              _radiusKm,
              DateTime.now(),
            ),
          );
        }
      }
      _notify();
      if (page.hasMore &&
          !page.waiting &&
          page.error == null &&
          page._items.isEmpty) {
        unawaited(loadCatalog());
      }
    } catch (_) {
      // Leave the last loaded card in place if the detail refresh fails.
    }
  }

  Future<void> reloadSaved() async {
    final repo = community;
    if (_disposed || repo == null) return;
    final generation = ++_savedGeneration;
    final revision = _saveRevision;
    try {
      final ids = await repo.savedMissionIds();
      if (_disposed ||
          generation != _savedGeneration ||
          revision != _saveRevision ||
          _saving.isNotEmpty) {
        return;
      }
      final changed = _savedMissions != null && !setEquals(ids, _savedMissions);
      _savedMissions = ids.toSet();
      if (changed && savedOnly) {
        _reloadCatalog();
      } else {
        _notify();
      }
    } catch (_) {
      // Keep the visible catalog and the last known bookmark state.
    }
  }

  bool get canSave => _savedMissions != null;

  bool isSaved(String id) => _savedMissions?.contains(id) ?? false;

  bool isSaving(String id) => _saving.contains(id);

  Future<String?> toggleSaved(String id) async {
    final repo = community;
    final ids = _savedMissions;
    if (_disposed || repo == null || ids == null || !_saving.add(id)) {
      return null;
    }
    ++_saveRevision;
    final next = !ids.remove(id);
    if (next) ids.add(id);
    _notify();
    try {
      await repo.setMissionSaved(id, next);
      if (!_disposed && savedOnly) _reloadCatalog();
    } catch (_) {
      if (next) {
        ids.remove(id);
      } else {
        ids.add(id);
      }
      return 'No pudimos actualizar el guardado. Inténtalo de nuevo.';
    } finally {
      _saving.remove(id);
      _notify();
    }
    return null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimer();
    super.dispose();
  }
}
