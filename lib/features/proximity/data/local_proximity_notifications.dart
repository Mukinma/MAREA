import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/proximity_models.dart';
import 'proximity_services.dart';

class ProximityNotificationPayload {
  const ProximityNotificationPayload({
    required this.recipientId,
    required this.targetId,
    required this.kind,
    required this.route,
  });

  final String recipientId, targetId, route;
  final ProximityTargetKind kind;

  bool get isValid =>
      isProximityUuid(recipientId) &&
      isAllowedProximityRoute(route, kind: kind, targetId: targetId);

  String encode() {
    if (!isValid) throw ArgumentError('Invalid proximity destination');
    return jsonEncode({
      'type': 'proximity',
      'version': 1,
      'recipient_id': recipientId,
      'target_id': targetId,
      'target_kind': kind.name,
      'route': route,
    });
  }

  static ProximityNotificationPayload? parse(
    String? payload, {
    required String currentAccountId,
  }) {
    if (payload == null || !isProximityUuid(currentAccountId)) return null;
    try {
      final data = jsonDecode(payload);
      if (data is! Map<String, dynamic> ||
          data['type'] != 'proximity' ||
          data['version'] != 1 ||
          data['recipient_id'] != currentAccountId ||
          data['target_id'] is! String ||
          data['route'] is! String) {
        return null;
      }
      final kind = switch (data['target_kind']) {
        'mission' => ProximityTargetKind.mission,
        'marker' => ProximityTargetKind.marker,
        _ => null,
      };
      if (kind == null) return null;
      final notice = ProximityNotificationPayload(
        recipientId: currentAccountId,
        targetId: data['target_id'] as String,
        kind: kind,
        route: data['route'] as String,
      );
      return notice.isValid ? notice : null;
    } catch (_) {
      return null;
    }
  }
}

/// Uses the app's already initialized singleton. The owner must multiplex its
/// notification callback with ProximityNotificationPayload.parse; initializing
/// here would replace push callbacks. This adapter never requests permission.
class LocalProximityNotificationSink implements ProximityNotificationSink {
  LocalProximityNotificationSink({required this._plugin});

  final FlutterLocalNotificationsPlugin _plugin;
  final _posted = <String, Map<String, ({int id, String tag})>>{};
  static const channel = AndroidNotificationChannel(
    'marea_proximity',
    'Experiencias cercanas',
    description: 'Avisos al acercarte a una misión o imagen RA',
    importance: Importance.high,
  );

  @override
  Future<void> present(
    ProximityEncounter encounter, {
    required String accountId,
    required bool Function() isCurrent,
  }) async {
    final target = encounter.target;
    if (!isCurrent() || !target.isValid || !isProximityUuid(accountId)) return;
    final payload = ProximityNotificationPayload(
      recipientId: accountId,
      targetId: target.id,
      kind: target.kind,
      route: target.route,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    if (!isCurrent()) return;
    final tag = 'proximity:$accountId:${target.key}';
    final id = _noticeId(tag);
    final posted = _posted.putIfAbsent(accountId, () => {});
    posted[target.key] = (id: id, tag: tag);
    await _plugin.show(
      id: id,
      title: 'Estás cerca de ${target.title}',
      body: target.kind == ProximityTargetKind.mission
          ? 'Hay una misión a 20 metros o menos. Toca para verla.'
          : 'Hay una experiencia RA a 20 metros o menos. Toca para explorar.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'ic_marea_notification',
          tag: tag,
          importance: channel.importance,
          priority: Priority.high,
          onlyAlertOnce: true,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload.encode(),
    );
    if (!isCurrent()) {
      await _plugin.cancel(id: id, tag: tag);
      posted.remove(target.key);
    }
  }

  @override
  Future<void> clearAccount(String accountId) async {
    final posted = _posted.remove(accountId);
    if (posted == null) return;
    for (final notice in posted.values.toList()) {
      await _plugin.cancel(id: notice.id, tag: notice.tag);
    }
  }

  int _noticeId(String value) {
    var hash = 0x811c9dc5;
    for (final code in value.codeUnits) {
      hash = ((hash ^ code) * 0x01000193) & 0x3fffffff;
    }
    // Existing social push uses id 0; proximity has a separate numeric range.
    return 0x40000000 | hash;
  }
}
