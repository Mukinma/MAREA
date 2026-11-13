import 'package:flutter/material.dart';
import 'package:marea/l10n/app_localizations.dart';
import 'package:marea/l10n/app_localizations_es.dart';
import '../models/tour_models.dart';
import 'capture_plan.dart';

import 'package:marea/core/localization/app_localizations.dart' as core_l10n;
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

  String instruction(AppLocalizations l10n) {
    if (busy) return core_l10n.AppLocalizations.tr(l10n.guardandoToma);
    if (!fresh || !yaw.isFinite || !pitch.isFinite) {
      return core_l10n.AppLocalizations.tr(l10n.esperandoOrientacionMover);
    }
    if (aimed) {
      return steady
          ? core_l10n.AppLocalizations.tr(l10n.posicionListaAceptar)
          : core_l10n.AppLocalizations.tr(l10n.mantenerTelefonoEstableMomento);
    }
    final turn = normalizeYaw(target.yaw - yaw);
    final tilt = target.pitch - pitch;
    final directions = <String>[];
    if (tilt.abs() >= 3) {
      directions.add(
        tilt > 0
            ? core_l10n.AppLocalizations.tr(
                l10n.inclinaArribaGrados(tilt.abs().round()),
              )
            : core_l10n.AppLocalizations.tr(
                l10n.inclinaAbajoGrados(tilt.abs().round()),
              ),
      );
    }
    // Azimuth is immaterial when aiming at the ceiling or floor.
    if (target.pitch.abs() < 85 && turn.abs() >= 3) {
      directions.add(
        turn > 0
            ? core_l10n.AppLocalizations.tr(
                l10n.giraDerechaGrados(turn.abs().round()),
              )
            : core_l10n.AppLocalizations.tr(
                l10n.giraIzquierdaGrados(turn.abs().round()),
              ),
      );
    }
    return directions.isEmpty
        ? core_l10n.AppLocalizations.tr(l10n.ajustaEncuadreAlinear)
        : directions.join('. ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              instruction(l10n),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (fresh && yaw.isFinite && pitch.isFinite) ...[
              const SizedBox(height: 4),
              Text(
                core_l10n.AppLocalizations.tr(
                  l10n.lecturaOrientacion(
                    yaw.round(),
                    pitch.round(),
                    target.yaw.round(),
                    target.pitch.round(),
                  ),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: !busy && fresh && aimed && steady ? onTake : null,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(core_l10n.AppLocalizations.tr(l10n.aceptarToma)),
            ),
          ],
        ),
      ),
    );
  }
}
