import 'package:flutter/material.dart';
import '../models/tour_models.dart';
import 'capture_plan.dart';

/// Guidance and shutter stay visible while the camera content scrolls.
class CaptureGuidancePanel extends StatelessWidget {
  const CaptureGuidancePanel({
    required this.target,
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
    super.key,
  });

  final CaptureTarget target;
  final double yaw, pitch;
  final bool fresh, aimed, steady, busy;
  final VoidCallback onTake;
  final bool automatic, paused, showAngles;
  final VoidCallback? onTogglePause;

  String get instruction {
    if (busy) return 'Guardando la toma…';
    if (automatic && paused) {
      return 'Captura en pausa. Continúa cuando estés listo.';
    }
    if (!fresh || !yaw.isFinite || !pitch.isFinite) {
      return 'Esperando orientación del teléfono. Muévelo suavemente.';
    }
    if (aimed) {
      return steady
          ? automatic
                ? 'Encuadre listo. Tomando foto…'
                : 'Posición lista. Pulsa Aceptar toma.'
          : 'Mantén el teléfono estable un momento.';
    }
    if (target.pitch.abs() >= 85) {
      final position = target.pitch > 0
          ? 'al techo, con la pantalla hacia abajo'
          : 'al piso, con la pantalla hacia arriba';
      return 'Apunta la cámara trasera $position. '
          '${automatic ? 'Quédate quieto: la foto se toma sola.' : 'Mantén el teléfono quieto hasta que se active Aceptar toma.'}';
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
    if (automatic && paused) return Icons.pause_circle_outline;
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
                child: Icon(
                  _directionIcon,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  instruction,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          if (showAngles && fresh && yaw.isFinite && pitch.isFinite) ...[
            const SizedBox(height: 4),
            Text(
              'Actual: giro ${yaw.round()}° · inclinación ${pitch.round()}°\n'
              'Objetivo: giro ${target.yaw.round()}° · inclinación ${target.pitch.round()}°',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: busy
                ? null
                : automatic
                ? onTogglePause
                : fresh && aimed && steady
                ? onTake
                : null,
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
                  : 'Aceptar toma',
            ),
          ),
        ],
      ),
    ),
  );
}
