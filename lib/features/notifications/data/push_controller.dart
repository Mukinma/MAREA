import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/notification_preferences.dart';
import '../models/notification_destination.dart';
import 'notification_preferences_repository.dart';
import 'push_gateway.dart';

class PushController extends ChangeNotifier with WidgetsBindingObserver {
  PushController(this.repository, this.gateway) {
    WidgetsBinding.instance.addObserver(this);
    _subscriptions.add(
      gateway.opened.listen((notice) {
        _pending = notice;
        if (!_disposed) notifyListeners();
      }),
    );
    _subscriptions.add(
      gateway.tokenChanges.listen((token) => unawaited(_register(token))),
    );
    _subscriptions.add(
      gateway.received.listen((message) => unawaited(_present(message))),
    );
  }
  final NotificationPreferencesRepository repository;
  final PushGateway gateway;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _seen = <String>{};
  Future<bool>? _initialization;
  Future<void>? _deviceWork;
  Timer? _activityTimer;
  bool _resetPending = false;
  String? _userId;
  bool _ready = false, _disposed = false;
  int _generation = 0;
  PushNotice? _pending;
  NotificationPreferences preferences = const NotificationPreferences();
  bool preferencesLoaded = false;
  PushPermission permissionStatus = PushPermission.unavailable;
  bool busy = false, configured = false;
  String? error;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _current(int generation) =>
      !_disposed && generation == _generation && _userId != null && _ready;

