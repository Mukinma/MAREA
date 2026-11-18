import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'discover filters moderation and author before paginating posts',
    () async {
      const userId = '00000000-0000-4000-8000-000000000001';
      String encode(Object json) =>
          base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
      final token =
          '${encode({'alg': 'HS256'})}.'
          '${encode({'sub': userId, 'exp': 4102444800})}.test';
      final queries = <Map<String, String>>[];
      final client = SupabaseClient(
        'https://example.invalid',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          if (request.url.path == '/auth/v1/token') {
            return http.Response(
              jsonEncode({
                'access_token': token,
                'token_type': 'bearer',
                'refresh_token': 'test-refresh-token',
                'user': {'id': userId},
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          expect(request.url.path, '/rest/v1/posts');
          queries.add(request.url.queryParameters);
          return http.Response(
            '[]',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'test@example.invalid',
        password: 'test-only',
      );
      final repo = SupabaseCommunityRepository(client);
      await repo.posts(
        discoverOnly: true,
        category: 'fotografia',
        query: 'Manzanillo',
        offset: 30,
      );
      expect(queries.single['hidden'], 'eq.false');
      expect(queries.single['author_id'], 'neq.$userId');
      expect(queries.single['category'], 'eq.fotografia');
      expect(queries.single['or'], contains('Manzanillo'));
      expect(queries.single['offset'], '30');
      expect(queries.single['limit'], '30');

      await repo.posts(authorId: userId);
      expect(queries.last, isNot(contains('hidden')));
      expect(queries.last['author_id'], 'eq.$userId');
    },
  );
}
