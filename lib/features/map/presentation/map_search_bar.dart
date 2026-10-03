import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/category_visuals.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/map/models/mission_map_models.dart';
import 'package:marea/shared/widgets/marea_surface.dart';

class MapSearchBar extends StatelessWidget {
  const MapSearchBar({
    required this.controller,
    required this.filtersActive,
    required this.onSubmitted,
    required this.onFilters,
    super.key,
  });
  final TextEditingController controller;
  final bool filtersActive;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilters;
  @override
  Widget build(BuildContext context) => MareaSurface(
    color: AppColors.surface,
    radius: 32,
    padding: const EdgeInsets.only(left: 8, right: 6),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Buscar en el mapa',
          onPressed: () => onSubmitted(controller.text),
          icon: const Icon(Icons.search_rounded, color: AppColors.brandNavy),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: onSubmitted,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Buscar misiones o lugares',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Filtros del mapa',
          onPressed: onFilters,
          style: IconButton.styleFrom(backgroundColor: AppColors.mint),
          icon: Badge(
            isLabelVisible: filtersActive,
            backgroundColor: AppColors.aqua,
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.aquaDark,
              size: 21,
            ),
          ),
        ),
      ],
    ),
  );
}

class MapQuickFilters extends StatelessWidget {
  const MapQuickFilters({
    required this.filters,
    required this.onChanged,
    super.key,
  });
  final MissionMapFilters filters;
  final ValueChanged<MissionMapFilters> onChanged;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _chip(
          'Todo',
          filters.category == null,
          () => onChanged(filters.withCategory(null)),
        ),
        _chip(
          'Hoy',
          filters.date == MissionMapDate.today,
          () => onChanged(
            filters.withDate(
              filters.date == MissionMapDate.today
                  ? MissionMapDate.any
                  : MissionMapDate.today,
            ),
          ),
        ),
        for (final entry in communityCategories.entries)
          _chip(
            entry.value,
            filters.category == entry.key,
            () => onChanged(
              filters.withCategory(
                filters.category == entry.key ? null : entry.key,
              ),
            ),
            color: CategoryVisuals.forCategory(entry.key).color,
          ),
      ],
    ),
  );
  Widget _chip(
    String label,
    bool selected,
    VoidCallback action, {
    Color? color,
  }) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => action(),
      showCheckmark: false,
      selectedColor: AppColors.brandNavy,
      backgroundColor: color?.withValues(alpha: .94) ?? AppColors.surface,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.brandNavy,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(color: selected ? AppColors.brandNavy : Colors.white),
      shape: const StadiumBorder(),
    ),
  );
}
