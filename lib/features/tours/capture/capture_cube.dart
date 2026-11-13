import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'capture_cube_guide.dart';

/// Vector-drawn cube: its 3x3 faces turn towards the suggested capture side.
/// The animation travels from the face centre to the next suggested square.
class CaptureCube extends StatefulWidget {
  const CaptureCube({required this.step, this.completed = false, super.key});
  final CaptureCubeStep? step;
  final bool completed;
  @override
  State<CaptureCube> createState() => _CaptureCubeState();
}

class _CaptureCubeState extends State<CaptureCube>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  double _fromYaw = -.6, _toYaw = -.6, _fromPitch = .5, _toPitch = .5;
  double get _progress => Curves.easeInOutCubic.transform(_animation.value);

  @override
  void initState() {
    super.initState();
    _retarget();
  }

  void _retarget() {
    _fromYaw = _fromYaw + (_toYaw - _fromYaw) * _progress;
    _fromPitch = _fromPitch + (_toPitch - _fromPitch) * _progress;
    final step = widget.step;
    final yaw = -.6 - (step?.faceYaw ?? 0) * math.pi / 180;
    final delta = (yaw - _fromYaw + math.pi) % (2 * math.pi) - math.pi;
    _toYaw = _fromYaw + delta;
    _toPitch = step?.face == CaptureCubeFace.ceiling
        ? 1.3
        : step?.face == CaptureCubeFace.floor
        ? -1.3
        : .5;
    if (WidgetsBinding.instance.disableAnimations) {
      _animation.value = 1;
    } else {
      _animation.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(CaptureCube oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step?.target.id != widget.step?.target.id ||
        oldWidget.completed != widget.completed) {
      _retarget();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.completed
        ? 'Guía de cubo recorrida'
        : 'Cubo 3 por 3. ${widget.step?.faceLabel ?? 'Frente'}: ${widget.step?.zoneLabel ?? 'Centro'}. Referencia desde el centro.',
    image: true,
    child: ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, _) => CustomPaint(
          painter: _CubePainter(
            widget.step,
            widget.completed,
            _fromYaw + (_toYaw - _fromYaw) * _progress,
            _fromPitch + (_toPitch - _fromPitch) * _progress,
            _progress,
          ),
          size: const Size(100, 100),
        ),
      ),
    ),
  );
}

typedef _Point = ({double x, double y, double z});
_Point _point(double x, double y, double z) => (x: x, y: y, z: z);

class _CubeFace {
  const _CubeFace(this.normal, this.right, this.up, this.color);
  final _Point normal, right, up;
  final Color color;
}

class _CubePainter extends CustomPainter {
  _CubePainter(this.step, this.completed, this.yaw, this.pitch, this.progress);
  final CaptureCubeStep? step;
  final bool completed;
  final double yaw, pitch, progress;
  static const faces = [
    _CubeFace((x: 0, y: 0, z: 1), (x: 1, y: 0, z: 0), (
      x: 0,
      y: 1,
      z: 0,
    ), Color(0xFF007C91)),
    _CubeFace((x: 1, y: 0, z: 0), (x: 0, y: 0, z: -1), (
      x: 0,
      y: 1,
      z: 0,
    ), Color(0xFF4056A1)),
    _CubeFace((x: 0, y: 0, z: -1), (x: -1, y: 0, z: 0), (
      x: 0,
      y: 1,
      z: 0,
    ), Color(0xFF8057A3)),
    _CubeFace((x: -1, y: 0, z: 0), (x: 0, y: 0, z: 1), (
      x: 0,
      y: 1,
      z: 0,
    ), Color(0xFFBC6425)),
    _CubeFace((x: 0, y: 1, z: 0), (x: 1, y: 0, z: 0), (
      x: 0,
      y: 0,
      z: -1,
    ), Color(0xFF43855B)),
    _CubeFace((x: 0, y: -1, z: 0), (x: 1, y: 0, z: 0), (
      x: 0,
      y: 0,
      z: 1,
    ), Color(0xFFB24D70)),
  ];
  _Point rotate(_Point p) {
    final x = math.cos(yaw) * p.x + math.sin(yaw) * p.z;
    final z = -math.sin(yaw) * p.x + math.cos(yaw) * p.z;
    return _point(
      x,
      math.cos(pitch) * p.y - math.sin(pitch) * z,
      math.sin(pitch) * p.y + math.cos(pitch) * z,
    );
  }

  _Point onFace(_CubeFace f, double u, double v) => _point(
    f.normal.x + f.right.x * u + f.up.x * v,
    f.normal.y + f.right.y * u + f.up.y * v,
    f.normal.z + f.right.z * u + f.up.z * v,
  );
  Offset project(_Point point, Size size) {
    final p = rotate(point);
    final scale = math.min(size.width, size.height) * .30 * 4 / (4 - p.z);
    return Offset(size.width / 2 + p.x * scale, size.height / 2 - p.y * scale);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final order = List.generate(6, (i) => i)
      ..sort(
        (a, b) =>
            rotate(faces[a].normal).z.compareTo(rotate(faces[b].normal).z),
      );
    for (final index in order) {
      final face = faces[index];
      if (rotate(face.normal).z <= .04) continue;
      for (var row = 0; row < 3; row++) {
        for (var col = 0; col < 3; col++) {
          final u = -1 + col * 2 / 3, v = 1 - row * 2 / 3;
          final points = [
            onFace(face, u, v),
            onFace(face, u + 2 / 3, v),
            onFace(face, u + 2 / 3, v - 2 / 3),
            onFace(face, u, v - 2 / 3),
          ];
          final path = Path()
            ..addPolygon(points.map((p) => project(p, size)).toList(), true);
          final centre = row == 1 && col == 1;
          final active =
              !completed &&
              index == (step?.face.index ?? 0) &&
              row == (progress < .2 ? 1 : step?.row ?? 1) &&
              col == (progress < .2 ? 1 : step?.column ?? 1);
          canvas.drawPath(
            path,
            Paint()..color = active ? const Color(0xFFFFCE54) : face.color,
          );
          canvas.drawPath(
            path,
            Paint()
              ..color = const Color(0xFFFAFAFA)
              ..style = PaintingStyle.stroke
              ..strokeWidth = active ? 2.5 : 1.1,
          );
          if (centre && index == (step?.face.index ?? 0)) {
            final c = project(onFace(face, 0, 0), size);
            canvas.drawCircle(c, 3, Paint()..color = const Color(0xFF102147));
          }
        }
      }
      if (!completed && index == (step?.face.index ?? 0)) {
        final u = index >= 4
            ? 0.0
            : ((step?.localYaw ?? 0) / 45 * .9).clamp(-.9, .9);
        final v = index >= 4
            ? 0.0
            : ((step?.target.pitch ?? 0) / 60 * .9).clamp(-.9, .9);
        final origin = project(onFace(face, 0, 0), size);
        final pointer = project(onFace(face, u * progress, v * progress), size);
        canvas.drawLine(
          origin,
          pointer,
          Paint()
            ..color = const Color(0xFF102147)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(pointer, 3.5, Paint()..color = Colors.white);
        canvas.drawCircle(
          pointer,
          3.5,
          Paint()
            ..color = const Color(0xFF102147)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CubePainter old) =>
      old.step != step ||
      old.completed != completed ||
      old.yaw != yaw ||
      old.pitch != pitch ||
      old.progress != progress;
}
