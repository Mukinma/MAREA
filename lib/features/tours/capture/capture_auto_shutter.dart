/// Coordinates automatic captures using the camera's real readiness signals.
///
/// The caller owns camera lifecycle, alignment and sensor freshness. This
/// coordinator never manufactures readiness or retries a failed photograph.
class CaptureAutoShutter {
  bool enabled = true;
  bool paused = false;
  bool _capturing = false;

  bool get capturing => _capturing;

  Future<void> tick({
    required bool active,
    required bool ready,
    required Future<void> Function() capture,
  }) async {
    if (!enabled || paused || _capturing || !active || !ready) return;
    _capturing = true;
    try {
      await capture();
    } catch (_) {
      paused = true;
      rethrow;
    } finally {
      _capturing = false;
    }
  }
}
