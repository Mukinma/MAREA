import 'package:marea/features/community/models/post_social.dart';

/// Both the in-app inbox and Android open the same destination.
String notificationDestination(SocialNotification n) {
  if (n.kind == NotificationKind.mareaMessage) return '/home';
  if (n.missionId != null) {
    final organizer =
        n.kind == NotificationKind.missionApplication ||
        n.kind == NotificationKind.missionWithdrawn;
    return Uri(
      pathSegments: ['', 'missions', n.missionId!, if (organizer) 'manage'],
      queryParameters:
          n.kind == NotificationKind.comment ||
              n.kind == NotificationKind.reaction
          ? {
              'notification': n.id,
              if (n.kind == NotificationKind.comment) ...{
                'panel': 'comments',
                if (n.sourceId != null) 'comment': n.sourceId!,
              },
            }
          : null,
    ).toString();
  }
  if (n.postId == null) return '/home';
  return Uri(
    pathSegments: ['', 'posts', n.postId!],
    queryParameters: {
      'notification': n.id,
      if (n.kind == NotificationKind.comment) ...{
        'panel': 'comments',
        if (n.sourceId != null) 'comment': n.sourceId!,
      },
      if (n.kind == NotificationKind.interest) ...{
        'panel': 'interest',
        if (n.sourceId != null) 'interest': n.sourceId!,
      },
    },
  ).toString();
}

class PushNotice {
  const PushNotice({required this.notificationId, required this.recipientId});
  final String notificationId, recipientId;
  static PushNotice? fromData(Map<String, dynamic> data) {
    final id = data['notification_id'], recipient = data['recipient_id'];
    // Payloads are identifiers, never arbitrary navigation URLs.
    final uuid = RegExp(
      r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$',
    );
    if (id is! String ||
        recipient is! String ||
        !uuid.hasMatch(id) ||
        !uuid.hasMatch(recipient)) {
      return null;
    }
    return PushNotice(notificationId: id, recipientId: recipient);
  }
}
