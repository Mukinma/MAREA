import 'dart:math' as math;

import '../models/proximity_models.dart';

/// An entry detector; it does not request permissions, fetch or send notices.
class ProximityEngine {
  ProximityEngine({Duration cooldown = const Duration(minutes: 5)})
    : cooldown = cooldown < const Duration(minutes: 5)
          ? const Duration(minutes: 5)
          : cooldown;

  static const entryMeters = 20.0;
  static const exitMeters = 30.0;
  static const maxAccuracyMeters = 20.0;
  static const maxFixAge = Duration(seconds: 30);

  final Duration cooldown;
  final _states = <String, _TargetState>{};
  DateTime? _lastFix;

  bool acceptsFix(ProximityFix fix, {required DateTime now}) {
    final age = now.difference(fix.timestamp);
    return validProximityCoordinates(fix.latitude, fix.longitude) &&
        fix.accuracy.isFinite &&
        fix.accuracy >= 0 &&
        fix.accuracy <= maxAccuracyMeters &&
        !age.isNegative &&
        age <= maxFixAge &&
        (_lastFix == null || !fix.timestamp.isBefore(_lastFix!));
  }

  List<ProximityEncounter> update({
    required Iterable<ProximityTarget> targets,
    required ProximityFix fix,
    required DateTime now,
  }) {
    if (!acceptsFix(fix, now: now)) return const [];
    _lastFix = fix.timestamp;
    final encounters = <ProximityEncounter>[];
    final seen = <String>{};
    for (final target in targets) {
      if (!target.isValid ||
          (target.expiresAt != null && !now.isBefore(target.expiresAt!)) ||
          !seen.add(target.key)) {
        continue;
      }
      // Match Android's unrounded Haversine calculation. The epsilon only
      // absorbs floating point noise at an exact boundary (below a micron).
      final distance = distanceMeters(
        fix.latitude,
        fix.longitude,
        target.latitude,
        target.longitude,
      );
      if (!distance.isFinite) continue;
      final state = _states.putIfAbsent(target.key, _TargetState.new);
      if (distance >= exitMeters - 1e-7) {
        state.inside = false;
      } else if (distance <= entryMeters + 1e-7 && !state.inside) {
        state.inside = true;
        final lastNotice = state.lastNotice;
        if (lastNotice == null || now.difference(lastNotice) >= cooldown) {
          state.lastNotice = now;
          encounters.add(
            ProximityEncounter(
              target: target,
              distanceMeters: distance,
              occurredAt: now,
            ),
          );
        }
      }
    }
    return List.unmodifiable(encounters);
  }

  void reset() {
    _states.clear();
    _lastFix = null;
  }

  static double distanceMeters(double a, double b, double c, double d) {
    final dy = (c - a) * math.pi / 180;
    final dx = (d - b) * math.pi / 180;
    final h =
        math.pow(math.sin(dy / 2), 2) +
        math.cos(a * math.pi / 180) *
            math.cos(c * math.pi / 180) *
            math.pow(math.sin(dx / 2), 2);
    return 6371000 * 2 * math.asin(math.sqrt(h.clamp(0, 1)));
  }
}

class _TargetState {
  bool inside = false;
  DateTime? lastNotice;
}
