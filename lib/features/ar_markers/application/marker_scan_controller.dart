import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../tours/data/tour_local_store.dart';
import '../../tours/models/business_ar_target.dart';
import '../../tours/models/tour_models.dart' show tourId;
import '../data/marker_repository.dart';
import '../models/ar_marker.dart';

/// A native tracking callback is the only way to show the marker's content.
class MarkerScanController extends ChangeNotifier {
  MarkerScanController({
    required this.repository,
    required this.accountId,
    required this.markerId,
    required this.currentAccount,
    TourLocalStore? localStore,
    MethodChannel? channel,
    Stream<dynamic>? trackingEvents,
    DateTime Function()? now,
  }) : _store = localStore ?? TourLocalStore(),
       _channel = channel ?? const MethodChannel('marea/tour_ar'),
       _events =
           trackingEvents ??
           const EventChannel('marea/tour_ar/events').receiveBroadcastStream(),
       _now = now ?? DateTime.now;

  final MarkerRepository repository;
  final String accountId, markerId;
  final String? Function() currentAccount;
  final TourLocalStore _store;
  final MethodChannel _channel;
  final Stream<dynamic> _events;
  final DateTime Function() _now;
  static const freshness = Duration(milliseconds: 600);
  ArMarker? marker;
  Uint8List? image;
  bool supported = false, loading = false, scanning = false;
  String? error, sessionId;
  List<Map<String, dynamic>> references = [];
  dynamic quad;
  int _generation = 0;
  bool _disposed = false, _reporting = false, _proofAttempted = false;
  DateTime? _recognizedSince, _lastFrame;
  Timer? _watchdog;
  StreamSubscription<dynamic>? _subscription;
  bool get _current => !_disposed && currentAccount() == accountId;
  bool _valid(int generation) => _current && generation == _generation;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    await stop();
    final generation = _generation;
    if (!_current) return;
    loading = true;
    error = null;
    _changed();
    try {
      final record = await repository.get(accountId, markerId);
      if (!_valid(generation)) return;
      if (record == null) {
        throw StateError('Este marcador ya no está disponible.');
      }
      final bytes = await repository.loadImage(accountId, record);
      if (!_valid(generation)) return;
      var available = false;
      if (!kIsWeb) {
        try {
          available = await _channel.invokeMethod<bool>('supported') ?? false;
        } on MissingPluginException {
          available = false;
        }
      }
      if (!_valid(generation)) return;
      marker = record;
      image = bytes;
      supported = available;
    } catch (e) {
      if (_valid(generation)) error = _message(e);
    } finally {
      if (_valid(generation)) {
        loading = false;
        _changed();
      }
    }
  }

  Future<void> start() async {
    await load();
    if (!_current ||
        !supported ||
        marker == null ||
        image == null ||
        error != null) {
      return;
    }
    final generation = _generation;
    final record = marker!;
    loading = true;
    _changed();
    try {
      final path = await _store.saveBytes(
        accountId,
        'marker-${record.id}-${record.referenceVersion}',
        image!,
      );
      if (!_valid(generation)) return;
      final scanId = tourId();
      sessionId = scanId;
      _proofAttempted = false;
      references = [
        {'id': record.id, 'path': path, 'widthMeters': record.widthCm / 100},
      ];
      _subscription = _events.listen(
        (dynamic event) => _onFrame(event, generation, scanId, record),
        onError: (Object e) {
          if (_valid(generation)) {
            unawaited(stop());
            error = 'Se interrumpió la cámara. Puedes abrirla otra vez.';
            _changed();
          }
        },
      );
      scanning = true;
    } catch (e) {
      if (_valid(generation)) error = _message(e);
    } finally {
      if (_valid(generation)) {
        loading = false;
        _changed();
      }
    }
  }

  void _onFrame(dynamic event, int generation, String scanId, ArMarker record) {
    if (!_valid(generation) ||
        !scanning ||
        event is! Map ||
        event['sessionId'] != scanId) {
      return;
    }
    if (event['state'] == 'error') {
      unawaited(stop());
      error = 'No pudimos abrir la cámara. Reintenta.';
      _changed();
      return;
    }
    if (event['id'] != record.id) return;
    final tracked =
        event['state'] == 'tracking' &&
        arCardTransform(
              event['quad'],
              const Size(100, 100),
              const Size(200, 100),
            ) !=
            null;
    _watchdog?.cancel();
    final now = _now();
    final previous = _lastFrame;
    if (!tracked) {
      _forget();
      _changed();
      return;
    }
    if (previous == null ||
        now.difference(previous).isNegative ||
        now.difference(previous) > freshness) {
      _recognizedSince = now;
    }
    _lastFrame = now;
    quad = event['quad'];
    _watchdog = Timer(freshness, () {
      if (_valid(generation)) {
        _forget();
        _changed();
      }
    });
    _changed();
    final since = _recognizedSince;
    if (!_reporting &&
        !_proofAttempted &&
        record.ownerId == accountId &&
        marker?.isTested != true &&
        since != null &&
        now.difference(since) >= const Duration(seconds: 3)) {
      _proofAttempted = true;
      unawaited(_confirm(generation, record, now.difference(since).inSeconds));
    }
  }

  Future<void> _confirm(int generation, ArMarker record, int seconds) async {
    _reporting = true;
    try {
      final saved = await repository.confirmRecognition(
        accountId,
        record.id,
        record.referenceVersion,
        defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        seconds,
      );
      if (!_valid(generation)) return;
      if (saved.referenceVersion != record.referenceVersion) {
        await stop();
        error = 'La imagen cambió. Vuelve a abrir la cámara para reconocerla.';
      } else {
        marker = saved;
      }
    } catch (e) {
      if (_valid(generation)) error = _message(e);
    } finally {
      if (_valid(generation)) {
        _reporting = false;
        _changed();
      }
    }
  }

  void _forget() {
    quad = null;
    _lastFrame = null;
    _recognizedSince = null;
  }

  Future<void> stop() async {
    ++_generation;
    final oldSession = sessionId;
    sessionId = null;
    _watchdog?.cancel();
    _watchdog = null;
    _forget();
    scanning = false;
    loading = false;
    _reporting = false;
    references = [];
    final subscription = _subscription;
    _subscription = null;
    _changed();
    await subscription?.cancel();
    if (oldSession != null) {
      try {
        await _channel.invokeMethod<void>('stop', {'sessionId': oldSession});
      } catch (_) {}
    }
  }

  static String _message(Object error) => error is StateError
      ? error.message.toString()
      : 'No pudimos abrir este marcador. Reintenta.';

  @override
  void dispose() {
    _disposed = true;
    unawaited(stop());
    super.dispose();
  }
}
