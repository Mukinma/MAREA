import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/location/models/location_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class LocationRepository {
  Future<List<LocationPlace>> search(String query);
  Future<LocationPlace?> reverse(PostCoordinates coordinates);
  Future<LocationCity?> resolveContentCity({
    required String contentKind,
    required String contentId,
    required PostCoordinates coordinates,
  });
}

class SupabaseLocationRepository implements LocationRepository {
  SupabaseLocationRepository(this._client);
  final SupabaseClient _client;
  final Map<String, Future<Map<String, dynamic>>> _pending = {};
  final Map<String, Map<String, dynamic>> _resolved = {};

  Future<Map<String, dynamic>> _lookup(String key, Map<String, dynamic> input) {
    final cached = _resolved[key];
    if (cached != null) return Future.value(cached);
    return _pending.putIfAbsent(key, () async {
      try {
        final response = await _client.functions
            .invoke('geocoding', body: input)
            .timeout(const Duration(seconds: 25));
        if (response.status != 200 || response.data is! Map) {
          throw StateError('geocoding_unavailable');
        }
        final value = Map<String, dynamic>.from(response.data as Map);
        _resolved[key] = value;
        return value;
      } finally {
        _pending.remove(key);
      }
    });
  }

  String _pointKey(PostCoordinates point) =>
      '${point.latitude}:${point.longitude}';
  Map<String, dynamic> _pointInput(PostCoordinates point) => {
    'latitude': point.latitude,
    'longitude': point.longitude,
  };
  @override
  Future<List<LocationPlace>> search(String query) async {
    final normalized = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length < 3 || normalized.length > 180) return [];
    final value = await _lookup('search:${normalized.toLowerCase()}', {
      'mode': 'search',
      'query': normalized,
    });
    return (value['places'] as List? ?? [])
        .map(LocationPlace.fromJson)
        .whereType<LocationPlace>()
        .toList();
  }

  @override
  Future<LocationPlace?> reverse(PostCoordinates coordinates) async {
    if (!coordinates.isValid) return null;
    final value = await _lookup('reverse:${_pointKey(coordinates)}', {
      'mode': 'reverse',
      ..._pointInput(coordinates),
    });
    return LocationPlace.fromJson(value['place']);
  }

  @override
  Future<LocationCity?> resolveContentCity({
    required String contentKind,
    required String contentId,
    required PostCoordinates coordinates,
  }) async {
    if (!coordinates.isValid || !{'post', 'mission'}.contains(contentKind)) {
      return null;
    }
    final value = await _lookup(
      'content:$contentKind:$contentId:${_pointKey(coordinates)}',
      {
        'mode': 'content_city',
        'contentKind': contentKind,
        'contentId': contentId,
        ..._pointInput(coordinates),
      },
    );
    return LocationCity.fromJson(value['city']);
  }
}
