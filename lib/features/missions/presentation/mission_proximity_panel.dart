import 'package:flutter/material.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/missions/application/mission_catalog_controller.dart';
import 'package:marea/features/missions/presentation/mission_catalog_cards.dart';
import 'package:marea/shared/widgets/marea_skeleton.dart';

class MissionProximityPanel extends StatelessWidget {
  const MissionProximityPanel({
    required this.catalog,
    required this.onMap,
    required this.onSettings,
    required this.onOpen,
    required this.bookmark,
    super.key,
  });

  final MissionCatalogController catalog;
  final VoidCallback onMap, onSettings;
  final ValueChanged<String> onOpen;
  final MissionBookmark? Function(String) bookmark;

  @override
  Widget build(BuildContext context) {
    final missions = catalog.nearby;
    final scale = MediaQuery.textScalerOf(context).scale(16);
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.navigationAqua.withValues(alpha: .5),
        border: Border.all(color: AppColors.surface, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 4, 8, 4),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.navigationAqua,
                  foregroundColor: AppColors.aquaDark,
                  child: Icon(Icons.location_on_rounded, size: 21),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catalog.zoneName ??
                            (catalog.hasPosition ? 'Tu zona' : 'Cerca de ti'),
                        style: text.titleSmall?.copyWith(
                          color: AppColors.brandNavy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (missions.isNotEmpty && scale <= 22)
                        Text(
                          'Oportunidades cerca de ti',
                          style: text.bodySmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Ver mapa',
                  onPressed: onMap,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.brandNavy,
                    minimumSize: const Size.square(48),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 23),
                ),
              ],
            ),
          ),
          if (missions.isNotEmpty)
            LayoutBuilder(
              builder: (context, bounds) => SizedBox(
                height: NearbyMissionCard.height(context) + 9,
                child: ListView.separated(
                  key: ValueKey(
                    'mission-proximity-${catalog.category}-${catalog.radiusKm}',
                  ),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 9),
                  itemCount: missions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final item = missions[index];
                    final id = item.mission.id;
                    return SizedBox(
                      width: missions.length == 1
                          ? bounds.maxWidth - 12
                          : (bounds.maxWidth * (scale > 22 ? .8 : .46)).clamp(
                              128.0,
                              275.0,
                            ),
                      child: NearbyMissionCard(
                        key: ValueKey('nearby-mission-$id'),
                        mission: item.mission,
                        nearby: item,
                        resolveImage: catalog.community?.missionImageUrl,
                        bookmark: bookmark(id),
                        onOpen: () => onOpen(id),
                      ),
                    );
                  },
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: _state(),
            ),
        ],
      ),
    );
  }

  Widget _state() {
    if (catalog.nearbyWaiting) {
      return const SizedBox(height: 42, child: MareaSkeleton(compact: true));
    }
    if (catalog.nearError case final error?) {
      return MissionCatalogNotice(
        message: error,
        action: 'Reintentar',
        onAction: catalog.loadNearby,
        inline: true,
      );
    }
    final failure = catalog.locationFailure;
    if (failure == null) {
      return const MissionCatalogNotice(
        message: 'No hay misiones dentro de este radio.',
        inline: true,
      );
    }
    final needsSettings =
        failure.kind == DeviceLocationFailureKind.deniedForever ||
        failure.kind == DeviceLocationFailureKind.disabled;
    return MissionCatalogNotice(
      message: 'Activa la ubicación para ver misiones cercanas.',
      action: needsSettings ? 'Abrir Ajustes' : 'Usar mi ubicación',
      onAction: needsSettings
          ? onSettings
          : () => catalog.locate(explicit: true),
      inline: true,
    );
  }
}

class MissionCatalogNotice extends StatelessWidget {
  const MissionCatalogNotice({
    required this.message,
    this.action,
    this.onAction,
    this.inline = false,
    super.key,
  });

  final String message;
  final String? action;
  final VoidCallback? onAction;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final text = Text(message, style: Theme.of(context).textTheme.bodySmall);
    if (action == null && inline) return text;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        text,
        if (action case final label?)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: Text(label),
          ),
      ],
    );
    return inline
        ? content
        : DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(padding: const EdgeInsets.all(12), child: content),
          );
  }
}
