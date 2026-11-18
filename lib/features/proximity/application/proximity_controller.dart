import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/proximity_services.dart';
import '../models/proximity_models.dart';
import 'proximity_engine.dart';

/// Opt-in monitoring owned by the app runtime, never a background service.
class ProximityController extends ChangeNotifier {
  ProximityController({
    required this.location,
    required this.targets,
    required this.notifications,
    ProximityEngine? engine,
    DateTime Function()? now,
  }) : _engine = engine ?? ProximityEngine(),
       _now = now ?? DateTime.now;

  final ProximityLocationSource location;
  final ProximityTargetSource targets;
  final ProximityNotificationSink notifications;
  final ProximityEngine _engine;
  final DateTime Function() _now;
  StreamSubscription<ProximityFix>? _subscription;
  Future<bool>? _activation;
  String? _accountId;
  bool _enabled = false, _foreground = false;
  bool _running = false, _starting = false, _disposed = false;
  int _generation = 0, _fixGeneration = 0;
  Object? _error;
  ProximityEncounter? _lastEncounter;

  String? get accountId => _accountId;
  bool get enabled => _enabled;
  bool get foreground => _foreground;
  bool get running => _running;
  bool get starting => _starting;
  Object? get error => _error;
  ProximityEncounter? get lastEncounter => _lastEncounter;

  bool _current(int generation, String account) =>
      !_disposed &&
      _enabled &&
      _foreground &&
      _generation == generation &&
      _accountId == account;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// This is the only operation that may ask for location permission.
  Future<bool> start({required String accountId}) async {
    if (_disposed || accountId.isEmpty) return false;
    if (_accountId != accountId) await setAccount(accountId);
    if (_disposed || _accountId != accountId) return false;
    _enabled = true;
    return _activate(requestPermission: true);
  }

  Future<bool> _activate({required bool requestPermission}) {
    if (_disposed || !_enabled || !_foreground || _accountId == null) {
      _notify();
      return Future.value(false);
    }
    if (_running) return Future.value(true);
    if (_starting) return _activation ?? Future.value(false);
    return _activation = _activateNow(requestPermission: requestPermission);
  }

  Future<bool> _activateNow({required bool requestPermission}) async {
    final generation = ++_generation;
    final account = _accountId!;
    bool current() => _current(generation, account);
    _starting = true;
    _error = null;
    _notify();
    try {
      await location.prepare(
        requestPermission: requestPermission,
        isCurrent: current,
      );
      if (!current()) return false;
      final subscription = location.watch().listen(
        (fix) => unawaited(_handleFix(fix, generation, account)),
        onError: (Object error) => _streamEnded(generation, account, error),
        onDone: () => _streamEnded(generation, account, null),
      );
      if (!current()) {
        await subscription.cancel();
        return false;
      }
      _subscription = subscription;
      _running = true;
      return true;
    } catch (error) {
      if (current()) _error = error;
      return false;
    } finally {
      if (!_disposed && generation == _generation) {
        _starting = false;
        _notify();
      }
    }
  }

  Future<void> _handleFix(
    ProximityFix fix,
    int generation,
    String account,
  ) async {
    bool current() => _current(generation, account);
    if (!current() || !_engine.acceptsFix(fix, now: _now())) return;
    final fixGeneration = ++_fixGeneration;
    try {
      final available = await targets.load(fix);
      if (!current() || fixGeneration != _fixGeneration) return;
      final entries = _engine.update(targets: available, fix: fix, now: _now());
      for (final entry in entries) {
        if (!current()) return;
        _lastEncounter = entry;
        _notify();
        await notifications.present(
          entry,
          accountId: account,
          isCurrent: current,
        );
      }
    } catch (error) {
      if (current() && fixGeneration == _fixGeneration) {
        _error = error;
        _notify();
      }
    }
  }

  void _streamEnded(int generation, String account, Object? error) {
    if (!_current(generation, account)) return;
    ++_generation;
    ++_fixGeneration;
    final subscription = _subscription;
    _subscription = null;
    _running = false;
    _starting = false;
    _error = error;
    if (subscription != null) unawaited(subscription.cancel());
    _notify();
  }

  Future<void> _stopListening() async {
    ++_generation;
    ++_fixGeneration;
    final subscription = _subscription;
    _subscription = null;
    _running = false;
    _starting = false;
    _notify();
    await subscription?.cancel();
  }

  /// Leaving the foreground stops GPS and discards in-flight work. Returning
  /// resumes an existing opt-in without presenting another permission prompt.
  Future<void> setForeground(bool foreground) async {
    if (_disposed || _foreground == foreground) return;
    _foreground = foreground;
    if (foreground && _enabled) {
      await _activate(requestPermission: false);
    } else {
      await _stopListening();
    }
  }

  /// Stops monitoring but retains hysteresis/cooldown for the same account.
  Future<void> stop() async {
    if (_disposed) return;
    _enabled = false;
    await _stopListening();
  }

  Future<void> setAccount(String? accountId) async {
    if (_disposed || _accountId == accountId) return;
    final previous = _accountId;
    _accountId = accountId;
    _enabled = false;
    _error = null;
    _lastEncounter = null;
    _engine.reset();
    await _stopListening();
    if (previous != null) await notifications.clearAccount(previous);
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    ++_fixGeneration;
    _enabled = false;
    _running = false;
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    _engine.reset();
    super.dispose();
  }
}
