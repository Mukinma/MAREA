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
    super.key,
  });

  final CaptureTarget target;
  final double yaw, pitch;
  final bool fresh, aimed, steady, busy;
  final VoidCallback onTake;

  String get instruction {
    if (busy) return 'Guardando la toma…';
    if (!fresh || !yaw.isFinite || !pitch.isFinite) {
      return 'Esperando orientación del teléfono. Muévelo suavemente.';
    }
    if (aimed) {
      return steady
          ? 'Posición lista. Pulsa Aceptar toma.'
          : 'Mantén el teléfono estable un momento.';
    }
    final turn = normalizeYaw(target.yaw - yaw);
    final tilt = target.pitch - pitch;
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
          Text(instruction, style: Theme.of(context).textTheme.titleSmall),
          if (fresh && yaw.isFinite && pitch.isFinite) ...[
            const SizedBox(height: 4),
            Text(
              'Actual: giro ${yaw.round()}° · inclinación ${pitch.round()}°\n'
              'Objetivo: giro ${target.yaw.round()}° · inclinación ${target.pitch.round()}°',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: !busy && fresh && aimed && steady ? onTake : null,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Aceptar toma'),
          ),
        ],
      ),
    ),
  );
}
