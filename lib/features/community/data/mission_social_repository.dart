import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/mission_social.dart';
import 'package:marea/features/community/models/post_social.dart';

abstract interface class MissionSocialRepository {
  Future<Map<String, MissionSocialStats>> stats(List<String> missionIds);
  Future<void> setReaction(String missionId, PostReaction? reaction);
  Future<List<MissionComment>> comments(String missionId, {int offset = 0});
  Future<MissionComment?> comment(String id);
  Future<String> createComment(
    String missionId,
    String body,
    String operationId,
  );
  Future<void> deleteComment(String id);
}

class SupabaseMissionSocialRepository implements MissionSocialRepository {
  SupabaseMissionSocialRepository(this.client);
  final SupabaseClient client;
  Future<T> _run<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      if (error is PostgrestException) {
        final message = switch (error.message) {
          'mission_unavailable' =>
            'Esta misión fue retirada o ya no está disponible.',
          'comment_unavailable' => 'Este comentario fue retirado.',
          'comment_permission_denied' =>
            'No tienes permiso para retirar este comentario.',
          'invalid_comment' => 'Escribe entre 1 y 1.000 caracteres.',
          'operation_conflict' =>
            'Este envío ya se utilizó con otro comentario.',
          _ => null,
        };
        if (message != null) throw AppFailure(message);
      }
      throw communityFailure(error);
    }
  }

  @override
  Future<Map<String, MissionSocialStats>> stats(List<String> missionIds) =>
      _run(() async {
        if (missionIds.isEmpty) return {};
        final rows = await client.rpc(
          'mission_social_stats',
          params: {'mission_ids': missionIds},
        );
        return {
          for (final row in rows as List)
            row['mission_id'] as String: MissionSocialStats.fromJson(
              Map<String, dynamic>.from(row),
            ),
        };
      });
  @override
  Future<void> setReaction(String missionId, PostReaction? reaction) =>
      _run(() async {
        await client.rpc(
          'set_mission_reaction',
          params: {'mission_uuid': missionId, 'reaction_type': reaction?.name},
        );
      });
  @override
  Future<List<MissionComment>> comments(String missionId, {int offset = 0}) =>
      _run(() async {
        final rows = await client
            .from('mission_comments')
            .select()
            .eq('mission_id', missionId)
            .order('created_at', ascending: false)
            .order('id', ascending: false)
            .range(offset, offset + 29);
        return rows.map(MissionComment.fromJson).toList();
      });
  @override
  Future<MissionComment?> comment(String id) => _run(() async {
    final row = await client
        .from('mission_comments')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : MissionComment.fromJson(row);
  });
  @override
  Future<String> createComment(
    String missionId,
    String body,
    String operationId,
  ) => _run(
    () async =>
        await client.rpc(
              'create_mission_comment',
              params: {
                'mission_uuid': missionId,
                'comment_body': body,
                'operation_uuid': operationId,
              },
            )
            as String,
  );
  @override
  Future<void> deleteComment(String id) => _run(() async {
    await client.rpc('delete_mission_comment', params: {'comment_uuid': id});
  });
}
