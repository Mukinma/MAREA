import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/category_visuals.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/mission_widgets.dart';
import 'package:marea/shared/widgets/marea_surface.dart';

class MissionMapPreview extends StatelessWidget {
  const MissionMapPreview({
    required this.mission,
    required this.onOpen,
    required this.onClose,
    this.repository,
    this.distanceMeters,
    super.key,
  });
  final Mission mission;
  final CommunityRepository? repository;
  final double? distanceMeters;
  final VoidCallback onOpen, onClose;
  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisuals.forCategory(mission.category);
    final distance = distanceMeters == null
        ? null
        : distanceMeters! < 1000
        ? '${(distanceMeters! / 50).round() * 50} m aprox.'
        : '${(distanceMeters! / 1000).toStringAsFixed(1)} km aprox.';
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 150) onClose();
      },
      child: MareaSurface(
        color: AppColors.surface,
        radius: 28,
        padding: const EdgeInsets.fromLTRB(16, 4, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 48),
                const Spacer(),
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Cerrar misión',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 19),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mission.imagePath != null) ...[
                  SizedBox(
                    width: 88,
                    child: MissionCover(
                      path: mission.imagePath,
                      repository: repository,
                      height: 110,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: visual.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          child: Text(
                            communityCategories[mission.category] ?? 'Otros',
                            style: const TextStyle(
                              color: AppColors.brandNavy,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mission.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Por ${mission.organizerName ?? mission.organizerUsername ?? 'la comunidad MAREA'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${mission.location}${distance == null ? '' : ' · $distance'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        missionDate(mission.startsAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.aquaDark,
                  minimumSize: const Size(48, 44),
                ),
                child: const Text('Ver misión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
