import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/category_visuals.dart';
import 'package:marea/features/community/models/community_models.dart';

class MissionMapMarker extends StatelessWidget {
  const MissionMapMarker({
    required this.mission,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final Mission mission;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisuals.forCategory(mission.category);
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${communityCategories[mission.category] ?? 'Otros'}: ${mission.title}',
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: mission.title,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: selected ? 1.12 : 1,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: visual.color,
                  border: Border.all(
                    color: selected ? AppColors.brandNavy : Colors.white,
                    width: selected ? 3 : 2.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x260B255E),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(visual.icon, size: 21, color: AppColors.brandNavy),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MissionMapCluster extends StatelessWidget {
  const MissionMapCluster({required this.count, super.key});
  final int count;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$count misiones agrupadas',
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.brandNavy,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260B255E),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    ),
  );
}
