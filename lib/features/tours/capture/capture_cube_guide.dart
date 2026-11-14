import '../models/tour_models.dart';
import 'capture_plan.dart';

enum CaptureCubeFace { front, right, back, left, ceiling, floor }

/// A suggested route, separate from measured poses and sphere coverage.
/// Taking a photo advances the suggestion, never validates its actual angle.
class CaptureCubeGuide {
  CaptureCubeGuide._(this.steps);
  static const version = 1;
  final List<CaptureCubeStep> steps;

  factory CaptureCubeGuide.forPlan(CapturePlan? plan) {
    if (plan != null && plan.targets.length > CapturePlan.maxTargets) {
      try {
        plan = CapturePlan.create(hfov: plan.hfov, vfov: plan.vfov);
      } on StateError {
        plan = null;
      }
    }
    final targets =
        plan?.targets ??
        [
          // A visual fallback when lens metadata is unavailable. These are
          // instructions only: no fallback angles are assigned to actual photos.
          for (final yaw in [0.0, 90.0, -180.0, -90.0])
            for (final pitch in [0.0, 45.0, -45.0])
              for (final offset in [0.0, 30.0, -30.0])
                CaptureTarget(
                  'cube:$yaw:$pitch:$offset',
                  normalizeYaw(yaw + offset),
                  pitch,
                ),
          const CaptureTarget('cube:ceiling', 0, 90),
          const CaptureTarget('cube:floor', 0, -90),
        ];
    final steps = targets.map(CaptureCubeStep.new).toList();
    steps.sort((a, b) {
      final face = a.face.index.compareTo(b.face.index);
      if (face != 0) return face;
      final row = _rowOrder(a.row).compareTo(_rowOrder(b.row));
      if (row != 0) return row;
      final column = _columnOrder(a.column).compareTo(_columnOrder(b.column));
      if (column != 0) return column;
      final centre = a.localYaw.abs().compareTo(b.localYaw.abs());
      return centre != 0 ? centre : a.target.id.compareTo(b.target.id);
    });
    return CaptureCubeGuide._(List.unmodifiable(steps));
  }

  static int _rowOrder(int row) => row == 1
      ? 0
      : row == 0
      ? 1
      : 2;
  static int _columnOrder(int column) => column == 1
      ? 0
      : column == 2
      ? 1
      : 2;

  Map<String, dynamic> toJson() => {
    'version': version,
    'targets': steps.map((step) => step.target.toJson()).toList(),
  };

  static CaptureCubeGuide? restore(dynamic data) {
    if (data is! Map ||
        data['version'] != version ||
        data['targets'] is! List) {
      return null;
    }
    final raw = data['targets'] as List;
    if (raw.isEmpty || raw.length > CapturePlan.maxTargets) return null;
    final ids = <String>{};
    final steps = <CaptureCubeStep>[];
    for (final item in raw) {
      if (item is! Map ||
          item['id'] is! String ||
          item['yaw'] is! num ||
          item['pitch'] is! num) {
        return null;
      }
      final id = item['id'] as String;
      final yaw = (item['yaw'] as num).toDouble(),
          pitch = (item['pitch'] as num).toDouble();
      if (id.isEmpty ||
          !ids.add(id) ||
          !yaw.isFinite ||
          !pitch.isFinite ||
          yaw < -180 ||
          yaw >= 180 ||
          pitch.abs() > 90) {
        return null;
      }
      steps.add(CaptureCubeStep(CaptureTarget(id, yaw, pitch)));
    }
    return CaptureCubeGuide._(List.unmodifiable(steps));
  }

  int nextIndex(List<dynamic> frames) {
    var next = 0;
    for (final frame in frames) {
      if (frame is! Map || frame['cube_guide_version'] != version) continue;
      final index = steps.indexWhere(
        (step) => step.target.id == frame['cube_guide_step'],
      );
      if (index >= next) next = index + 1;
    }
    return next;
  }
}

class CaptureCubeStep {
  CaptureCubeStep(this.target);
  final CaptureTarget target;
  CaptureCubeFace get face {
    if (target.pitch >= 85) return CaptureCubeFace.ceiling;
    if (target.pitch <= -85) return CaptureCubeFace.floor;
    final quadrant = ((normalizeYaw(target.yaw) / 90).round() % 4 + 4) % 4;
    return CaptureCubeFace.values[quadrant];
  }

  double get faceYaw => switch (face) {
    CaptureCubeFace.right => 90,
    CaptureCubeFace.back => -180,
    CaptureCubeFace.left => -90,
    _ => 0,
  };
  double get localYaw => normalizeYaw(target.yaw - faceYaw);
  int get row => face.index >= 4
      ? 1
      : target.pitch > 15
      ? 0
      : target.pitch < -15
      ? 2
      : 1;
  int get column => face.index >= 4
      ? 1
      : localYaw > 15
      ? 2
      : localYaw < -15
      ? 0
      : 1;
  String get faceLabel => switch (face) {
    CaptureCubeFace.front => 'Frente',
    CaptureCubeFace.right => 'Lado derecho',
    CaptureCubeFace.back => 'Detrás',
    CaptureCubeFace.left => 'Lado izquierdo',
    CaptureCubeFace.ceiling => 'Techo',
    CaptureCubeFace.floor => 'Piso',
  };
  String get zoneLabel {
    if (face.index >= 4) return 'Centro';
    final vertical = row == 0
        ? 'Arriba'
        : row == 2
        ? 'Abajo'
        : 'Centro';
    if (column == 1) return vertical;
    return '$vertical · ${column == 2 ? 'derecha' : 'izquierda'}';
  }

  String instruction({bool first = false}) {
    if (first) return 'Primero toma el frente, a la altura de tus ojos.';
    if (face == CaptureCubeFace.ceiling) {
      return 'Desde el mismo punto, apunta al techo.';
    }
    if (face == CaptureCubeFace.floor) {
      return 'Desde el mismo punto, apunta al piso.';
    }
    final vertical = row == 0
        ? 'hacia arriba'
        : row == 2
        ? 'hacia abajo'
        : 'a la altura de tus ojos';
    final side = column == 2
        ? ', a la derecha'
        : column == 0
        ? ', a la izquierda'
        : localYaw.abs() > 5
        ? ', un poco a la ${localYaw > 0 ? 'derecha' : 'izquierda'}'
        : '';
    return 'Desde el centro de este lado, toma $vertical$side.';
  }
}
