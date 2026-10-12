import 'dart:convert';
import '../models/tour_models.dart';

class TourProgressPersistenceException implements Exception {
  const TourProgressPersistenceException();
}

/// Account/version scoped durable outbox. Network failure never discards progress.
class TourProgressStore {
  TourProgressStore({
    required this.account,
    required this.tourId,
    required this.revisionId,
    required this.read,
    required this.write,
    required this.sync,
  });
  final String account, tourId, revisionId;
  final Future<Map<String, dynamic>?> Function(String, String) read;
  final Future<void> Function(String, String, Map<String, dynamic>) write;
  final Future<TourProgress> Function(TourProgress?) sync;
  Future<void> _tail = Future.value();
  String get _key => 'progress-$tourId-$revisionId';

  Future<TourProgress> load() async {
    final local = await read(account, _key);
    final cached = local == null
        ? null
        : TourProgress.fromJson(revisionId, jsonMap(local['progress']));
    if (local?['pending'] == true && cached?.matches(revisionId) == true) {
      try {
        await save(cached!);
      } catch (_) {
        /* Durable retry on next visit. */
      }
      return cached!;
    }
    try {
      final remote = await sync(null);
      if (remote.matches(revisionId)) {
        await write(account, _key, {
          'progress': remote.toJson(),
          'pending': false,
        });
      }
      return remote;
    } catch (_) {
      if (cached != null && cached.matches(revisionId)) return cached;
      return TourProgress(revisionId: revisionId);
    }
  }

  Future<void> save(TourProgress value) {
    if (!value.matches(revisionId)) {
      return Future.error(StateError('La versión cambió.'));
    }
    final snapshot = TourProgress.fromJson(
      revisionId,
      jsonDecode(jsonEncode(value.toJson())) as Map<String, dynamic>,
    );
    final operation = _tail.then((_) async {
      try {
        await write(account, _key, {
          'progress': snapshot.toJson(),
          'pending': true,
        });
      } catch (_) {
        throw const TourProgressPersistenceException();
      }

      await sync(snapshot);
      await write(account, _key, {
        'progress': snapshot.toJson(),
        'pending': false,
      });
    });
    _tail = operation.catchError((Object _) {});
    return operation;
  }
}
