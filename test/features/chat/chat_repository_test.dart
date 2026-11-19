import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marea/features/chat/data/chat_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'conversation previews use the conversation ID and retain the avatar',
    () async {
      const user = '00000000-0000-4000-8000-000000000001';
      const other = '00000000-0000-4000-8000-000000000002';
      const conversation = '00000000-0000-4000-8000-000000000003';
      const date = '2026-10-01T10:00:00Z';
      String encode(Object json) =>
          base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
      final token =
          '${encode({'alg': 'HS256'})}.'
          '${encode({'sub': user, 'exp': 4102444800})}.test';

      final client = SupabaseClient(
        'https://example.invalid',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          final Object rows = switch (request.url.path) {
            '/auth/v1/token' => {
              'access_token': token,
              'token_type': 'bearer',
              'refresh_token': 'test-refresh-token',
              'user': {'id': user},
            },
            '/rest/v1/chat_conversations' => [
              {
                'id': conversation,
                'requester_id': user,
                'recipient_id': other,
                'status': 'accepted',
                'created_at': date,
                'last_message_at': date,
              },
            ],
            '/rest/v1/rpc/community_profiles' => [
              {
                'id': other,
                'full_name': 'Colectivo',
                'username': 'colectivo',
                'avatar_path': '$other/avatar.png',
              },
            ],
            '/rest/v1/chat_messages' => [
              {
                'conversation_id': conversation,
                'body': 'Hola',
                'created_at': date,
              },
            ],
            _ => throw StateError('Unexpected request: ${request.url.path}'),
          };
          return http.Response(
            jsonEncode(rows),
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

      final chats = await SupabaseChatRepository(client).conversations();
      expect(chats.single.lastMessageBody, 'Hola');
      expect(chats.single.otherAvatarPath, '$other/avatar.png');
    },
  );
}
