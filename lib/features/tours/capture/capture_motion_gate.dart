import '../models/tour_models.dart';
import 'capture_plan.dart';

/// Requires recent, continuous orientation samples before accepting a photo.
class CaptureMotionGate {
  static const _freshFor = Duration(milliseconds: 300);
  static const _steadyFor = Duration(milliseconds: 500);

  CaptureTarget? _target;
  double? _yaw, _pitch;
  DateTime? _lastMotion, _stableSince;
  bool _aimed = false;

  bool get aimed => _aimed;

  bool isFresh(DateTime now) {
    final last = _lastMotion;
    if (last == null) return false;
    final elapsed = now.difference(last);
    return !elapsed.isNegative && elapsed < _freshFor;
  }

  bool isSteady(DateTime now) {
    final since = _stableSince;
    if (!_aimed || since == null || !isFresh(now)) return false;
    return now.difference(since) >= _steadyFor;
  }

  void update({
    required double yaw,
    required double pitch,
    required CaptureTarget? target,
    required DateTime now,
  }) {
    if (!yaw.isFinite ||
        !pitch.isFinite ||
        (target != null && (!target.yaw.isFinite || !target.pitch.isFinite))) {
      reset();
      return;
    }

    final targetChanged =
        _target?.id != target?.id ||
        _target?.yaw != target?.yaw ||
        _target?.pitch != target?.pitch;
    final continuous = isFresh(now);
    final moved =
        _yaw != null && angularDistance(_yaw!, _pitch!, yaw, pitch) > 1.5;
    final aimed =
        target != null &&
        angularDistance(yaw, pitch, target.yaw, target.pitch) < 6;

    if (!aimed) {
      _stableSince = null;
    } else if (!continuous ||
        targetChanged ||
        !_aimed ||
        moved ||
        _stableSince == null) {
      _stableSince = now;
    }
    _target = target;
    _yaw = yaw;
    _pitch = pitch;
    _lastMotion = now;
    _aimed = aimed;
  }

  void reset() {
    _target = null;
    _yaw = null;
    _pitch = null;
    _lastMotion = null;
    _stableSince = null;
    _aimed = false;
  }
}
