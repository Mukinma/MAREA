import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/post_social.dart';

abstract interface class SocialRepository {
  Future<Map<String, PostSocialStats>> stats(List<String> postIds);
  Future<void> setReaction(String postId, PostReaction? reaction);
  Future<List<PostComment>> comments(String postId, {int offset = 0});
  Future<PostComment?> comment(String id);
  Future<String> createComment(String postId, String body, String operationId);
  Future<void> deleteComment(String id);
  Future<String> sendInterest(String postId, String message);
  Future<CollaborationInterest?> interest(String id);
  Future<List<SocialNotification>> notifications({
    bool unreadOnly = false,
    int offset = 0,
  });
  Future<int> unreadCount();
  Future<void> markRead({String? id, DateTime? before});
  Stream<void> changes(String recipientId);
}

class SupabaseSocialRepository implements SocialRepository {
  SupabaseSocialRepository(this.client);
  final SupabaseClient client;
  Future<T> _run<T>(Future<T> Function() op) async {
    try {
      return await op();
    } catch (error) {
      if (error is PostgrestException) {
        final message = switch (error.message) {
          'post_unavailable' =>
            'Esta publicación fue retirada o ya no está disponible.',
          'comment_unavailable' => 'Este comentario fue retirado.',
          'comment_permission_denied' =>
            'No tienes permiso para retirar este comentario.',
          'invalid_comment' => 'Escribe entre 1 y 1.000 caracteres.',
          'invalid_interest' => 'Escribe entre 1 y 1.000 caracteres.',
          'collaboration_closed' =>
            'Esta publicación ya no admite colaboraciones.',
          _ => null,
        };
        if (message != null) throw AppFailure(message);
      }
      throw communityFailure(error);
    }
  }

  @override
  Future<Map<String, PostSocialStats>> stats(List<String> postIds) =>
      _run(() async {
        if (postIds.isEmpty) return {};
        final rows = await client.rpc(
          'post_social_stats',
          params: {'post_ids': postIds},
        );
        return {
          for (final row in rows as List)
            row['post_id'] as String: PostSocialStats.fromJson(
              Map<String, dynamic>.from(row),
            ),
        };
      });
  @override
  Future<void> setReaction(String postId, PostReaction? reaction) =>
      _run(() async {
        await client.rpc(
          'set_post_reaction',
          params: {'post_uuid': postId, 'reaction_type': reaction?.name},
        );
      });
  @override
  Future<List<PostComment>> comments(String postId, {int offset = 0}) =>
      _run(() async {
        final rows = await client
            .from('post_comments')
            .select()
            .eq('post_id', postId)
            .order('created_at', ascending: false)
            .order('id', ascending: false)
            .range(offset, offset + 29);
        return rows.map(PostComment.fromJson).toList();
      });
  @override
  Future<PostComment?> comment(String id) => _run(() async {
    final row = await client
        .from('post_comments')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : PostComment.fromJson(row);
  });
  @override
  Future<String> createComment(
    String postId,
    String body,
    String operationId,
  ) => _run(
    () async =>
        await client.rpc(
              'create_post_comment',
              params: {
                'post_uuid': postId,
                'comment_body': body,
                'operation_uuid': operationId,
              },
            )
            as String,
  );
  @override
  Future<void> deleteComment(String id) => _run(() async {
    await client.rpc('delete_post_comment', params: {'comment_uuid': id});
  });
  @override
  Future<String> sendInterest(String postId, String message) => _run(
    () async =>
        await client.rpc(
              'send_post_interest',
              params: {'post_uuid': postId, 'interest_message': message},
            )
            as String,
  );
  @override
  Future<CollaborationInterest?> interest(String id) => _run(() async {
    final row = await client
        .from('post_collaboration_interests')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : CollaborationInterest.fromJson(row);
  });
  @override
  Future<List<SocialNotification>> notifications({
    bool unreadOnly = false,
    int offset = 0,
  }) => _run(() async {
    var query = client.from('notifications').select();
    if (unreadOnly) query = query.isFilter('read_at', null);
    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + 29);
    return rows.map(SocialNotification.fromJson).toList();
  });
  @override
  Future<int> unreadCount() => _run(
    () async => await client
        .from('notifications')
        .count(CountOption.exact)
        .isFilter('read_at', null),
  );
  @override
  Future<void> markRead({String? id, DateTime? before}) => _run(() async {
    await client.rpc(
      'mark_notifications_read',
      params: {
        'notification_uuid': id,
        'before_time': before?.toUtc().toIso8601String(),
      },
    );
  });
  @override
  Stream<void> changes(String recipientId) => client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('recipient_id', recipientId)
      .map((_) {});
}
