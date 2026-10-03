import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';

class _CleanupRepository extends SupabaseCommunityRepository {
  _CleanupRepository(super.client);
  final removed = <String>[];
  @override
  Future<void> removeMissionImage(String path) async {
    removed.add(path);
  }
}

void main() {
  test('draft discovery filters publication journal by timestamp', () async {
    late http.Request request;
    final client = SupabaseClient(
      'https://example.invalid',
      'test',
      httpClient: _Client((r) async {
        request = r;
        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    await SupabaseCommunityRepository(client).missionDrafts();
    expect(request.url.queryParameters['published_at'], 'is.null');
    expect(
      request.url.queryParameters.containsKey('published_mission_id'),
      isFalse,
    );
  });
  test(
    'draft deletion removes its cover only after server confirms deletion',
    () async {
      final calls = <String>[];
      final client = SupabaseClient(
        'https://example.invalid',
        'test',
        httpClient: _Client((r) async {
          calls.add(r.url.path);
          return http.Response(
            r.method == 'GET'
                ? jsonEncode({
                    'id': 'd',
                    'data': {'image_path': 'u/cover.png'},
                    'updated_at': '2026-01-01T00:00:00Z',
                  })
                : 'null',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final repo = _CleanupRepository(client);
      await repo.deleteMissionDraft('d');
      expect(calls, [
        '/rest/v1/mission_drafts',
        '/rest/v1/rpc/delete_mission_draft',
      ]);
      expect(repo.removed, ['u/cover.png']);
    },
  );

  const op = '11111111-1111-4111-8111-111111111111';
  test(
    'structured submission sends evidence availability and stable retry ID',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.invalid',
        'test',
        httpClient: _Client((r) async {
          requests.add(r);
          return http.Response(
            jsonEncode('application-id'),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final repo = SupabaseCommunityRepository(client);
      const input = MissionApplicationInput(
        message: ' Mi experiencia ',
        availabilityConfirmed: true,
        operationId: op,
        evidence: [
          MissionEvidence(title: ' Mi obra ', url: 'https://example.com/work'),
        ],
      );
      expect(await repo.submitApplication('m', input), 'application-id');
      expect(
        requests.single.url.path,
        '/rest/v1/rpc/submit_mission_application',
      );
      expect(jsonDecode(requests.single.body), {
        'mission_id': 'm',
        'application_input': {
          'message': 'Mi experiencia',
          'availability_confirmed': true,
          'operation_id': op,
          'evidence': [
            {
              'title': 'Mi obra',
              'showcase_id': null,
              'url': 'https://example.com/work',
            },
          ],
        },
      });
    },
  );
  test('draft ID is retained and incomplete payload may be saved', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.invalid',
      'test',
      httpClient: _Client((r) async {
        requests.add(r);
        return http.Response(
          jsonEncode(op),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final repo = SupabaseCommunityRepository(client);
    expect(await repo.saveMissionDraft({'title': 'Idea'}, id: op), op);
    expect(jsonDecode(requests.single.body), {
      'draft_id': op,
      'draft_input': {'title': 'Idea'},
    });
  });
  test('selection does not send an empty group to the server', () async {
    var calls = 0;
    final client = SupabaseClient(
      'https://example.invalid',
      'test',
      httpClient: _Client((r) async {
        calls++;
        return http.Response('null', 200);
      }),
    );
    addTearDown(client.dispose);
    await expectLater(
      SupabaseCommunityRepository(client).confirmMissionSelection('m', []),
      throwsA(isA<Exception>()),
    );
    expect(calls, 0);
  });
}

class _Client extends http.BaseClient {
  _Client(this.handle);
  final Future<http.Response> Function(http.Request) handle;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest r) async {
    final request = http.Request(r.method, r.url)
      ..headers.addAll(r.headers)
      ..bodyBytes = await r.finalize().toBytes();
    final response = await handle(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: r,
    );
  }
}
