import 'dart:math' as math;
import '../models/tour_models.dart';

class CaptureTarget {
  const CaptureTarget(this.id, this.yaw, this.pitch);
  final String id;
  final double yaw, pitch;
  Map<String, dynamic> toJson() => {'id': id, 'yaw': yaw, 'pitch': pitch};
}

class CapturePlan {
  CapturePlan(this.hfov, this.vfov, this.targets);
  final double hfov, vfov;
  final List<CaptureTarget> targets;
  void checkLens({required double hfov, required double vfov}) {
    if (!hfov.isFinite ||
        !vfov.isFinite ||
        (this.hfov - hfov).abs() > 1 ||
        (this.vfov - vfov).abs() > 1) {
      throw StateError(
        'La lente cambió desde la primera toma. Usa la misma cámara o empieza otra captura.',
      );
    }
  }

  factory CapturePlan.create({required double hfov, required double vfov}) {
    if (!hfov.isFinite ||
        !vfov.isFinite ||
        hfov < 20 ||
        vfov < 20 ||
        hfov > 120 ||
        vfov > 120) {
      throw StateError(
        'No pudimos conocer la lente. Puedes importar un panorama 360°.',
      );
    }
    final steps = (180 / (vfov * .55)).ceil();
    final pitches = List.generate(steps + 1, (i) => -90.0 + i * 180 / steps)
      ..sort((a, b) => a.abs().compareTo(b.abs()));
    final targets = <CaptureTarget>[];
    for (final pitch in pitches) {
      final count = pitch.abs() == 90
          ? 1
          : (360 * math.cos(pitch * math.pi / 180) / (hfov * .55)).ceil().clamp(
              1,
              96,
            );
      for (var i = 0; i < count; i++) {
        targets.add(
          CaptureTarget(
            '${pitch.toStringAsFixed(3)}:$i',
            normalizeYaw(i * 360 / count),
            pitch,
          ),
        );
      }
    }
    if (targets.length > 96) {
      throw StateError(
        'Esta lente requiere demasiadas tomas. Usa la cámara principal o importa una esfera completa.',
      );
    }
    return CapturePlan(hfov, vfov, targets);
  }
  factory CapturePlan.fromJson(Map<String, dynamic> json) => CapturePlan(
    (json['hfov'] as num).toDouble(),
    (json['vfov'] as num).toDouble(),
    (json['targets'] as List)
        .map(
          (t) => CaptureTarget(
            t['id'] as String,
            (t['yaw'] as num).toDouble(),
            (t['pitch'] as num).toDouble(),
          ),
        )
        .toList(),
  );
  Map<String, dynamic> toJson() => {
    'hfov': hfov,
    'vfov': vfov,
    'targets': targets.map((t) => t.toJson()).toList(),
  };
}
