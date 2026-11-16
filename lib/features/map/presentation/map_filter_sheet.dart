import 'package:marea/shared/widgets/marea_panel.dart';
import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/category_visuals.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/map/models/mission_map_models.dart';

Future<MissionMapFilters?> showMapFilterSheet(
  BuildContext context,
  MissionMapFilters initial,
) => showMareaBottomSheet<MissionMapFilters>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => MapFilterSheet(initial: initial),
);

class MapFilterSheet extends StatefulWidget {
  const MapFilterSheet({required this.initial, super.key});
  final MissionMapFilters initial;
  @override
  State<MapFilterSheet> createState() => _MapFilterSheetState();
}

class _MapFilterSheetState extends State<MapFilterSheet> {
  late MissionMapFilters _value = widget.initial;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.navigationAqua,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.tune_rounded,
                            color: AppColors.brandNavy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Filtros del mapa',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.brandNavy,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Categoría',
                    style: TextStyle(
                      color: AppColors.brandNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ChoiceChip(
                        label: const Text('Todas'),
                        selected: _value.category == null,
                        selectedColor: AppColors.navigationAqua,
                        onSelected: (_) =>
                            setState(() => _value = _value.withCategory(null)),
                      ),
                      for (final entry in communityCategories.entries)
                        _categoryChip(entry.key, entry.value),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Radio alrededor del centro de esta zona',
                    style: TextStyle(
                      color: AppColors.brandNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final radius in <double?>[null, 1, 3, 5, 10])
                        ChoiceChip(
                          label: Text(
                            radius == null
                                ? 'Sin límite'
                                : '${radius.toInt()} km',
                          ),
                          selected: _value.radiusKm == radius,
                          onSelected: (_) => setState(
                            () => _value = MissionMapFilters(
                              category: _value.category,
                              date: _value.date,
                              radiusKm: radius,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Fecha',
                    style: TextStyle(
                      color: AppColors.brandNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final (value, label) in [
                        (MissionMapDate.any, 'Cualquier fecha'),
                        (MissionMapDate.today, 'Hoy'),
                        (MissionMapDate.next7Days, 'Próximos siete días'),
                      ])
                        ChoiceChip(
                          label: Text(label),
                          selected: _value.date == value,
                          onSelected: (_) =>
                              setState(() => _value = _value.withDate(value)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _value),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Aplicar filtros'),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pop(context, const MissionMapFilters()),
                    child: const Text('Limpiar filtros'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _categoryChip(String value, String label) {
    final visual = CategoryVisuals.forCategory(value);
    final selected = _value.category == value;
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(visual.icon, size: 17, color: AppColors.brandNavy),
      selected: selected,
      selectedColor: visual.color,
      backgroundColor: visual.color.withValues(alpha: .18),
      side: BorderSide(
        color: selected ? AppColors.aquaDark : visual.color,
      ),
      onSelected: (_) => setState(
        () => _value = _value.withCategory(value),
      ),
    );
  }
}
