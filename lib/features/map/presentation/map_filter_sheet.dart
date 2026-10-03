import 'package:flutter/material.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/map/models/mission_map_models.dart';

Future<MissionMapFilters?> showMapFilterSheet(
  BuildContext context,
  MissionMapFilters initial,
) => showModalBottomSheet<MissionMapFilters>(
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros del mapa',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'Categoría',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _value.category == null,
                  onSelected: (_) =>
                      setState(() => _value = _value.withCategory(null)),
                ),
                for (final entry in communityCategories.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _value.category == entry.key,
                    onSelected: (_) =>
                        setState(() => _value = _value.withCategory(entry.key)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Radio alrededor del centro de esta zona',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final radius in <double?>[null, 1, 3, 5, 10])
                  ChoiceChip(
                    label: Text(
                      radius == null ? 'Sin límite' : '${radius.toInt()} km',
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
            const SizedBox(height: 16),
            const Text('Fecha', style: TextStyle(fontWeight: FontWeight.w800)),
            Wrap(
              spacing: 8,
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _value),
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
    ),
  );
}