  Future<void> setSession(String? userId, {required bool ready}) async {
    if (_userId == userId && _ready == ready && _initialization != null) return;
    final lostSession = _userId != null && _userId != userId;
    _userId = userId;
    _ready = ready;
    _activityTimer?.cancel();
    if (lostSession) {
      _pending = null;
      _queueReset(revoke: false);
    }
    permissionStatus = PushPermission.unavailable;
    final generation = ++_generation;
    preferences = const NotificationPreferences();
    preferencesLoaded = false;
    error = null;
    busy = userId != null && ready;
    _seen.clear();
    _notify();
    try {
      await _deviceWork?.timeout(const Duration(seconds: 10));
      if (!_current(generation)) return;
      if (_resetPending) {
        _queueReset(revoke: false);
        await _deviceWork?.timeout(const Duration(seconds: 10));
        if (!_current(generation)) return;
        if (_resetPending) throw StateError('push_reset_failed');
      }
      configured = await (_initialization ??= gateway.initialize());
      if (!_current(generation)) return;
      final loaded = await repository.load();
      if (!_current(generation)) return;
      preferences = loaded;
      preferencesLoaded = true;
      await _recordActivity(generation);
      if (!_current(generation)) return;
      _activityTimer = Timer.periodic(const Duration(minutes: 15), (_) {
        if (WidgetsBinding.instance.lifecycleState ==
            AppLifecycleState.resumed) {
          unawaited(_recordActivity(generation).catchError((Object _) {}));
        }
      });
      if (configured) {
        final permission = await gateway.promptOnce();
        if (!_current(generation)) return;
        permissionStatus = permission;
        await _register(null, generation: generation);
      }
    } catch (_) {
      if (_current(generation)) {
        error = 'No pudimos configurar los avisos. Puedes reintentar.';
      }
    } finally {
      if (generation == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> _register(String? token, {int? generation}) async {
    final revision = generation ?? _generation;
    if (!_current(revision) || !configured) return;
    final previous = _deviceWork ?? Future<void>.value();
    final work = previous
        .then((_) async {
          if (!_current(revision)) return;
          final installation = await gateway.installationId();
          if (!_current(revision)) return;
          if (permissionStatus != PushPermission.granted) {
            await repository.unregisterDevice(installation);
          } else {
            final currentToken = token ?? await gateway.token();
            if (_current(revision) && currentToken != null) {
              await repository.registerDevice(installation, currentToken, true);
            }
          }
        })
        .catchError((Object _) {
          if (_current(revision)) {
            error = 'No pudimos registrar este dispositivo. Puedes reintentar.';
            _notify();
          }
        });
    _deviceWork = work;
    try {
      await work.timeout(const Duration(seconds: 10));
    } catch (_) {
      if (_current(revision)) {
        error = 'No pudimos registrar este dispositivo. Puedes reintentar.';
        _notify();
      }
    }
  }

  Future<void> _present(ForegroundNotice message) async {
    if (_disposed ||
        !_ready ||
        !preferencesLoaded ||
        _userId != message.notice.recipientId ||
        permissionStatus != PushPermission.granted) {
      return;
    }
    final generation = _generation;
    final key = '${message.notice.notificationId}:${message.version}';
    if (!_seen.add(key)) return;
    if (_seen.length > 200) _seen.remove(_seen.first);
    try {
      var category =
          message.category ?? NotificationCategory.fromEvent(message.kind);
      if (category == null && message.kind == 'marea_message') {
        // An older worker sent both chat and editorial reminders under the
        // same kind. Resolve the event only if the inbox row still matches.
        final event = await repository.notification(
          message.notice.notificationId,
        );
        if (event == null ||
            event.recipientId != message.notice.recipientId ||
            event.isUnread == false ||
            event.createdAt != DateTime.tryParse(message.version)) {
          return;
        }
        category = NotificationCategory.fromEvent(
          event.kind.databaseValue,
          eventKey: event.eventKey,
        );
      }
      if (!_current(generation) ||
          permissionStatus != PushPermission.granted ||
          category == null ||
          !preferences.isEnabled(category)) {
        return;
      }
      await gateway.present(message.withCategory(category));
    } catch (_) {
      if (_current(generation)) _seen.remove(key);
    }
  }

  Future<void> refresh({bool requestPermission = false}) async {
    if (_userId == null || !_ready || busy) return;
    final generation = _generation;
    busy = true;
    error = null;
    _notify();
    try {
      // On Web the prompt must run directly from the settings button gesture.
      final requested = requestPermission && configured
          ? await gateway.requestPermission()
          : null;
      if (!_current(generation)) return;
      await _deviceWork?.timeout(const Duration(seconds: 10));
      if (!_current(generation)) return;
      if (_resetPending) {
        _queueReset(revoke: false);
        await _deviceWork?.timeout(const Duration(seconds: 10));
        if (!_current(generation)) return;
        if (_resetPending) throw StateError('push_reset_failed');
      }
      if (!configured) {
        configured = await (_initialization = gateway.initialize());
      }
      if (!_current(generation)) return;
      final p = await repository.load();
      if (!_current(generation)) return;
      preferences = p;
      preferencesLoaded = true;
      await _recordActivity(generation);
      if (!_current(generation) || !configured) return;
      final permission = requested ?? await gateway.promptOnce();
      if (!_current(generation)) return;
      permissionStatus = permission;
      await _register(null, generation: generation);
    } catch (_) {
      if (_current(generation)) {
        error = 'No pudimos actualizar los avisos. Puedes reintentar.';
      }
    } finally {
      if (generation == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> setCategory(NotificationCategory category, bool enabled) async {
    if (_userId == null || !_ready || busy || !preferencesLoaded) return;
    final generation = _generation;
    final before = preferences;
    preferences = before.withCategory(category, enabled);
    busy = true;
    error = null;
    _notify();
    try {
      final saved = await repository.setCategory(category, enabled);
      if (_current(generation)) preferences = saved;
    } catch (_) {
      if (_current(generation)) {
        preferences = before;
        error = 'No pudimos guardar tus preferencias.';
      }
    } finally {
      if (generation == _generation) {
        busy = false;
        _notify();
      }
    }
  }

  PushNotice? takePending(String userId) {
    final notice = _pending;
    if (notice == null) return null;
    _pending = null;
    return notice.recipientId == userId ? notice : null;
  }

  Future<void> _recordActivity(int generation) async {
    final zone = await gateway.timezone();
    if (_current(generation)) await repository.recordActivity(zone);
  }

  void _queueReset({required bool revoke}) {
    final previous = _deviceWork ?? Future<void>.value();
    _resetPending = true;
    _deviceWork = previous.then((_) async {
      // Revocation is best effort; losing network must not trap a user in a session.
      if (revoke && configured) {
        try {
          await repository
              .unregisterDevice(await gateway.installationId())
              .timeout(const Duration(seconds: 5));
        } catch (_) {}
      }
      try {
        await gateway.reset();
        _resetPending = false;
      } catch (_) {
        // Retry before registering a new account, so it cannot reuse the old association.
      }
    });
  }

  /// Called while the old authenticated session can still revoke its device.
  Future<void> endSession() async {
    final hadSession = _userId != null;
    _userId = null;
    _ready = false;
    ++_generation;
    _pending = null;
    _activityTimer?.cancel();
    _queueReset(revoke: hadSession);
    // Bound logout's wait, retaining the real future as a barrier for the next account.
    try {
      await _deviceWork?.timeout(const Duration(seconds: 5));
    } catch (_) {}
    preferences = const NotificationPreferences();
    preferencesLoaded = false;
    busy = false;
    _notify();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  @override
  void dispose() {
    _disposed = true;
    _activityTimer?.cancel();
    ++_generation;
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    unawaited(gateway.dispose());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
