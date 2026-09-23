import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  Map<String, dynamic> missionRow() => {
    'id': 'mission',
    'author_id': 'author',
    'title': 'Misión de arte',
    'body': 'Descripción',
    'category': 'arte',
    'location': 'Centro',
    'starts_at': '2100-01-01T00:00:00Z',
    'capacity': 3,
    'status': 'open',
    'created_at': '2026-01-01T00:00:00Z',
  };

  MissionInput input({DateTime? start}) => MissionInput(
    title: 'Misión de arte',
    body: 'Descripción',
    category: 'arte',
    location: 'Centro',
    startsAt: start ?? DateTime.utc(2100),
    capacity: 3,
    requirements: ' Llevar material ',
    conditions: ' Participación gratuita ',
    imagePath: 'author/image.png',
    coordinates: const PostCoordinates(
      latitude: 19.4,
      longitude: -99.1,
      precision: PostLocationPrecision.approximate,
    ),
  );

  SupabaseCommunityRepository repository(
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      httpClient: MockClient((request) async {
        final response = await handler(request);
        return http.Response.bytes(
          utf8.encode(response.body),
          response.statusCode,
          request: request,
          headers: {
            ...response.headers,
            'content-type': 'application/json; charset=utf-8',
          },
        );
      }),
    );
    addTearDown(client.dispose);
    return SupabaseCommunityRepository(client);
  }

  test('mission listing sends filters and parses server aggregates', () async {
    final repo = repository((request) async {
      expect(request.url.path, '/rest/v1/rpc/list_missions');
      expect(jsonDecode(request.body), {
        'author_filter': 'author',
        'query_text': 'arte',
        'category_filter': 'arte',
        'target_filter': UserType.creator.databaseValue,
        'scope_filter': 'available',
        'page_offset': 30,
      });
      return http.Response(
        jsonEncode([
          {
            ...missionRow(),
            'accepted_count': 2,
            'pending_count': null,
            'organizer_name': 'Ana',
            'organizer_username': 'ana',
          },
        ]),
        200,
      );
    });
    final rows = await repo.missions(
      authorId: 'author',
      query: ' arte ',
      category: 'arte',
      targetType: UserType.creator,
      scope: 'available',
      offset: 30,
    );
    expect(rows.single.acceptedCount, 2);
    expect(rows.single.pendingCount, 0);
    expect(rows.single.availableSeats, 1);
    expect(rows.single.organizerName, 'Ana');
  });

  test(
    'mission detail uses same RPC and preserves missing visibility',
    () async {
      final repo = repository((request) async {
        expect(request.url.path, '/rest/v1/rpc/list_missions');
        expect(jsonDecode(request.body), {'mission_filter': 'hidden'});
        return http.Response('[]', 200);
      });
      expect(await repo.mission('hidden'), isNull);
    },
  );

  test(
    'create returns id and update allows a past start for server validation',
    () async {
      final requests = <http.Request>[];
      final repo = repository((request) async {
        requests.add(request);
        return http.Response(
          request.url.path.endsWith('create_mission') ? '"created-id"' : 'null',
          200,
        );
      });
      expect(await repo.createMission(input()), 'created-id');
      final createBody = jsonDecode(requests.first.body) as Map;
      expect(
        createBody['mission_input']['conditions'],
        'Participación gratuita',
      );
      expect(createBody['mission_input']['requirements'], 'Llevar material');
      expect(createBody['mission_input']['image_path'], 'author/image.png');
      expect(createBody['mission_input']['location_precision'], 'approximate');
      await repo.updateMission('mission', input(start: DateTime.utc(2000)));
      expect(requests.last.url.path, '/rest/v1/rpc/update_mission');
      expect(jsonDecode(requests.last.body)['mission_id'], 'mission');
    },
  );

  test(
    'cancel sends a trimmed reason and rejects empty cancellation',
    () async {
      var calls = 0;
      final repo = repository((request) async {
        calls++;
        expect(jsonDecode(request.body), {
          'mission_id': 'mission',
          'new_status': 'cancelled',
          'cancellation_reason': 'Lluvia intensa',
        });
        return http.Response('null', 200);
      });
      await expectLater(
        repo.setMissionStatus('mission', 'cancelled'),
        throwsA(isA<AppFailure>()),
      );
      expect(calls, 0);
      await repo.setMissionStatus(
        'mission',
        'cancelled',
        reason: ' Lluvia intensa ',
      );
      expect(calls, 1);
    },
  );

  test(
    'profile lookup batches unique ids without dropping applicants',
    () async {
      final batchSizes = <int>[];
      final repo = repository((request) async {
        final ids = jsonDecode(request.body)['profile_ids'] as List;
        batchSizes.add(ids.length);
        expect(ids.length, lessThanOrEqualTo(100));
        return http.Response(
          jsonEncode(
            ids
                .map(
                  (id) => {
                    'id': id,
                    'full_name': 'Persona $id',
                    'username': 'user$id',
                    'user_type': UserType.general.databaseValue,
                  },
                )
                .toList(),
          ),
          200,
        );
      });
      final profiles = await repo.profiles(
        ids: [...List.generate(205, (i) => '$i'), '0', '1'],
      );
      expect(batchSizes, [100, 100, 5]);
      expect(profiles.length, 205);
      expect(profiles.last.id, '204');
    },
  );

  test(
    'mission images use private bucket signed URLs and shared validation',
    () async {
      final repo = repository((request) async {
        expect(
          request.url.path,
          '/storage/v1/object/sign/mission-images/author/image.png',
        );
        expect(jsonDecode(request.body)['expiresIn'], 600);
        return http.Response(
          '{"signedURL":"/object/sign/mission-images/author/image.png?token=signed"}',
          200,
        );
      });
      expect(
        await repo.missionImageUrl('author/image.png'),
        contains('mission-images'),
      );
      await expectLater(
        repo.uploadMissionImage(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<AppFailure>()),
      );
      await expectLater(
        repo.uploadMissionImage(Uint8List(4 * 1024 * 1024 + 1)),
        throwsA(isA<AppFailure>()),
      );
    },
  );
}
