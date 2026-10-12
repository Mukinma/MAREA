import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/config/app_config.dart';
import 'package:marea/features/community/models/mission_social.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/notifications/models/notification_destination.dart';

void main() {
  test('mission share URL uses the configured public origin', () {
    final config = AppConfig.fromValues(
      supabaseUrl: '',
      supabaseAnonKey: '',
      publicUrl: 'https://example.test/base?x=y',
    );
    expect(
      config.missionUrl('m').toString(),
      'https://example.test/missions/m',
    );
  });
  test('mission social stats reuse all three reaction choices', () {
    for (final reaction in PostReaction.values) {
      final stats = MissionSocialStats.fromJson({
        'mission_id': 'm',
        'reaction_count': 4,
        'comment_count': 2,
        'my_reaction': reaction.name,
      });
      expect(stats.missionId, 'm');
      expect(stats.reactionCount, 4);
      expect(stats.commentCount, 2);
      expect(stats.myReaction, reaction);
    }
  });
  test('mission comment notification opens the specific conversation', () {
    final n = SocialNotification(
      id: 'n',
      recipientId: 'a',
      actorId: 'b',
      postId: null,
      missionId: 'm',
      kind: NotificationKind.comment,
      sourceId: 'c',
      postTitle: 'Misión',
      createdAt: DateTime.utc(2026),
    );
    final url = Uri.parse(notificationDestination(n));
    expect(url.path, '/missions/m');
    expect(url.queryParameters, {
      'notification': 'n',
      'panel': 'comments',
      'comment': 'c',
    });
  });
  test('mission comment preserves typed mission ownership', () {
    final comment = MissionComment.fromJson({
      'id': 'c',
      'mission_id': 'm',
      'author_id': 'a',
      'body': 'Hola',
      'created_at': '2026-10-07T00:00:00Z',
    });
    expect(comment.missionId, 'm');
    expect(comment.authorId, 'a');
  });
}
