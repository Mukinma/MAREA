import 'package:marea/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/category_visuals.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/map/models/mission_map_models.dart';
import 'package:marea/shared/widgets/marea_surface.dart';

class MapSearchBar extends StatefulWidget {
  const MapSearchBar({
    required this.controller,
    required this.onSubmitted,
    required this.onFilters,
    this.filterCount = 0,
    super.key,
  });
  final TextEditingController controller;
  final int filterCount;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilters;
  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  final _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  void _changed() => setState(() {});
  @override
  void dispose() {
    _focus.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      MareaSurface(
        color: AppColors.surface,
        radius: 18,
        padding: EdgeInsets.zero,
        floating: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, right: 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Buscar en el mapa',
                    onPressed: () => widget.onSubmitted(widget.controller.text),
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    icon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.brandNavy,
                      size: 23,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      textInputAction: TextInputAction.search,
                      onSubmitted: widget.onSubmitted,
                      decoration: const InputDecoration(
                        hintText: 'Buscar misiones',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Filtros del mapa',
                    child: TextButton.icon(
                      onPressed: widget.onFilters,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        foregroundColor: AppColors.brandNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 19),
                      label: Text(
                        widget.filterCount > 0
                            ? 'Filtros ${widget.filterCount}'
                            : 'Filtros',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_focus.hasFocus)
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 14, right: 14, bottom: 8),
                  child: Text(
                    'Por título, lugar u organizador',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class MapQuickFilters extends StatefulWidget {
  const MapQuickFilters({
    required this.filters,
    required this.onChanged,
    super.key,
  });
  final MissionMapFilters filters;
  final ValueChanged<MissionMapFilters> onChanged;
  @override
  State<MapQuickFilters> createState() => _MapQuickFiltersState();
}

class _MapQuickFiltersState extends State<MapQuickFilters> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final activeCategory = widget.filters.category == null
        ? null
        : CategoryVisuals.forCategory(widget.filters.category!);
    final categoryButton = _chip(
      AppLocalizations.tr('Categorías'),
      false,
      () => setState(() => _expanded = true),
      icon: Icons.category_outlined,
      iconColor: AppColors.brandNavy,
    );
    final activeCategoryButton = activeCategory == null
        ? null
        : _activeCategoryButton(
            AppLocalizations.tr(
              communityCategories[widget.filters.category] ?? 'Categoría',
            ),
            activeCategory,
          );
    final commonChips = [
      _chip(
        AppLocalizations.tr('Todas'),
        widget.filters.category == null,
        () => widget.onChanged(widget.filters.withCategory(null)),
      ),
      for (final entry in communityCategories.entries)
        _chip(
          AppLocalizations.tr(entry.value),
          widget.filters.category == entry.key,
          () => widget.onChanged(
            widget.filters.withCategory(
              widget.filters.category == entry.key ? null : entry.key,
            ),
          ),
          color: CategoryVisuals.forCategory(entry.key).color,
          icon: CategoryVisuals.forCategory(entry.key).icon,
          iconColor: CategoryVisuals.forCategory(entry.key).iconColor,
          alwaysColored: true,
        ),
      _chip(
        AppLocalizations.tr('Hoy'),
        widget.filters.date == MissionMapDate.today,
        () => widget.onChanged(
          widget.filters.withDate(
            widget.filters.date == MissionMapDate.today
                ? MissionMapDate.any
                : MissionMapDate.today,
          ),
        ),
      ),
      if (widget.filters.radiusKm != null)
        _chip(
          '${widget.filters.radiusKm!.toInt()} km',
          true,
          () => setState(() => _expanded = true),
          icon: Icons.near_me_outlined,
        ),
    ];
    if (!_expanded) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            categoryButton,
            ?activeCategoryButton,
            ...commonChips.skip(communityCategories.length + 1),
          ],
        ),
      );
    }
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: IconButton(
            tooltip: AppLocalizations.tr('Ocultar categorías'),
            onPressed: () => setState(() => _expanded = false),
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: AppColors.brandNavy,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
              shape: const CircleBorder(),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: commonChips),
          ),
        ),
      ],
    );
  }

  Widget _activeCategoryButton(String label, CategoryVisual visual) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: true,
        label: label,
        child: IconButton(
          onPressed: () => widget.onChanged(widget.filters.withCategory(null)),
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          padding: EdgeInsets.zero,
          icon: Icon(visual.icon, size: 22, color: visual.iconColor),
          style: IconButton.styleFrom(
            backgroundColor: visual.color,
            side: BorderSide(color: visual.iconColor, width: 2),
            shape: const CircleBorder(),
          ),
        ),
      ),
    ),
  );

  Widget _chip(
    String label,
    bool selected,
    VoidCallback action, {
    Color? color,
    IconData? icon,
    Color? iconColor,
    bool alwaysColored = false,
  }) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: SizedBox(
      height: 48,
      child: MergeSemantics(
        child: Semantics(
          selected: selected,
          child: ActionChip(
            label: Text(label),
            avatar: icon == null
                ? null
                : Icon(
                    icon,
                    size: 17,
                    color: iconColor ?? color ?? AppColors.brandNavy,
                  ),
            onPressed: action,
            backgroundColor: alwaysColored && color != null
                ? color.withValues(alpha: selected ? 1 : .28)
                : selected
                ? color ?? AppColors.navigationAqua
                : AppColors.surface,
            labelStyle: const TextStyle(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide(
              color: selected && alwaysColored && color != null
                  ? iconColor ?? color
                  : selected
                  ? AppColors.aquaDark
                  : alwaysColored && color != null
                  ? color
                  : AppColors.border,
              width: selected ? 2.5 : 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    ),
  );
}
