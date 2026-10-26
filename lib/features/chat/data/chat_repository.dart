import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/chat/models/chat_models.dart';
import 'package:marea/features/chat/data/chat_censor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ChatRepository {
  Future<List<ChatConversation>> conversations();
  Future<List<ChatMessage>> messages(String conversationId);
  Future<String> request(String targetId);
  Future<void> accept(String conversationId);
  Future<void> reject(String conversationId);
  Future<String> send(String conversationId, String body);
  Future<void> block(String targetId, bool blocked);
  Future<void> report(String conversationId, String? messageId, String reason);
  Stream<void> changes(String conversationId);
}

class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this.client);
  final SupabaseClient client;
  Future<T> _run<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      if (error is PostgrestException) {
        if (error.code == 'PGRST202' &&
            (error.message.contains('request_chat') ||
                error.message.contains('chat_'))) {
          throw const AppFailure(
            'El chat todavía no está habilitado en este servicio. '
            'Aplica la migración 022_private_chat.sql y vuelve a intentarlo.',
          );
        }
        final message = switch (error.message) {
          'chat_blocked' => 'Este chat está bloqueado.',
          'chat_unavailable' => 'Este chat ya no está disponible.',
          'invalid_chat_message' => 'Escribe entre 1 y 2.000 caracteres.',
          _ => null,
        };
        if (message != null) throw AppFailure(message);
      }
      throw AppFailureMapper.from(error);
    }
  }

  @override
  Future<List<ChatConversation>> conversations() => _run(() async {
    final user = client.auth.currentUser!.id;
    final rows = await client
        .from('chat_conversations')
        .select()
        .or('requester_id.eq.$user,recipient_id.eq.$user')
        .order('last_message_at', ascending: false);
    final ids = rows
        .map(
          (r) =>
              (r['requester_id'] == user
                      ? r['recipient_id']
                      : r['requester_id'])
                  as String,
        )
        .toSet()
        .toList();
    final profiles = ids.isEmpty
        ? <Map<String, dynamic>>[]
        : (await client.rpc(
                    'community_profiles',
                    params: {'profile_ids': ids, 'query_text': ''},
                  )
                  as List)
              .map((row) => Map<String, dynamic>.from(row as Map))
              .toList();
    final byId = {for (final p in profiles) p['id'] as String: p};
    final conversationIds = rows.map((row) => row['id'] as String).toList();
    final latestMessages = conversationIds.isEmpty
        ? <Map<String, dynamic>>[]
        : (await client
                  .from('chat_messages')
                  .select('conversation_id,body,created_at')
                  .inFilter('conversation_id', conversationIds)
                  .order('created_at', ascending: false))
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
    final lastBody = <String, String>{};
    for (final message in latestMessages) {
      lastBody.putIfAbsent(
        message['conversation_id'] as String,
        () => message['body'] as String,
      );
    }
    return rows.map((r) {
      final id =
          (r['requester_id'] == user ? r['recipient_id'] : r['requester_id'])
              as String;
      final p = byId[id];
      return ChatConversation.fromJson(
        Map<String, dynamic>.from(r),
        otherName: p?['full_name'] as String?,
        otherUsername: p?['username'] as String?,
      ).copyWithLastMessage(lastBody[id]);
    }).toList();
  });
  @override
  Future<List<ChatMessage>> messages(String conversationId) => _run(
    () async =>
        (await client
                .from('chat_messages')
                .select()
                .eq('conversation_id', conversationId)
                .order('created_at', ascending: false))
            .map(ChatMessage.fromJson)
            .toList(),
  );
  @override
  Future<String> request(String targetId) => _run(
    () async =>
        await client.rpc('request_chat', params: {'target': targetId})
            as String,
  );
  @override
  Future<void> accept(String id) => _run(() async {
    await client.rpc('accept_chat', params: {'conversation': id});
  });
  @override
  Future<void> reject(String id) => _run(() async {
    await client.rpc('reject_chat', params: {'conversation': id});
  });
  @override
  Future<String> send(String id, String body) => _run(
    () async =>
        await client.rpc(
              'send_chat_message',
              params: {
                'conversation': id,
                'message_body': censorChatMessage(body),
              },
            )
            as String,
  );
  @override
  Future<void> block(String id, bool blocked) => _run(() async {
    await client.rpc(
      'set_chat_block',
      params: {'target': id, 'blocked': blocked},
    );
  });
  @override
  Future<void> report(String id, String? messageId, String reason) =>
      _run(() async {
        await client.rpc(
          'report_chat',
          params: {
            'conversation': id,
            'message': messageId,
            'report_reason': reason,
          },
        );
      });
  @override
  Stream<void> changes(String id) => client
      .from('chat_messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', id)
      .map((_) {});
}
