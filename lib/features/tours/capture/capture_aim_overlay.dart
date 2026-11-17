import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/tour_models.dart';
import 'capture_plan.dart';

/// An advisory camera reticle. It never enables or disables the shutter.
class CaptureAimOverlay extends StatelessWidget {
  const CaptureAimOverlay({
    required this.target,
    required this.yaw,
    required this.pitch,
    required this.fresh,
    this.roll = 0,
    super.key,
  });

  final CaptureTarget? target;
  final double yaw, pitch, roll;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    final t = target;
    final available = fresh && t != null && yaw.isFinite && pitch.isFinite;
    final ready = available && angularDistance(yaw, pitch, t.yaw, t.pitch) < 6;
    final color = ready ? const Color(0xFF69F0AE) : Colors.white;
    final turn = available && t.pitch.abs() < 85
        ? normalizeYaw(t.yaw - yaw)
        : 0.0;
    final tilt = available ? t.pitch - pitch : 0.0;
    return IgnorePointer(
      child: Semantics(
        label: ready
            ? 'Encuadre sugerido alineado'
            : available
            ? 'Guía de giro e inclinación'
            : 'Guía de orientación sin lectura reciente',
        child: SizedBox(
          key: const Key('capture-aim-indicator'),
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                key: Key(ready ? 'capture-aim-ready' : 'capture-aim-pending'),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: available ? color : Colors.white54,
                    width: ready ? 4 : 2,
                  ),
                  color: Colors.black26,
                ),
              ),
              if (available) ...[
                Transform.rotate(
                  angle: (roll.isFinite ? roll : 0) * math.pi / 180,
                  child: Container(width: 86, height: 2, color: color),
                ),
                Align(
                  alignment: Alignment(
                    (turn / 40).clamp(-1, 1),
                    (-tilt / 40).clamp(-1, 1),
                  ),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black54, width: 2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
