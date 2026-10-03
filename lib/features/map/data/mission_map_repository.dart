import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/map/models/mission_map_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class MissionMapRepository {
  Future<MissionMapPage> fetch({
    required MapBounds bounds,
    required MissionMapFilters filters,
    required String query,
    required DateTime now,
  });
}

class SupabaseMissionMapRepository implements MissionMapRepository {
  SupabaseMissionMapRepository(this._client);
  final SupabaseClient _client;
  @override
  Future<MissionMapPage> fetch({
    required MapBounds bounds,
    required MissionMapFilters filters,
    required String query,
    required DateTime now,
  }) async {
    if (!bounds.isValid) {
      throw const AppFailure('La zona seleccionada no es válida.');
    }
    final (from, before) = filters.dateRange(now);
    try {
      final value = await _client.rpc(
        'list_map_missions',
        params: {
          'south': bounds.south,
          'west': bounds.west,
          'north': bounds.north,
          'east': bounds.east,
          'query_text': query.trim(),
          'category_filter': filters.category,
          'starts_from': from?.toUtc().toIso8601String(),
          'starts_before': before?.toUtc().toIso8601String(),
          'center_latitude': bounds.center.latitude,
          'center_longitude': bounds.center.longitude,
          'radius_km': filters.radiusKm,
        },
      );
      return MissionMapPage.fromJson(Map<String, dynamic>.from(value as Map));
    } catch (error) {
      if (error is Error) rethrow;
      if (error is PostgrestException && error.code == 'PGRST202') {
        throw const AppFailure(
          'El mapa necesita una actualización del servicio. Puedes seguir explorando e intentarlo más tarde.',
        );
      }
      throw AppFailureMapper.from(error);
    }
  }
}
