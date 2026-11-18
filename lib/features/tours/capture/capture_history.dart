import 'dart:convert';
import '../data/tour_local_store.dart';
import '../models/tour_models.dart';

/// Keeps previous local capture sessions, reusing their original JPEG files.
class CaptureHistory {
  CaptureHistory(this.store);
  final TourLocalStore store;
  String _index(String scene) => 'capture-history-$scene';

  Future<void> archive(
    String account,
    String scene,
    Map<String, dynamic> session, {
    required bool Function() isCurrent,
  }) async {
    if ((session['frames'] as List? ?? const []).isEmpty) return;
    void check() {
      if (!isCurrent()) throw StateError('La sesión cambió.');
    }

    check();
    final copy = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(session)) as Map,
    );
    final key = 'capture-archive-${tourId()}';
    final entry = {
      'key': key,
      'account': account,
      'scene': scene,
      'saved_at': DateTime.now().toUtc().toIso8601String(),
      'session': copy,
    };
    await store.write(account, key, entry);
    check();
    final index = await store.read(account, _index(scene));
    check();
    final keys = (index?['keys'] as List? ?? const [])
        .whereType<String>()
        .toList();
    await store.write(account, _index(scene), {
      'keys': [key, ...keys],
    });
    check();
  }

  Future<List<Map<String, dynamic>>> list(
    String account,
    String scene, {
    required bool Function() isCurrent,
  }) async {
    final index = await store.read(account, _index(scene));
    if (!isCurrent()) return [];
    final entries = <Map<String, dynamic>>[];
    for (final key
        in (index?['keys'] as List? ?? const []).whereType<String>()) {
      if (!RegExp(r'^capture-archive-[a-f0-9-]{36}$').hasMatch(key)) continue;
      final entry = await store.read(account, key);
      if (!isCurrent()) return [];
      if (entry?['account'] == account &&
          entry?['scene'] == scene &&
          entry?['session'] is Map) {
        entries.add(entry!);
      }
    }
    return entries;
  }
}
