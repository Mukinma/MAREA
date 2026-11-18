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
  static const maxTargets = 40;
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
    // Equatorial start, complete polar coverage and at least 25% vertical
    // overlap. Horizontal rings start at 30% overlap. The older plan used 45%
    // in both axes, multiplying the number of rows and shots unnecessarily.
    var firstSteps = (180 / (vfov * .75)).ceil();
    if (firstSteps.isOdd) firstSteps++;
    final candidates = <List<CaptureTarget>>[];
    for (var steps = firstSteps; steps <= 18; steps += 2) {
      for (final spacing in [.70, .65, .60]) {
        for (final stagger in [false, true]) {
          final targets = <CaptureTarget>[];
          for (var row = 0; row <= steps; row++) {
            final pitch = -90.0 + row * 180 / steps;
            final count = pitch.abs() == 90
                ? 1
                : (360 * math.cos(pitch * math.pi / 180) / (hfov * spacing))
                      .ceil();
            for (var i = 0; i < count; i++) {
              final offset = stagger && row.isOdd && pitch != 0 ? .5 : 0.0;
              targets.add(
                CaptureTarget(
                  '${pitch.toStringAsFixed(3)}:$i',
                  normalizeYaw((i + offset) * 360 / count),
                  pitch,
                ),
              );
            }
            if (targets.length > maxTargets) break;
          }
          if (targets.length <= maxTargets) candidates.add(targets);
        }
      }
    }
    candidates.sort((a, b) => a.length.compareTo(b.length));
    for (final targets in candidates) {
      if (_coversSphere(targets, hfov, vfov)) {
        targets.sort((a, b) {
          final ring = a.pitch.abs().compareTo(b.pitch.abs());
          if (ring != 0) return ring;
          final side = a.pitch.compareTo(b.pitch);
          if (side != 0) return side;
          // Begin each ring in the forward direction, then turn continuously.
          return ((a.yaw + 360) % 360).compareTo((b.yaw + 360) % 360);
        });
        return CapturePlan(hfov, vfov, targets);
      }
    }
    throw StateError(
      'Con esta lente no pudimos cubrir una esfera con un máximo de 40 tomas. '
      'Usa una cámara de mayor ángulo o importa un panorama 360°.',
    );
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

// A rectangular rectilinear JPEG is not a circular spherical cap. Validate
// against its four great-circle image boundaries, including corner regions.
// Every 1° grid sample has >=1.1° inside-edge clearance; every sphere point is
// within <=1° of a sample (latitude + longitude distance). Thus the nominal
// footprints cover the entire sphere, not just the sampled directions.
// Real accepted poses/optics still require the worker's alpha/feature checks.
bool _coversSphere(List<CaptureTarget> targets, double hfov, double vfov) {
  final footprints = targets.map(_Footprint.new).toList();
  final h = hfov * math.pi / 360, v = vfov * math.pi / 360;
  final sh = math.sin(h), ch = math.cos(h);
  final sv = math.sin(v), cv = math.cos(v);
  final clearance = math.sin(1.1 * math.pi / 180);
  for (final elevation in _elevations) {
    for (final azimuth in _azimuths) {
      final x = elevation.$1 * azimuth.$1;
      final y = elevation.$1 * azimuth.$2;
      final z = elevation.$2;
      var covered = false;
      for (final f in footprints) {
        final forward = f.fx * x + f.fy * y + f.fz * z;
        if (forward <= 0) continue;
        final right = f.rx * x + f.ry * y;
        final up = f.ux * x + f.uy * y + f.uz * z;
        if (sh * forward - ch * right.abs() >= clearance &&
            sv * forward - cv * up.abs() >= clearance) {
          covered = true;
          break;
        }
      }
      if (!covered) return false;
    }
  }
  return true;
}

final _azimuths = [
  for (var degrees = -180; degrees < 180; degrees++)
    (math.cos(degrees * math.pi / 180), math.sin(degrees * math.pi / 180)),
];
final _elevations = [
  for (var degrees = -90; degrees <= 90; degrees++)
    (math.cos(degrees * math.pi / 180), math.sin(degrees * math.pi / 180)),
];

class _Footprint {
  _Footprint(CaptureTarget target) {
    final yaw = target.yaw * math.pi / 180;
    final pitch = target.pitch * math.pi / 180;
    final cy = math.cos(yaw), sy = math.sin(yaw);
    final cp = math.cos(pitch), sp = math.sin(pitch);
    fx = cp * cy;
    fy = cp * sy;
    fz = sp;
    rx = -sy;
    ry = cy;
    ux = -sp * cy;
    uy = -sp * sy;
    uz = cp;
  }
  late final double fx, fy, fz, rx, ry, ux, uy, uz;
}
