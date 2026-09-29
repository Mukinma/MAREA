enum PostReaction {
  like('Me gusta'),
  inspire('Me inspira'),
  support('Lo apoyo');

  const PostReaction(this.label);
  final String label;
}

class PostSocialStats {
  const PostSocialStats({
    required this.postId,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.myReaction,
    this.interestSent = false,
  });
  final String postId;
  final int reactionCount, commentCount;
  final PostReaction? myReaction;
  final bool interestSent;
  factory PostSocialStats.fromJson(Map<String, dynamic> j) => PostSocialStats(
    postId: j['post_id'] as String,
    reactionCount: (j['reaction_count'] as num?)?.toInt() ?? 0,
    commentCount: (j['comment_count'] as num?)?.toInt() ?? 0,
    myReaction: PostReaction.values
        .where((r) => r.name == j['my_reaction'])
        .firstOrNull,
    interestSent: j['interest_sent'] == true,
  );
}

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });
  final String id, postId, authorId, body;
  final DateTime createdAt;
  factory PostComment.fromJson(Map<String, dynamic> j) => PostComment(
    id: j['id'],
    postId: j['post_id'],
    authorId: j['author_id'],
    body: j['body'],
    createdAt: DateTime.parse(j['created_at']),
  );
}

class CollaborationInterest {
  const CollaborationInterest({
    required this.id,
    required this.postId,
    required this.applicantId,
    required this.message,
    required this.createdAt,
  });
  final String id, postId, applicantId, message;
  final DateTime createdAt;
  factory CollaborationInterest.fromJson(Map<String, dynamic> j) =>
      CollaborationInterest(
        id: j['id'],
        postId: j['post_id'],
        applicantId: j['applicant_id'],
        message: j['message'],
        createdAt: DateTime.parse(j['created_at']),
      );
}

enum NotificationKind { reaction, comment, interest }

class SocialNotification {
  const SocialNotification({
    required this.id,
    required this.recipientId,
    required this.actorId,
    required this.postId,
    required this.kind,
    required this.postTitle,
    required this.createdAt,
    this.sourceId,
    this.readAt,
  });
  final String id, recipientId, actorId, postId, postTitle;
  final String? sourceId;
  final NotificationKind kind;
  final DateTime createdAt;
  final DateTime? readAt;
  bool get isUnread => readAt == null;
  factory SocialNotification.fromJson(Map<String, dynamic> j) =>
      SocialNotification(
        id: j['id'],
        recipientId: j['recipient_id'],
        actorId: j['actor_id'],
        postId: j['post_id'],
        kind: NotificationKind.values.byName(j['kind']),
        sourceId: j['source_id'],
        postTitle: j['post_title'],
        createdAt: DateTime.parse(j['created_at']),
        readAt: j['read_at'] == null ? null : DateTime.parse(j['read_at']),
      );
}
