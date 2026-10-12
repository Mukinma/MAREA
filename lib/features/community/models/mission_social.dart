import 'package:marea/features/community/models/post_social.dart';

class MissionSocialStats {
  const MissionSocialStats({
    required this.missionId,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.myReaction,
  });
  final String missionId;
  final int reactionCount, commentCount;
  final PostReaction? myReaction;
  factory MissionSocialStats.fromJson(Map<String, dynamic> json) =>
      MissionSocialStats(
        missionId: json['mission_id'] as String,
        reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0,
        commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
        myReaction: PostReaction.values
            .where((r) => r.name == json['my_reaction'])
            .firstOrNull,
      );
}

class MissionComment {
  const MissionComment({
    required this.id,
    required this.missionId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });
  final String id, missionId, authorId, body;
  final DateTime createdAt;
  factory MissionComment.fromJson(Map<String, dynamic> json) => MissionComment(
    id: json['id'] as String,
    missionId: json['mission_id'] as String,
    authorId: json['author_id'] as String,
    body: json['body'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
