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
import 'package:geolocator/geolocator.dart';
import '../models/notification_destination.dart';
import '../models/notification_preferences.dart';
import 'push_configuration.dart';
import 'push_gateway.dart';
import 'web_push_stub.dart'
    if (dart.library.js_interop) 'web_push_browser.dart'
    as web_push;

@pragma('vm:entry-point')
Future<void> mareaBackgroundMessage(RemoteMessage message) async {
  // FCM displays background alert payloads. No duplicate local alert is needed.
}

class FirebasePushGateway implements PushGateway {
  FirebasePushGateway(this.configuration);

  final PushConfiguration configuration;
  bool get _ios => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
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
      final app = await Firebase.initializeApp(options: configuration.options);
      if (app.options.appId != configuration.options.appId ||
          app.options.projectId != configuration.options.projectId) {
        return false;
      }
      _messaging = FirebaseMessaging.instance;
      if (kIsWeb) {
        if (!await _messaging!.isSupported()) {
          _messaging = null;
          return false;
        }
        web_push.listen(_openPayload);
      } else {
        FirebaseMessaging.onBackgroundMessage(mareaBackgroundMessage);
        phase = 'local_notifications';
        await _initializeNativeAlerts();
        if (_ios) {
          await _messaging!.setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
        }
      }
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
                category: NotificationCategory.fromPayload(
                  message.data['category'],
                ),
                title:
                    message.notification?.title ??
                    message.data['title']?.toString() ??
                    'MAREA',
                body:
                    message.notification?.body ??
                    message.data['body']?.toString() ??
                    'Hay novedades en tu comunidad.',
              ),
            );
          }
        }),
      );
      phase = 'initial_message';
      final initial = await _messaging!.getInitialMessage();
      if (initial != null) _openData(initial.data);
      if (!kIsWeb) {
        final launch = await _local.getNotificationAppLaunchDetails();
        if (launch?.didNotificationLaunchApp == true) {
          _openPayload(launch?.notificationResponse?.payload);
        }
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

  Future<void> _initializeNativeAlerts() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_marea_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) => _openPayload(r.payload),
    );
    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_channel);
    await android?.createNotificationChannel(_mareaChannel);
  }

  @override
  Future<PushPermission> permission() async {
    if (_messaging == null) return PushPermission.unavailable;
    final settings = await _messaging!.getNotificationSettings();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => PushPermission.granted,
      AuthorizationStatus.notDetermined => PushPermission.notDetermined,
      AuthorizationStatus.denied => PushPermission.denied,
    };
  }

  @override
  Future<PushPermission> promptOnce() async {
    // Browsers require a user gesture before presenting their permission prompt.
    if (kIsWeb) return permission();
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
  Future<void> openSettings() async {
    if (_ios) {
      await Geolocator.openAppSettings();
    } else if (!kIsWeb) {
      await const MethodChannel(
        'marea/notifications',
      ).invokeMethod<void>('openSettings');
    }
  }

  @override
  Future<String?> token() async {
    if (await permission() != PushPermission.granted) return null;
    await _messaging?.setAutoInitEnabled(true);
    if (kIsWeb) {
      final options = configuration.options;
      final path = Uri(
        path: 'push/firebase-messaging-sw.js',
        queryParameters: {
          'apiKey': options.apiKey,
          'appId': options.appId,
          'messagingSenderId': options.messagingSenderId,
          'projectId': options.projectId,
        },
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('marea.push.tokenRequested', true);
      return _messaging?.getToken(
        vapidKey: configuration.vapidKey,
        serviceWorkerScriptPath: web_push.absoluteWorkerUrl(path.toString()),
      );
    }
    // APNs registration is asynchronous. onTokenRefresh also handles its arrival.
    if (_ios && await _messaging?.getAPNSToken() == null) return null;
    if (_ios) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('marea.push.tokenRequested', true);
    }
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
    final marea = message.category == NotificationCategory.reminders;
    final payload = jsonEncode({
      'notification_id': message.notice.notificationId,
      'recipient_id': message.notice.recipientId,
    });
    if (kIsWeb) {
      await web_push.show(message.title, message.body, payload, marea);
      return;
    }
    final channel = marea ? _mareaChannel : _channel;
    // A stable tag replaces retries of the same event in the Android tray.
    await _local.show(
      id: _ios
          ? int.parse(
                  message.notice.notificationId.substring(0, 8),
                  radix: 16,
                ) &
                0x3fffffff
          : 0,
      title: message.title,
      body: message.body,
      notificationDetails: NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentSound: !marea,
          threadIdentifier: message.category?.name,
          interruptionLevel: marea
              ? InterruptionLevel.passive
              : InterruptionLevel.active,
        ),
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
      payload: payload,
    );
  }

  @override
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('marea.push.installation');
    try {
      await _messaging?.setAutoInitEnabled(false);
      final requested = prefs.getBool('marea.push.tokenRequested') == true;
      // deleteToken would create a default browser worker or require an APNs
      // token even when this installation has never been able to subscribe.
      if (requested ||
          !kIsWeb && (!_ios || await _messaging?.getAPNSToken() != null)) {
        await _messaging?.deleteToken();
      }
      await prefs.remove('marea.push.tokenRequested');
    } finally {
      if (kIsWeb) {
        await web_push.clear();
      } else {
        await _local.cancelAll();
      }
    }
  }

  @override
  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    if (kIsWeb) web_push.stopListening();
    await _opened.close();
    await _received.close();
    await _tokens.close();
  }
}
