import 'package:flutter/material.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_radius.dart';
import 'package:marea/features/missions/application/mission_catalog_controller.dart';
import 'package:marea/features/missions/presentation/mission_catalog_cards.dart';
import 'package:marea/features/missions/presentation/mission_catalog_controls.dart';
import 'package:marea/shared/widgets/marea_skeleton.dart';

class MissionProximityPanel extends StatelessWidget {
  const MissionProximityPanel({
    required this.catalog,
    required this.missions,
    required this.onMap,
    required this.onSettings,
    required this.onOpen,
    required this.bookmark,
    super.key,
  });

  final MissionCatalogController catalog;
  final List<NearbyMission> missions;
  final VoidCallback onMap, onSettings;
  final ValueChanged<String> onOpen;
  final MissionBookmark? Function(String) bookmark;

  static const _insets = EdgeInsets.symmetric(horizontal: missionCatalogInset);
  static const _gap = 9.0;

  @override
  Widget build(BuildContext context) {
    final resolveImage = catalog.community?.missionImageUrl;
    final textSize = MediaQuery.textScalerOf(context).scale(16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: _insets,
          child: MissionCatalogSectionHeader(
            title: 'Cerca de ti',
            subtitle: catalog.zoneName,
            compact: true,
            actions: [MissionCatalogMapButton(onPressed: onMap)],
          ),
        ),
        const SizedBox(height: 8),
        if (missions.isEmpty)
          Padding(padding: _insets, child: _state())
        else
          LayoutBuilder(
            builder: (context, bounds) {
              if (missions.length == 1 ||
                  bounds.maxWidth < 340 ||
                  textSize > 20) {
                return Padding(
                  padding: _insets,
                  child: Column(
                    children: [
                      for (final (index, item) in missions.indexed) ...[
                        if (index > 0) const SizedBox(height: _gap),
                        MissionCatalogCard(
                          key: ValueKey('nearby-mission-${item.mission.id}'),
                          mission: item.mission,
                          distance: item,
                          resolveImage: resolveImage,
                          bookmark: bookmark(item.mission.id),
                          onOpen: () => onOpen(item.mission.id),
                        ),
                      ],
                    ],
                  ),
                );
              }
              final available = bounds.maxWidth - _insets.horizontal;
              final cardWidth =
                  (missions.length == 2
                          ? (available - _gap) / 2
                          : available * .46)
                      .clamp(0.0, 255.0);
              return SizedBox(
                height: NearbyMissionCard.height + (textSize - 16) * 4,
                child: ListView.separated(
                  key: ValueKey(
                    'mission-proximity-${catalog.category}-${catalog.radiusKm}',
                  ),
                  scrollDirection: Axis.horizontal,
                  padding: _insets,
                  itemCount: missions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: _gap),
                  itemBuilder: (context, index) {
                    final item = missions[index];
                    final id = item.mission.id;
                    return SizedBox(
                      width: cardWidth,
                      child: NearbyMissionCard(
                        key: ValueKey('nearby-mission-$id'),
                        mission: item.mission,
                        nearby: item,
                        resolveImage: resolveImage,
                        bookmark: bookmark(id),
                        onOpen: () => onOpen(id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _state() {
    if (catalog.nearbyWaiting) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.medium)),
        ),
        child: SizedBox(height: 84, child: MareaSkeleton()),
      );
    }
    if (catalog.nearError case final error?) {
      return MissionCatalogNotice(
        message: error,
        action: 'Reintentar',
        onAction: catalog.loadNearby,
      );
    }
    final failure = catalog.locationFailure;
    if (failure == null) {
      return const MissionCatalogNotice(
        message: 'No hay misiones dentro de este radio.',
      );
    }

    final kind = failure.kind;
    final needsSettings =
        kind == DeviceLocationFailureKind.deniedForever ||
        kind == DeviceLocationFailureKind.disabled;
    final (message, action) = switch (kind) {
      DeviceLocationFailureKind.deniedForever => (
        'Permite el acceso a tu ubicación desde Ajustes.',
        'Abrir Ajustes',
      ),
      DeviceLocationFailureKind.disabled => (
        'La ubicación del dispositivo está desactivada.',
        'Abrir Ajustes',
      ),
      DeviceLocationFailureKind.timeout ||
      DeviceLocationFailureKind.unavailable => (
        'No pudimos obtener tu ubicación.',
        'Reintentar',
      ),
      _ => (
        'Activa la ubicación para ver misiones cercanas.',
        'Usar mi ubicación',
      ),
    };
    return MissionCatalogNotice(
      message: message,
      action: action,
      onAction: needsSettings
          ? onSettings
          : () => catalog.locate(explicit: true),
    );
  }
}

class MissionCatalogNotice extends StatelessWidget {
  const MissionCatalogNotice({
    required this.message,
    this.action,
    this.onAction,
    super.key,
  });

  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppRadius.small),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(13, 12, 13, action == null ? 12 : 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
          if (action case final label?)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 2),
              ),
              child: Text(label),
            ),
        ],
      ),
    ),
  );
}
