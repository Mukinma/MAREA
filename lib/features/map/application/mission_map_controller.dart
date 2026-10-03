import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/map/data/mission_map_repository.dart';
import 'package:marea/features/map/models/mission_map_models.dart';

class MissionMapController extends ChangeNotifier {
  MissionMapController(this.repository);
  final MissionMapRepository? repository;
  MissionMapFilters filters = const MissionMapFilters();
  MissionMapPage page = const MissionMapPage(missions: [], total: 0);
  MapBounds? viewport, loadedBounds;
  String query = '';
  String? error, _selectedId, _loadedKey, _activeKey;
  bool loading = false, _disposed = false;
  int _generation = 0;
  Future<void>? _activeRequest;

  Mission? get selected =>
      page.missions.where((m) => m.id == _selectedId).firstOrNull;
  bool get needsAreaSearch =>
      loadedBounds != null &&
      viewport != null &&
      loadedBounds!.changedSignificantly(viewport!);
  bool get hasLoaded => loadedBounds != null;

  void updateViewport(MapBounds bounds, {bool notify = true}) {
    if (_disposed || !bounds.isValid) return;
    final before = needsAreaSearch;
    viewport = bounds;
    if (notify && before != needsAreaSearch) notifyListeners();
  }

  void select(String? id) {
    if (_disposed || _selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  Future<void> applyFilters(MissionMapFilters value) {
    filters = value;
    return search();
  }

  Future<void> submitQuery(String value) {
    query = value.trim();
    return search();
  }

  Future<void> search({bool force = false}) {
    final bounds = viewport;
    if (_disposed || bounds == null) return Future.value();
    final now = DateTime.now();
    final (from, before) = filters.dateRange(now);
    final key = jsonEncode([
      bounds.south,
      bounds.west,
      bounds.north,
      bounds.east,
      query,
      filters.category,
      filters.radiusKm,
      from?.toIso8601String(),
      before?.toIso8601String(),
    ]);
    if (key == _activeKey) return _activeRequest ?? Future.value();
    if (!force && key == _loadedKey && error == null) {
      // Switching back to the loaded filters must also cancel a different request.
      ++_generation;
      _activeKey = null;
      _activeRequest = null;
      loading = false;
      notifyListeners();
      return Future.value();
    }
    final generation = ++_generation;
    _activeKey = key;
    loading = true;
    error = null;
    notifyListeners();
    return _activeRequest = _load(bounds, filters, query, now, key, generation);
  }

  Future<void> _load(
    MapBounds bounds,
    MissionMapFilters requestedFilters,
    String requestedQuery,
    DateTime now,
    String key,
    int generation,
  ) async {
    try {
      final repo = repository;
      if (repo == null) {
        throw const AppFailure(
          'El servicio de misiones del mapa no está configurado.',
        );
      }
      final result = await repo.fetch(
        bounds: bounds,
        filters: requestedFilters,
        query: requestedQuery,
        now: now,
      );
      if (_disposed || generation != _generation) return;
      page = result;
      loadedBounds = bounds;
      _loadedKey = key;
      if (selected == null) _selectedId = null;
    } catch (failure) {
      if (_disposed || generation != _generation) return;
      error = failure is AppFailure
          ? failure.message
          : 'No pudimos actualizar las misiones. Los últimos resultados siguen visibles.';
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        _activeKey = null;
        _activeRequest = null;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    super.dispose();
  }
}
