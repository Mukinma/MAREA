import '../models/notification_destination.dart';
import '../models/notification_preferences.dart';

enum PushPermission { unavailable, notDetermined, denied, granted }

class ForegroundNotice {
  const ForegroundNotice({
    required this.notice,
    required this.version,
    required this.kind,
    required this.title,
    required this.body,
    this.category,
  });
  final PushNotice notice;
  final String version, kind, title, body;
  final NotificationCategory? category;

  ForegroundNotice withCategory(NotificationCategory value) => ForegroundNotice(
    notice: notice,
    version: version,
    kind: kind,
    title: title,
    body: body,
    category: value,
  );
}

abstract interface class PushGateway {
  Stream<PushNotice> get opened;
  Stream<String> get tokenChanges;
  Stream<ForegroundNotice> get received;
  Future<bool> initialize();
  Future<PushPermission> permission();
  Future<PushPermission> promptOnce();
  Future<PushPermission> requestPermission();
  Future<void> openSettings();
  Future<String?> token();
  Future<String> installationId();
  Future<String> timezone();
  Future<void> present(ForegroundNotice message);
  Future<void> reset();
  Future<void> dispose();
}
