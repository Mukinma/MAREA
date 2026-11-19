import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marea/features/tours/data/tour_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'only a gallery sphere bypasses the panorama processing queue',
    () async {
      final paths = <String>[];
      final client = SupabaseClient(
        'https://tours.example.invalid',
        'test-key',
        httpClient: MockClient((request) async {
          paths.add(request.url.path);
          final direct = request.url.path == '/functions/v1/tour-import';
          final body = jsonDecode(request.body) as Map;
          if (direct) {
            expect(body, {'capture': 'capture', 'frame': 'frame'});
          } else {
            expect(body['p_capture'], 'capture');
            expect(body['p_manifest'], isA<Map>());
          }
          return http.Response(
            jsonEncode({'id': 'job', 'state': direct ? 'ready' : 'queued'}),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(client.dispose);
      final repo = SupabaseTourRepository(client, '');
      final sphere = await repo.submitCapture('capture', {
        'mode': 'import',
        'frames': [
          {'id': 'frame'},
        ],
      });
      expect(sphere.state, 'ready');
      final horizontal = await repo.submitCapture('capture', {
        'mode': 'import',
        'panorama_kind': 'horizontal',
      });
      expect(horizontal.state, 'queued');
      final photos = await repo.submitCapture('capture', {'mode': 'photos'});
      expect(photos.state, 'queued');
      expect(paths, [
        '/functions/v1/tour-import',
        '/rest/v1/rpc/tours_capture_submit',
        '/rest/v1/rpc/tours_capture_submit',
      ]);
    },
  );

  test(
    'publication calls the owner RPC and confirms the public revision',
    () async {
      final client = SupabaseClient(
        'https://tours.example.invalid',
        'test-key',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/rest/v1/rpc/tours_publish');
          expect(jsonDecode(request.body), {'p_tour': 'tour'});
          return http.Response(
            jsonEncode({
              'id': 'tour',
              'owner_id': 'owner',
              'state': 'published',
              'revision_id': 'revision',
              'public_revision_id': 'revision',
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(client.dispose);
      final record = await SupabaseTourRepository(client, '').submit('tour');
      expect(record.state, 'published');
      expect(record.publicRevisionId, record.revisionId);
    },
  );

  test(
    'an old server cannot silently send a direct publication to review',
    () async {
      var calls = 0;
      final client = SupabaseClient(
        'https://tours.example.invalid',
        'test-key',
        httpClient: MockClient((request) async {
          calls++;
          expect(request.url.path, '/rest/v1/rpc/tours_publish');
          return http.Response(
            jsonEncode({'code': 'PGRST202', 'message': 'Function not found'}),
            404,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(client.dispose);
      await expectLater(
        SupabaseTourRepository(client, '').submit('tour'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Tu borrador sigue guardado'),
          ),
        ),
      );
      expect(calls, 1);
    },
  );
}
