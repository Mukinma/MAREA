import '../models/tour_models.dart';
import 'capture_plan.dart';

/// Whether an actual photo has the pose and lens data required by the worker.
/// Legacy photos have no status; new photos must explicitly have a usable pose.
/// IDs, storage paths and actual JPEG contents are still checked on the server.
bool canProcessCaptureFrame(Map<String, dynamic> frame) {
  if (frame.containsKey('pose_status') && frame['pose_status'] != 'ready') {
    return false;
  }
  final width = frame['width'], height = frame['height'];
  if (width is! int ||
      height is! int ||
      width < 64 ||
      height < 64 ||
      width > 24000 ||
      height > 24000 ||
      width * height > 120000000) {
    return false;
  }
  return _within(frame['yaw'], -180, 179.999999) &&
      _within(frame['pitch'], -90, 90) &&
      _within(frame['roll'], -180, 180) &&
      _within(frame['hfov'], 1, 179, exclusiveMaximum: true) &&
      _within(frame['vfov'], 1, 179, exclusiveMaximum: true);
}

/// Retains the original maps, including mutable resumable-upload checkpoints.
List<Map<String, dynamic>> processableCaptureFrames(List<dynamic> frames) => [
  for (final frame in frames)
    if (frame is Map<String, dynamic> && canProcessCaptureFrame(frame)) frame,
];

/// Finds the nearest still-pending guide direction, without requiring steadiness.
/// Photos outside the guide remain valid photos but complete no guide target.
CaptureTarget? findCaptureTarget({
  required CapturePlan? plan,
  required List<dynamic> frames,
  required double yaw,
  required double pitch,
}) {
  if (plan == null || !yaw.isFinite || !_within(pitch, -90, 90)) {
    return null;
  }
  final completed = {
    for (final frame in processableCaptureFrames(frames)) frame['target_id'],
  };
  CaptureTarget? nearest;
  var bestDistance = 6.0;
  for (final target in plan.targets) {
    if (completed.contains(target.id) ||
        !target.yaw.isFinite ||
        !_within(target.pitch, -90, 90)) {
      continue;
    }
    final distance = angularDistance(yaw, pitch, target.yaw, target.pitch);
    if (distance < bestDistance) {
      nearest = target;
      bestDistance = distance;
    }
  }
  return nearest;
}

/// Rebases only measured poses from the current native motion session.
/// Every map is copied so callers can roll back a failed local save. Other
/// sessions and photos without real sensor data remain unchanged and local.
List<Map<String, dynamic>> alignCaptureFrames(
  List<dynamic> frames, {
  required String motionSession,
  required double yawOffset,
  required CapturePlan? plan,
}) {
  if (!yawOffset.isFinite) {
    throw ArgumentError.value(yawOffset, 'yawOffset', 'Debe ser finito.');
  }
  final result = [
    for (final frame in frames) Map<String, dynamic>.from(frame as Map),
  ];
  if (motionSession.isEmpty) return result;
  final aligned = <Map<String, dynamic>>[];
  for (final frame in result) {
    final rawYaw = frame['sensor_yaw'];
    if (frame['pose_session'] != motionSession ||
        rawYaw is! num ||
        !rawYaw.isFinite ||
        !(rawYaw + yawOffset).isFinite) {
      continue;
    }
    final candidate = {
      ...frame,
      'yaw': normalizeYaw(rawYaw + yawOffset),
      'pose_status': 'ready',
    };
    if (!canProcessCaptureFrame(candidate)) continue;
    frame
      ..addAll(candidate)
      ..remove('target_id');
    aligned.add(frame);
  }
  // Clear old assignments for the entire rebased segment before choosing new
  // targets. Earlier photos and already-rebased photos retain their claims.
  for (final frame in aligned) {
    final target = findCaptureTarget(
      plan: plan,
      frames: result,
      yaw: (frame['yaw'] as num).toDouble(),
      pitch: (frame['pitch'] as num).toDouble(),
    );
    if (target != null) frame['target_id'] = target.id;
  }
  return result;
}

bool _within(
  dynamic value,
  double minimum,
  double maximum, {
  bool exclusiveMaximum = false,
}) =>
    value is num &&
    value.isFinite &&
    value >= minimum &&
    (exclusiveMaximum ? value < maximum : value <= maximum);
