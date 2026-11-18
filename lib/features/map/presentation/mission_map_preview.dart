import 'package:marea/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/category_visuals.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/presentation/mission_widgets.dart';

class MissionMapPreview extends StatelessWidget {
  const MissionMapPreview({
    required this.mission,
    required this.onOpen,
    required this.onClose,
    this.repository,
    this.arAction,
    this.distanceMeters,
    this.status = const [],
    super.key,
  });
  final Mission mission;
  final CommunityRepository? repository;
  final Widget? arAction;
  final double? distanceMeters;
  final List<Widget> status;
  final VoidCallback onOpen, onClose;
  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisuals.forCategory(mission.category);
    final distance = distanceMeters == null
        ? null
        : distanceMeters! < 1000
        ? '${(distanceMeters! / 50).round() * 50} m aprox.'
        : '${(distanceMeters! / 1000).toStringAsFixed(1)} km aprox.';
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: visual.color.withValues(alpha: .32),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              AppLocalizations.tr(
                                communityCategories[mission.category] ??
                                    'Otros',
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandNavy,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar misión',
                      onPressed: onClose,
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mission.imagePath != null) ...[
                      SizedBox(
                        width: 64,
                        child: MissionCover(
                          path: mission.imagePath,
                          repository: repository,
                          height: 76,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const SizedBox(height: 4),
                          Text(
                            '${mission.location}${distance == null ? '' : ' · $distance'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                ?arAction,
                ...status,
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.aquaDark,
              minimumSize: const Size(48, 48),
              textStyle: const TextStyle(
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Ver misión'),
          ),
        ),
      ],
    );
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 150) onClose();
      },
      child: content,
    );
  }
}
