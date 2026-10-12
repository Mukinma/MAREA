import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/notification_destination.dart';
import 'push_gateway.dart';

/// Web/iOS share preferences and activity without registering a push token.
class InboxOnlyGateway implements PushGateway {
  @override
  Stream<PushNotice> get opened => const Stream.empty();
  @override
  Stream<String> get tokenChanges => const Stream.empty();
  @override
  Stream<ForegroundNotice> get received => const Stream.empty();
  @override
  Future<bool> initialize() async => false;
  @override
  Future<PushPermission> permission() async => PushPermission.unavailable;
  @override
  Future<PushPermission> promptOnce() => permission();
  @override
  Future<PushPermission> requestPermission() => permission();
  @override
  Future<void> openSettings() async {}
  @override
  Future<String?> token() async => null;
  @override
  Future<String> installationId() async =>
      throw UnsupportedError('No push transport');
  @override
  Future<String> timezone() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;
  @override
  Future<void> present(ForegroundNotice message) async {}
  @override
  Future<void> reset() async {}
  @override
  Future<void> dispose() async {}
}
