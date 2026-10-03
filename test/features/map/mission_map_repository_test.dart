import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marea/features/map/models/mission_map_models.dart';
import 'package:marea/features/map/data/mission_map_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('geographic repository sends bounds and UTC calendar filters', () async {
    final client = SupabaseClient(
      'https://example.invalid',
      'key',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/rest/v1/rpc/list_map_missions');
        final body = jsonDecode(request.body) as Map;
        expect(body['south'], 19);
        expect(body['north'], 20);
        expect(body['west'], -100);
        expect(body['east'], -99);
        expect(body['center_latitude'], 19.5);
        expect(body['center_longitude'], -99.5);
        expect(body['radius_km'], 3);
        expect(body['query_text'], 'mural');
        expect(body['category_filter'], 'arte');
        expect(
          DateTime.parse(body['starts_from'] as String),
          DateTime(2026, 9, 29).toUtc(),
        );
        expect(
          DateTime.parse(body['starts_before'] as String),
          DateTime(2026, 9, 30).toUtc(),
        );
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'missions': [
                {
                  'id': 'one',
                  'author_id': 'author',
                  'title': 'Mural',
                  'body': 'Colaboración',
                  'category': 'arte',
                  'location': 'Centro',
                  'starts_at': '2100-01-01T00:00:00Z',
                  'capacity': 3,
                  'created_at': '2026-01-01T00:00:00Z',
                  'status': 'open',
                  'location_latitude': 19.5,
                  'location_longitude': -99.5,
                  'location_precision': 'approximate',
                  'accepted_count': 1,
                  'organizer_name': 'Mercado',
                },
              ],
              'total': 400,
            }),
          ),
          200,
          request: request,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(client.dispose);
    final page = await SupabaseMissionMapRepository(client).fetch(
      bounds: const MapBounds(south: 19, west: -100, north: 20, east: -99),
      filters: const MissionMapFilters(
        category: 'arte',
        radiusKm: 3,
        date: MissionMapDate.today,
      ),
      query: ' mural ',
      now: DateTime(2026, 9, 29, 23),
    );
    expect(page.total, 400);
    expect(page.isTruncated, true);
    expect(page.missions.single.coordinates!.isApproximate, true);
    expect(page.missions.single.availableSeats, 2);
  });
}
