import 'package:flutter/material.dart';
import '../models/tour_models.dart';
import 'capture_plan.dart';
import 'capture_cube.dart';
import 'capture_cube_guide.dart';

/// Guidance and shutter stay visible while the camera content scrolls.
class CaptureGuidancePanel extends StatelessWidget {
  const CaptureGuidancePanel({
    this.target,
    required this.yaw,
    required this.pitch,
    required this.fresh,
    required this.aimed,
    required this.steady,
    required this.busy,
    required this.onTake,
    this.automatic = false,
    this.paused = false,
    this.showAngles = false,
    this.onTogglePause,
    this.cubeGuide,
    this.guideIndex = 0,
    super.key,
  });

  final CaptureTarget? target;
  final double yaw, pitch;
  final bool fresh, aimed, steady, busy;
  final VoidCallback onTake;
  final bool automatic, paused, showAngles;
  final VoidCallback? onTogglePause;
  final CaptureCubeGuide? cubeGuide;
  final int guideIndex;
  CaptureCubeStep? get _cubeStep =>
      cubeGuide != null && guideIndex < cubeGuide!.steps.length
      ? cubeGuide!.steps[guideIndex]
      : null;

  String get instruction {
    if (busy) return 'Guardando la toma…';
    if (!automatic && cubeGuide != null) {
      return _cubeStep?.instruction(first: guideIndex == 0) ??
          'Puedes tomar más fotos.';
    }
    if (!automatic) return 'Gira despacio y toma fotos alrededor de ti.';
    if (paused) {
      return 'Captura en pausa. Continúa cuando estés listo.';
    }
    final target = this.target;
    if (target == null) return 'Mueve la cámara despacio alrededor de ti.';
    if (!fresh || !yaw.isFinite || !pitch.isFinite) {
      return 'Esperando orientación del teléfono. Muévelo suavemente.';
    }
    if (aimed) {
      return steady
          ? 'Encuadre listo. Tomando foto…'
          : 'Mantén el teléfono estable un momento.';
    }
    if (target.pitch.abs() >= 85) {
      final position = target.pitch > 0
          ? 'al techo, con la pantalla hacia abajo'
          : 'al piso, con la pantalla hacia arriba';
      return 'Apunta la cámara trasera $position. '
          'Quédate quieto: la foto se toma sola.';
    }
    if (pitch.abs() > 75) {
      return 'Primero apunta la cámara al frente. Después seguiremos con el giro.';
    }
    final turn = normalizeYaw(target.yaw - yaw);
    final tilt = target.pitch - pitch;
    if (!showAngles) {
      if (turn.abs() >= 3) {
        return 'Gira despacio hacia la ${turn > 0 ? 'derecha' : 'izquierda'}.';
      }
      if (tilt.abs() >= 3) {
        return 'Inclina la cámara hacia ${tilt > 0 ? 'arriba' : 'abajo'}.';
      }
      return 'Ajusta ligeramente el encuadre hasta alinear la cámara.';
    }
    final directions = <String>[];
    if (tilt.abs() >= 3) {
      directions.add(
        'Inclina ${tilt > 0 ? 'hacia arriba' : 'hacia abajo'} ${tilt.abs().round()}°',
      );
    }
    // Azimuth is immaterial when aiming at the ceiling or floor.
    if (target.pitch.abs() < 85 && turn.abs() >= 3) {
      directions.add(
        'Gira ${turn.abs().round()}° a la ${turn > 0 ? 'derecha' : 'izquierda'}',
      );
    }
    return directions.isEmpty
        ? 'Ajusta ligeramente el encuadre hasta alinear la cámara.'
        : directions.join('. ');
  }

  IconData get _directionIcon {
    if (busy) return Icons.hourglass_top_rounded;
    if (!automatic) return Icons.rotate_right_rounded;
    if (paused) return Icons.pause_circle_outline;
    final target = this.target;
    if (target == null) return Icons.rotate_right_rounded;
    if (!fresh || !yaw.isFinite || !pitch.isFinite) {
      return Icons.explore_outlined;
    }
    if (aimed) return steady ? Icons.check_rounded : Icons.pan_tool_outlined;
    if (target.pitch.abs() >= 85) {
      return target.pitch > 0
          ? Icons.arrow_upward_rounded
          : Icons.arrow_downward_rounded;
    }
    if (pitch.abs() > 75) return Icons.stay_current_portrait;
    final turn = normalizeYaw(target.yaw - yaw);
    if (turn.abs() >= 3) {
      return turn > 0 ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded;
    }
    return target.pitch > pitch
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
  }

  String get _angleDetails {
    final target = this.target;
    final actual =
        'Actual: giro ${yaw.round()}° · inclinación ${pitch.round()}°';
    return target == null
        ? actual
        : '$actual\n'
              'Objetivo: giro ${target.yaw.round()}° · inclinación ${target.pitch.round()}°';
  }

  @override
  Widget build(BuildContext context) => Material(
    elevation: 8,
    color: Theme.of(context).colorScheme.surface,
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: !automatic && cubeGuide != null
                    ? SizedBox(
                        width: MediaQuery.textScalerOf(context).scale(1) > 1.5
                            ? 64
                            : 92,
                        height: MediaQuery.textScalerOf(context).scale(1) > 1.5
                            ? 64
                            : 92,
                        child: CaptureCube(
                          step: _cubeStep,
                          completed: _cubeStep == null,
                        ),
                      )
                    : Icon(
                        _directionIcon,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!automatic && cubeGuide != null) ...[
                      Text(
                        _cubeStep == null
                            ? 'Guía recorrida'
                            : '${_cubeStep!.faceLabel} · ${_cubeStep!.zoneLabel}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        _cubeStep == null
                            ? 'Referencia: el centro'
                            : 'Paso ${guideIndex + 1} de ${cubeGuide!.steps.length} · desde el centro',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      instruction,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showAngles && fresh && yaw.isFinite && pitch.isFinite) ...[
            const SizedBox(height: 4),
            Text(_angleDetails, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: busy
                ? null
                : automatic
                ? onTogglePause
                : onTake,
            icon: Icon(
              automatic
                  ? paused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded
                  : Icons.camera_alt_outlined,
            ),
            label: Text(
              automatic
                  ? paused
                        ? 'Continuar captura'
                        : 'Pausar captura'
                  : 'Tomar foto',
            ),
          ),
        ],
      ),
    ),
  );
}
