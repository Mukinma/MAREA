import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import '../models/notification_destination.dart';
import 'push_gateway.dart';

FirebaseOptions? firebaseOptionsFromEnvironment() {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const sender = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  const project = String.fromEnvironment('FIREBASE_PROJECT_ID');
  if ([apiKey, appId, sender, project].any((v) => v.isEmpty)) return null;
  return const FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: sender,
    projectId: project,
  );
}

@pragma('vm:entry-point')
Future<void> mareaBackgroundMessage(RemoteMessage message) async {
  // FCM displays background notification payloads. Do not display them again.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: firebaseOptionsFromEnvironment());
  }
}

class AndroidPushGateway implements PushGateway {
  final _opened = StreamController<PushNotice>.broadcast();
  final _received = StreamController<ForegroundNotice>.broadcast();
  final _tokens = StreamController<String>.broadcast();
  final _local = FlutterLocalNotificationsPlugin();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  FirebaseMessaging? _messaging;
  bool _initialized = false;
  static const _channel = AndroidNotificationChannel(
    'marea_activity',
    'Actividad de MAREA',
    description: 'Reacciones, conversaciones y misiones',
    importance: Importance.high,
  );
  static const _mareaChannel = AndroidNotificationChannel(
    'marea_messages',
    'Mensajes de MAREA',
    description: 'Ideas y recordatorios ocasionales',
    importance: Importance.defaultImportance,
  );
  @override
  Stream<PushNotice> get opened => _opened.stream;
  @override
  Stream<ForegroundNotice> get received => _received.stream;
  @override
  Stream<String> get tokenChanges => _tokens.stream;

  void _openData(Map<String, dynamic> data) {
    final notice = PushNotice.fromData(data);
    if (notice != null && !_opened.isClosed) _opened.add(notice);
  }

  void _openPayload(String? payload) {
    if (payload == null) return;
    try {
      _openData(Map<String, dynamic>.from(jsonDecode(payload) as Map));
    } catch (_) {}
  }

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    var phase = 'firebase';
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: firebaseOptionsFromEnvironment());
      }
      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(mareaBackgroundMessage);
      phase = 'local_notifications';
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_marea_notification'),
        ),
        onDidReceiveNotificationResponse: (r) => _openPayload(r.payload),
      );
      final android = _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      phase = 'channels';
      await android?.createNotificationChannel(_channel);
      await android?.createNotificationChannel(_mareaChannel);
      _subscriptions.add(_messaging!.onTokenRefresh.listen(_tokens.add));
      _subscriptions.add(
        FirebaseMessaging.onMessageOpenedApp.listen((m) => _openData(m.data)),
      );
      _subscriptions.add(
        FirebaseMessaging.onMessage.listen((message) {
          final notice = PushNotice.fromData(message.data);
          if (notice != null) {
            _received.add(
              ForegroundNotice(
                notice: notice,
                version: message.data['event_version']?.toString() ?? '',
                kind: message.data['kind']?.toString() ?? '',
                title: message.notification?.title ?? 'MAREA',
                body:
                    message.notification?.body ??
                    'Hay novedades en tu comunidad.',
              ),
            );
          }
        }),
      );
      phase = 'initial_message';
      final initial = await _messaging!.getInitialMessage();
      if (initial != null) _openData(initial.data);
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        _openPayload(launch?.notificationResponse?.payload);
      }
      _initialized = true;
      return true;
    } catch (error) {
      if (kDebugMode) {
        final code = error is PlatformException
            ? error.code
            : error.runtimeType;
        debugPrint('MAREA push initialization: $phase ($code)');
      }
      for (final subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();
      _messaging = null;
      return false;
    }
  }

  @override
  Future<PushPermission> permission() async {
    if (_messaging == null) return PushPermission.unavailable;
    final settings = await _messaging!.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional
        ? PushPermission.granted
        : PushPermission.denied;
  }

  @override
  Future<PushPermission> promptOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('marea.push.permissionAsked') == true) {
      return permission();
    }
    final result = await requestPermission();
    await prefs.setBool('marea.push.permissionAsked', true);
    return result;
  }

  @override
  Future<PushPermission> requestPermission() async {
    await _messaging?.requestPermission();
    return permission();
  }

  @override
  Future<void> openSettings() => const MethodChannel(
    'marea/notifications',
  ).invokeMethod<void>('openSettings');
  @override
  Future<String?> token() async {
    if (await permission() != PushPermission.granted) return null;
    await _messaging?.setAutoInitEnabled(true);
    return _messaging?.getToken();
  }

  @override
  Future<String> installationId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('marea.push.installation');
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString('marea.push.installation', id);
    }
    return id;
  }

  @override
  Future<String> timezone() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;
  @override
  Future<void> present(ForegroundNotice message) async {
    final marea = message.kind == 'marea_message';
    final channel = marea ? _mareaChannel : _channel;
    // A stable tag replaces retries of the same event in the Android tray.
    await _local.show(
      id: 0,
      title: message.title,
      body: message.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'ic_marea_notification',
          tag: message.notice.notificationId,
          importance: channel.importance,
          priority: marea ? Priority.defaultPriority : Priority.high,
          onlyAlertOnce: true,
        ),
      ),
      payload: jsonEncode({
        'notification_id': message.notice.notificationId,
        'recipient_id': message.notice.recipientId,
      }),
    );
  }

  @override
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('marea.push.installation');
    try {
      await _messaging?.setAutoInitEnabled(false);
      await _messaging?.deleteToken();
    } finally {
      await _local.cancelAll();
    }
  }

  @override
  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _opened.close();
    await _received.close();
    await _tokens.close();
  }
}
