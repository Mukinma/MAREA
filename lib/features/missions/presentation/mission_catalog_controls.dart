import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_depth.dart';
import 'package:marea/core/theme/category_visuals.dart';
import 'package:marea/features/missions/application/mission_catalog_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/shared/widgets/marea_panel.dart';

const missionCatalogInset = 16.0;

class MissionCatalogSearchBar extends StatelessWidget {
  const MissionCatalogSearchBar({
    required this.text,
    required this.onChanged,
    required this.onSubmitted,
    required this.onFilters,
    required this.activeFilterCount,
    super.key,
  });

  final TextEditingController text;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilters;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(28),
      boxShadow: AppDepth.floating,
    ),
    child: Row(
      children: [
        ValueListenableBuilder(
          valueListenable: text,
          builder: (context, value, _) {
            if (value.text.isNotEmpty) {
              return IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () {
                  text.clear();
                  onChanged('');
                },
                icon: const Icon(
                  Icons.close,
                  color: AppColors.brandNavy,
                  size: 20,
                ),
              );
            }
            return MediaQuery.sizeOf(context).width >= 350 &&
                    MediaQuery.textScalerOf(context).scale(16) <= 22
                ? const Padding(
                    padding: EdgeInsets.only(left: 12, right: 6),
                    child: Icon(
                      Icons.search_outlined,
                      color: AppColors.brandNavy,
                      size: 23,
                    ),
                  )
                : const SizedBox(width: 10);
          },
        ),
        Expanded(
          child: TextField(
            key: const Key('mission-catalog-search'),
            controller: text,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: const InputDecoration(
              hintText: 'Buscar misiones',
              hintMaxLines: 2,
              hintStyle: TextStyle(color: AppColors.textSecondary),
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.aquaDark, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 24,
          child: VerticalDivider(width: 1, color: AppColors.border),
        ),
        Semantics(
          selected: activeFilterCount > 0,
          value: activeFilterCount == 0
              ? null
              : '$activeFilterCount filtros activos',
          child: IconButton(
            tooltip: 'Filtros',
            onPressed: onFilters,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(48),
              foregroundColor: AppColors.brandNavy,
            ),
            icon: Badge.count(
              count: activeFilterCount,
              isLabelVisible: activeFilterCount > 0,
              backgroundColor: AppColors.aquaDark,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ),
      ],
    ),
  );
}

class MissionCatalogCategories extends StatefulWidget {
  const MissionCatalogCategories({
    required this.categories,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  State<MissionCatalogCategories> createState() =>
      _MissionCatalogCategoriesState();
}

class _MissionCatalogCategoriesState extends State<MissionCatalogCategories> {
  final _scroll = ScrollController();
  final _selected = GlobalKey();

  @override
  void didUpdateWidget(covariant MissionCatalogCategories oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected == widget.selected) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _selected.currentContext?.findRenderObject();
      if (mounted && _scroll.hasClients && target != null) {
        _scroll.position.ensureVisible(target, alignment: .5);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const Key('mission-catalog-categories'),
    controller: _scroll,
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(
      missionCatalogInset,
      4,
      missionCatalogInset,
      8,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in <String?>[null, ...widget.categories]) ...[
          if (category != null) const SizedBox(width: 8),
          _CategoryTile(
            key: ValueKey('mission-catalog-category-${category ?? 'all'}'),
            tileKey: category == widget.selected ? _selected : null,
            category: category,
            selected: category == widget.selected,
            onTap: () => widget.onSelected(category),
          ),
        ],
      ],
    ),
  );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.tileKey,
    required this.category,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Key? tileKey;
  final String? category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = this.category;
    final visual = CategoryVisuals.forProfileInterest(category ?? 'otros');
    final label = communityCategories[category] ?? 'Todo';
    final activeAll = category == null && selected;
    final foreground = activeAll ? Colors.white : AppColors.brandNavy;
    final radius = BorderRadius.circular(16);
    return Semantics(
      key: tileKey,
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: activeAll
              ? AppColors.brandNavy
              : category == null
              ? AppColors.surface
              : visual.color,
          borderRadius: radius,
          boxShadow: AppDepth.floating,
          border: Border.all(
            color: selected && !activeAll
                ? AppColors.brandNavy
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minWidth: 57, minHeight: 49),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category == null ? Icons.explore_outlined : visual.icon,
                    size: 21,
                    color: category == null ? foreground : visual.accent,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef MissionCatalogFilters = ({double radiusKm, UserType? target});

Future<MissionCatalogFilters?> showMissionCatalogFilters(
  BuildContext context, {
  required MissionCatalogFilters value,
  required UserType? viewerType,
}) => showMareaBottomSheet<MissionCatalogFilters>(
  context: context,
  isScrollControlled: true,
  constraints: const BoxConstraints(maxWidth: 560),
  builder: (_) => _FilterSheet(value: value, viewerType: viewerType),
);

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.value, required this.viewerType});

  final MissionCatalogFilters value;
  final UserType? viewerType;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late double _radius = widget.value.radiusKm;
  late UserType? _target = widget.value.target;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .78,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtros',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserType?>(
                    key: const Key('mission-catalog-profile-filter'),
                    initialValue: _target,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Perfil buscado',
                    ),
                    items: [
                      const DropdownMenuItem<UserType?>(
                        value: null,
                        child: Text('Cualquier perfil'),
                      ),
                      for (final type in UserType.values)
                        DropdownMenuItem(
                          value: type,
                          child: Text(
                            type == widget.viewerType
                                ? 'Para mi perfil'
                                : type.databaseValue,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _target = value),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Radio de Cerca de ti',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final radius in MissionCatalogController.radii)
                        ChoiceChip(
                          label: Text('${radius.toInt()} km'),
                          selected: _radius == radius,
                          onSelected: (_) => setState(() => _radius = radius),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pop((radiusKm: _radius, target: _target)),
              child: const Text('Aplicar filtros'),
            ),
          ),
        ],
      ),
    ),
  );
}
