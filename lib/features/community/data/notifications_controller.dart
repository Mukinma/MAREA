import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:marea/features/community/data/social_repository.dart';

class NotificationsController extends ChangeNotifier
    with WidgetsBindingObserver {
  NotificationsController(this.repository) {
    WidgetsBinding.instance.addObserver(this);
  }
  final SocialRepository repository;
  StreamSubscription<void>? _subscription;
  String? _userId;
  int _generation = 0, _request = 0;
  bool _disposed = false;
  int unread = 0;
  String? error;
  void setSession(String? id) {
    if (_userId == id) return;
    _userId = id;
    ++_generation;
    unawaited(_subscription?.cancel());
    _subscription = null;
    unread = 0;
    error = null;
    if (id != null) {
      _subscription = repository
          .changes(id)
          .listen(
            (_) => refresh(),
            onError: (_) {
              error = 'No pudimos actualizar las notificaciones.';
              if (!_disposed) notifyListeners();
            },
          );
      unawaited(refresh());
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_userId == null || _disposed) return;
    final generation = _generation, request = ++_request;
    try {
      final count = await repository.unreadCount();
      if (_disposed || generation != _generation || request != _request) return;
      unread = count;
      error = null;
    } catch (_) {
      if (_disposed || generation != _generation || request != _request) return;
      error = 'No pudimos actualizar las notificaciones.';
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    unawaited(_subscription?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
