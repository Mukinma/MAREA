import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/category_visuals.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/home_feed/models/home_feed_models.dart';
import 'package:marea/shared/widgets/marea_panel.dart';

class HomeFeedControls extends StatelessWidget {
  const HomeFeedControls({
    required this.mode,
    required this.category,
    required this.hasCustomRadius,
    required this.onMode,
    required this.onFilters,
    required this.onClearCategory,
    super.key,
  });

  final HomeFeedMode mode;
  final String? category;
  final bool hasCustomRadius;
  final ValueChanged<HomeFeedMode> onMode;
  final VoidCallback onFilters, onClearCategory;

  @override
  Widget build(BuildContext context) {
    final count = (category == null ? 0 : 1) + (hasCustomRadius ? 1 : 0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final view in HomeFeedMode.values)
                            _FeedModeButton(
                              mode: view,
                              selected: view == mode,
                              onPressed: () => onMode(view),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 22,
                    child: VerticalDivider(width: 6, color: AppColors.border),
                  ),
                  IconButton(
                    tooltip: switch (count) {
                      0 => 'Filtrar Inicio',
                      1 => 'Filtrar Inicio (1 activo)',
                      _ => 'Filtrar Inicio ($count activos)',
                    },
                    onPressed: onFilters,
                    icon: ExcludeSemantics(
                      child: Badge.count(
                        count: count,
                        backgroundColor: AppColors.aquaDark,
                        isLabelVisible: count > 0,
                        child: const Icon(Icons.tune_rounded, size: 21),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (category case final category?)
            Tooltip(
              message: 'Quitar filtro de categoría',
              child: TextButton.icon(
                key: const Key('home-active-category'),
                label: Text(communityCategories[category] ?? category),
                icon: const Icon(Icons.close_rounded, size: 16),
                iconAlignment: IconAlignment.end,
                onPressed: onClearCategory,
                style: TextButton.styleFrom(
                  backgroundColor: CategoryVisuals.values[category]?.color,
                  foregroundColor: AppColors.brandNavy,
                  minimumSize: const Size(48, 36),
                  tapTargetSize: MaterialTapTargetSize.padded,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedModeButton extends StatelessWidget {
  const _FeedModeButton({
    required this.mode,
    required this.selected,
    required this.onPressed,
  });

  final HomeFeedMode mode;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = switch (mode) {
      HomeFeedMode.forYou => 'Para ti',
      HomeFeedMode.nearby => 'Cerca',
      HomeFeedMode.following => 'Siguiendo',
      HomeFeedMode.trending => 'Tendencias',
    };
    return Semantics(
      selected: selected,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          backgroundColor: selected
              ? AppColors.navigationAqua
              : Colors.transparent,
          foregroundColor: selected
              ? AppColors.brandNavy
              : AppColors.textSecondary,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

Future<({String? category, int radius})?> showHomeFeedFilters(
  BuildContext context, {
  required String? category,
  required int radius,
  required bool nearby,
}) {
  var selectedCategory = category;
  var selectedRadius = radius;
  return showMareaBottomSheet<({String? category, int radius})>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (context) => StatefulBuilder(
      builder: (context, update) {
        final theme = Theme.of(context);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.paddingOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.navigationAqua,
                      borderRadius: BorderRadius.all(Radius.circular(13)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(11),
                      child: Icon(
                        Icons.tune_rounded,
                        color: AppColors.brandNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Filtros de Inicio',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Categoría', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: selectedCategory == null,
                    onSelected: (_) => update(() => selectedCategory = null),
                  ),
                  for (final entry in communityCategories.entries)
                    ChoiceChip(
                      avatar: Icon(
                        CategoryVisuals.values[entry.key]?.icon,
                        size: 18,
                      ),
                      label: Text(entry.value),
                      backgroundColor: CategoryVisuals.values[entry.key]?.color,
                      selectedColor: AppColors.navigationAqua,
                      selected: selectedCategory == entry.key,
                      showCheckmark: true,
                      onSelected: (_) =>
                          update(() => selectedCategory = entry.key),
                    ),
                ],
              ),
              if (nearby) ...[
                const SizedBox(height: 16),
                Text('Distancia', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final km in [5, 10, 25, 50])
                      ChoiceChip(
                        label: Text('$km km'),
                        selected: selectedRadius == km,
                        onSelected: (_) => update(() => selectedRadius = km),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.pop(context, (
                  category: selectedCategory,
                  radius: selectedRadius,
                )),
                child: const Text('Aplicar filtros'),
              ),
              TextButton(
                onPressed: () => update(() {
                  selectedCategory = null;
                  if (nearby) selectedRadius = 10;
                }),
                child: const Text('Limpiar filtros'),
              ),
            ],
          ),
        );
      },
    ),
  );
}
