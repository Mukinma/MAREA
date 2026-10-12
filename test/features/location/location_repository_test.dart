import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/location/data/location_repository.dart';

const point = PostCoordinates(
  latitude: 19.5,
  longitude: -99.2,
  precision: PostLocationPrecision.exact,
);
http.Response jsonResponse(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json'},
);
SupabaseClient client(http.Client httpClient) => SupabaseClient(
  'https://test.supabase.co',
  'anon',
  httpClient: httpClient,
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);
void main() {
  test(
    'simultaneous city lookups share one request and successful unknown stays resolved',
    () async {
      var calls = 0;
      final received = Completer<void>();
      final response = Completer<http.Response>();
      final api = client(
        MockClient((request) async {
          calls++;
          expect(jsonDecode(request.body), {
            'mode': 'content_city',
            'contentKind': 'post',
            'contentId': 'p',
            'latitude': 19.5,
            'longitude': -99.2,
          });
          received.complete();
          return response.future;
        }),
      );
      addTearDown(api.dispose);
      final repo = SupabaseLocationRepository(api);
      final first = repo.resolveContentCity(
        contentKind: 'post',
        contentId: 'p',
        coordinates: point,
      );
      final second = repo.resolveContentCity(
        contentKind: 'post',
        contentId: 'p',
        coordinates: point,
      );
      await received.future;
      response.complete(jsonResponse({'city': null}));
      expect(await first, isNull);
      expect(await second, isNull);
      expect(
        await repo.resolveContentCity(
          contentKind: 'post',
          contentId: 'p',
          coordinates: point,
        ),
        isNull,
      );
      expect(calls, 1);
    },
  );
  test(
    'offline city failures are retried, and a changed point is a different lookup',
    () async {
      var calls = 0;
      final api = client(
        MockClient((request) async {
          calls++;
          if (calls == 1) return jsonResponse({'error': 'offline'}, 503);
          return jsonResponse({
            'city': {'name': calls == 2 ? 'Original' : 'Moved'},
          });
        }),
      );
      addTearDown(api.dispose);
      final repo = SupabaseLocationRepository(api);
      await expectLater(
        repo.resolveContentCity(
          contentKind: 'mission',
          contentId: 'm',
          coordinates: point,
        ),
        throwsA(anything),
      );
      expect(
        (await repo.resolveContentCity(
          contentKind: 'mission',
          contentId: 'm',
          coordinates: point,
        ))?.name,
        'Original',
      );
      expect(
        (await repo.resolveContentCity(
          contentKind: 'mission',
          contentId: 'm',
          coordinates: const PostCoordinates(
            latitude: 20,
            longitude: -100,
            precision: PostLocationPrecision.exact,
          ),
        ))?.name,
        'Moved',
      );
      expect(calls, 3);
    },
  );
  test(
    'search preserves address and structured city while filtering invalid points',
    () async {
      final api = client(
        MockClient(
          (request) async => jsonResponse({
            'places': [
              {
                'label': 'Street, Puebla',
                'latitude': 19,
                'longitude': -98,
                'city': {'name': 'Puebla'},
              },
              {'label': 'Invalid', 'latitude': 91, 'longitude': 0},
            ],
          }),
        ),
      );
      addTearDown(api.dispose);
      final repo = SupabaseLocationRepository(api);
      final results = await repo.search('Puebla');
      expect(results.length, 1);
      expect(results.single.label, 'Street, Puebla');
      expect(results.single.city?.name, 'Puebla');
    },
  );
  test(
    'every distinct stored content point invalidates a previous city lookup',
    () async {
      var calls = 0;
      final api = client(
        MockClient((request) async {
          calls++;
          return jsonResponse({
            'city': {'name': calls == 1 ? 'Original' : 'Moved'},
          });
        }),
      );
      addTearDown(api.dispose);
      final repo = SupabaseLocationRepository(api);
      expect(
        (await repo.resolveContentCity(
          contentKind: 'post',
          contentId: 'p',
          coordinates: point,
        ))?.name,
        'Original',
      );
      expect(
        (await repo.resolveContentCity(
          contentKind: 'post',
          contentId: 'p',
          coordinates: const PostCoordinates(
            latitude: 19.5000001,
            longitude: -99.2,
            precision: PostLocationPrecision.exact,
          ),
        ))?.name,
        'Moved',
      );
    },
  );
}
