import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/notifications/models/notification_destination.dart';

void main() {
  test('a MAREA message can be read without an actor or target', () {
    final message = SocialNotification.fromJson({
      'id': 'n',
      'recipient_id': 'u',
      'actor_id': null,
      'post_id': null,
      'mission_id': null,
      'kind': 'marea_message',
      'post_title': 'Tu próxima idea 👀',
      'created_at': '2026-10-05T12:00:00Z',
    });
    expect(message.actorId, isNull);
    expect(message.postTitle, contains('👀'));
    expect(message.isUnread, isTrue);
    expect(notificationDestination(message), '/home');
  });
  test('a MAREA chat message opens its conversation', () {
    final message = SocialNotification(
      id: 'n',
      recipientId: 'u',
      actorId: null,
      postId: null,
      kind: NotificationKind.mareaMessage,
      sourceId: 'conversation',
      postTitle: 'Nuevo mensaje',
      createdAt: DateTime.utc(2026),
    );
    expect(
      notificationDestination(message),
      '/messages?conversation=conversation',
    );
  });
  test('comment opens its post and the targeted conversation', () {
    final n = SocialNotification(
      id: 'n',
      recipientId: 'u',
      actorId: 'a',
      postId: 'post',
      kind: NotificationKind.comment,
      sourceId: 'comment',
      postTitle: 'Title',
      createdAt: DateTime.utc(2026),
    );
    expect(
      notificationDestination(n),
      '/posts/post?notification=n&panel=comments&comment=comment',
    );
  });
  test(
    'organizer events open management but applicant events open the mission',
    () {
      SocialNotification event(NotificationKind kind) => SocialNotification(
        id: 'n',
        recipientId: 'u',
        actorId: 'a',
        postId: null,
        missionId: 'mission',
        kind: kind,
        postTitle: 'Title',
        createdAt: DateTime.utc(2026),
      );
      expect(
        notificationDestination(event(NotificationKind.missionApplication)),
        '/missions/mission/manage',
      );
      expect(
        notificationDestination(event(NotificationKind.missionAccepted)),
        '/missions/mission',
      );
    },
  );
  test(
    'push payloads cannot provide an arbitrary route or malformed identity',
    () {
      expect(
        PushNotice.fromData({
          'notification_id': '../settings',
          'recipient_id': 'user',
        }),
        isNull,
      );
      expect(PushNotice.fromData({'route': 'https://example.com'}), isNull);
    },
  );
}
