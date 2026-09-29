import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/community/models/post_social.dart';

void main() {
  test('server summaries preserve selection, counts and interest state', () {
    final stats = PostSocialStats.fromJson({
      'post_id': 'post', 'reaction_count': 4, 'comment_count': 2,
      'my_reaction': 'inspire', 'interest_sent': true,
    });
    expect(stats.myReaction, PostReaction.inspire);
    expect(stats.reactionCount, 4);
    expect(stats.commentCount, 2);
    expect(stats.interestSent, isTrue);
  });
  test('notifications distinguish read and unread server states', () {
    final notification = SocialNotification.fromJson({
      'id':'n', 'recipient_id':'a', 'actor_id':'b', 'post_id':'p',
      'kind':'comment', 'source_id':'c', 'post_title':'Mi post',
      'created_at':'2026-09-29T00:00:00Z', 'read_at':null,
    });
    expect(notification.isUnread, isTrue);
    expect(notification.sourceId, 'c');
    expect(notification.kind, NotificationKind.comment);
  });
}
