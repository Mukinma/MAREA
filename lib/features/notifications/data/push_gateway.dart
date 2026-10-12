import '../models/notification_destination.dart';

enum PushPermission { unavailable, denied, granted }

class ForegroundNotice {
  const ForegroundNotice({
    required this.notice,
    required this.version,
    required this.kind,
    required this.title,
    required this.body,
  });
  final PushNotice notice;
  final String version, kind, title, body;
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
