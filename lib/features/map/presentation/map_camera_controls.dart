import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:marea/core/maps/map_surface.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/shared/widgets/marea_surface.dart';

class MapCameraControls extends StatelessWidget {
  const MapCameraControls({
    required this.controller,
    required this.ready,
    required this.locating,
    required this.onLocate,
    this.compact = false,
    super.key,
  });
  final MapSurfaceController controller;
  final bool ready, locating, compact;
  final VoidCallback onLocate;
  @override
  Widget build(BuildContext context) => MareaSurface(
    color: AppColors.surface,
    radius: 16,
    floating: true,
    clipBehavior: Clip.antiAlias,
    child: Flex(
      direction: compact ? Axis.horizontal : Axis.vertical,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (controller.isRotated)
          IconButton(
            tooltip: 'Orientar al norte',
            onPressed: ready && !controller.cameraBusy
                ? controller.resetNorth
                : null,
            constraints: BoxConstraints.tightFor(
              width: 48,
              height: 48,
            ),
            icon: Transform.rotate(
              angle: -(controller.viewport?.bearing ?? 0) * math.pi / 180,
              child: const Icon(
                Icons.navigation_outlined,
                color: AppColors.brandNavy,
              ),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (mode, label) in [
              (MapViewMode.twoD, '2D'),
              (MapViewMode.threeD, '3D'),
            ])
              SizedBox(
                width: 48,
                height: 48,
                child: MergeSemantics(
                  child: Semantics(
                    selected: controller.viewMode == mode,
                    child: TextButton(
                      onPressed: ready && !controller.cameraBusy
                          ? () => controller.setPerspective(mode)
                          : null,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 48),
                        shape: const RoundedRectangleBorder(),
                        backgroundColor: controller.viewMode == mode
                            ? AppColors.navigationAqua
                            : Colors.transparent,
                        foregroundColor: AppColors.brandNavy,
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (!compact) const SizedBox(width: 48, child: Divider(height: 1)),
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            tooltip: locating
                ? 'Buscando ubicación…'
                : 'Centrar en mi ubicación',
            onPressed: locating ? null : onLocate,
            icon: locating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.brandNavy,
                  ),
          ),
        ),
      ],
    ),
  );
}
