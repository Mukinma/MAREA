import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/missions/application/mission_catalog_controller.dart';
import 'package:marea/features/missions/presentation/mission_catalog_cards.dart';
import 'package:marea/features/missions/presentation/mission_catalog_controls.dart';
import 'package:marea/features/missions/presentation/mission_proximity_panel.dart';
import 'package:marea/shared/widgets/marea_skeleton.dart';

class MissionCatalogScreen extends StatefulWidget {
  const MissionCatalogScreen({
    required this.session,
    this.compatibleOnly = false,
    this.savedOnly = false,
    this.locationService = const GeolocatorDeviceLocationService(),
    super.key,
  });

  final AppSessionController session;
  final bool compatibleOnly, savedOnly;
  final DeviceLocationService locationService;

  @override
  State<MissionCatalogScreen> createState() => _MissionCatalogScreenState();
}

class _MissionCatalogScreenState extends State<MissionCatalogScreen>
    with WidgetsBindingObserver {
  static const _featuredCategories = [
    'arte',
    'musica',
    'gastronomia',
    'fotografia',
  ];
  static const _orders = {
    MissionCatalogOrder.recent: 'Más recientes',
    MissionCatalogOrder.startDate: 'Por fecha de inicio',
  };

  late final _catalog = MissionCatalogController(
    community: widget.session.communityRepository,
    missionMap: widget.session.missionMapRepository,
    location: widget.locationService,
    geocoding: widget.session.locationRepository,
    savedOnly: widget.savedOnly,
    initialTarget: widget.compatibleOnly
        ? widget.session.profile?.userType
        : null,
  );
  final _search = TextEditingController();
  final _scroll = ScrollController();
  bool _openingLocationSettings = false;
  final _catalogFocus = FocusNode(skipTraversal: true);

  List<String> get _categories => <String>{
    ..._featuredCategories.where(communityCategories.containsKey),
    ...communityCategories.keys,
  }.toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _catalog.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _catalog.dispose();
    _search.dispose();
    _scroll.dispose();
    _catalogFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _openingLocationSettings) {
      _openingLocationSettings = false;
      _catalog.locate();
    }
  }

  Future<void> _locationSettings() async {
    _openingLocationSettings = true;
    if (await _catalog.openLocationSettings() || !mounted) return;
    _openingLocationSettings = false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abre Ajustes para revisar el permiso de ubicación.'),
      ),
    );
  }

  Future<void> _filters() async {
    FocusScope.of(context).unfocus();
    final filters = await showMissionCatalogFilters(
      context,
      value: (radiusKm: _catalog.radiusKm, target: _catalog.target),
      viewerType: widget.session.profile?.userType,
    );
    if (!mounted || filters == null) return;
    _catalog.applyFilters(
      category: _catalog.category,
      radiusKm: filters.radiusKm,
      target: filters.target,
    );
  }

  void _selectCategory(String? category) => _catalog.applyFilters(
    category: category,
    radiusKm: _catalog.radiusKm,
    target: _catalog.target,
  );

  Future<void> _open(String path, {Map<String, String>? parameters}) async {
    // Restore focus to the viewport when a pushed route closes. Focusing a
    // toolbar button on return can scroll it into view and reset the offset.
    _catalogFocus.requestFocus();
    await context.push<void>(
      Uri(path: path, queryParameters: parameters).toString(),
    );
    if (mounted) await _catalog.reloadSaved();
  }

  void _openMap() => _open(
    '/map',
    parameters: {
      'from': 'missions',
      if (_catalog.query.isNotEmpty) 'q': _catalog.query,
      'category': ?_catalog.category,
    },
  );

  Future<void> _createMission() async {
    FocusScope.of(context).unfocus();
    final id = await context.push<String>('/missions/new');
    if (!mounted || id == null) return;
    final refreshed = _catalog.refresh();
    await _openMission(id);
    await refreshed;
  }

  MissionBookmark? _bookmark(String id) {
    if (!_catalog.canSave) return null;
    return (
      saved: _catalog.isSaved(id),
      onPressed: _catalog.isSaving(id)
          ? null
          : () async {
              final message = await _catalog.toggleSaved(id);
              if (mounted && message != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              }
            },
    );
  }

  Future<void> _openMission(String id) async {
    await _open('/missions/${Uri.encodeComponent(id)}');
    if (mounted) await _catalog.refreshMission(id);
  }

  Widget _catalogActions() => Wrap(
    spacing: 6,
    children: [
      TextButton.icon(
        onPressed: () => _open('/missions', parameters: {'section': 'saved'}),
        icon: const Icon(Icons.bookmark_border_rounded, size: 18),
        label: const Text('Guardadas'),
      ),
      TextButton.icon(
        onPressed: _createMission,
        icon: const Icon(Icons.add_rounded, size: 19),
        label: const Text('Crear misión'),
      ),
    ],
  );

  Widget _searchBar() => MissionCatalogSearchBar(
    text: _search,
    onChanged: _catalog.type,
    onSubmitted: (value) => _catalog.type(value, immediate: true),
    onFilters: _filters,
    activeFilterCount:
        (_catalog.target != null ? 1 : 0) +
        (_catalog.showNearby &&
                _catalog.radiusKm != MissionCatalogController.defaultRadius
            ? 1
            : 0),
  );

  Widget _catalogToolbar(BuildContext context) => MissionCatalogSectionHeader(
    title: _catalog.query.isEmpty ? 'Explorar misiones' : 'Resultados',
    actions: [
      if (!_catalog.showNearby) MissionCatalogMapButton(onPressed: _openMap),
      Semantics(
        value: _orders[_catalog.order],
        child: PopupMenuButton<MissionCatalogOrder>(
          tooltip: 'Ordenar',
          initialValue: _catalog.order,
          onSelected: _catalog.setOrder,
          itemBuilder: (_) => [
            for (final entry in _orders.entries)
              CheckedPopupMenuItem(
                value: entry.key,
                checked: entry.key == _catalog.order,
                child: Text(entry.value),
              ),
          ],
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ordenar',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandNavy,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: _catalog.order == MissionCatalogOrder.recent
                        ? AppColors.brandNavy
                        : AppColors.aquaDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _savedHeader(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Volver a misiones',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go('/missions'),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: const MissionCatalogSectionHeader(title: 'Misiones guardadas'),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.profileCanvas,
    child: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListenableBuilder(
            listenable: _catalog,
            builder: (context, _) {
              final page = _catalog.catalog;
              final items = page.items;
              final showFeatured =
                  _catalog.showNearby && _catalog.category == null;
              final featured = showFeatured
                  ? items
                        .where(
                          (item) => item.imagePath?.trim().isNotEmpty == true,
                        )
                        .firstOrNull
                  : null;
              final remaining = items
                  .where((item) => item.id != featured?.id)
                  .toList();
              final nearby = _nearbyPreview(remaining, featured?.id);
              final nearbyIds = nearby.map((item) => item.mission.id).toSet();
              final missions = remaining
                  .where((item) => !nearbyIds.contains(item.id))
                  .toList();
              final showProximity =
                  _catalog.showNearby &&
                  (nearby.isNotEmpty || _catalog.nearby.isEmpty);
              final hideEmptyResults =
                  (showFeatured || nearby.isNotEmpty) &&
                  missions.isEmpty &&
                  !page.waiting &&
                  !page.hasMore &&
                  page.error == null;
              return Focus(
                focusNode: _catalogFocus,
                child: RefreshIndicator(
                  color: AppColors.aquaDark,
                  onRefresh: _catalog.refresh,
                  child: CustomScrollView(
                    key: Key(
                      widget.savedOnly
                          ? 'saved-missions-scroll'
                          : 'mission-catalog-scroll',
                    ),
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      if (widget.savedOnly)
                        _box(_savedHeader(context), top: 10, bottom: 12)
                      else ...[
                        _box(_searchBar(), top: 8, bottom: 10),
                        SliverToBoxAdapter(
                          child: MissionCatalogCategories(
                            categories: _categories,
                            selected: _catalog.category,
                            onSelected: _selectCategory,
                          ),
                        ),
                        if (featured != null)
                          _box(
                            FeaturedMissionCard(
                              key: ValueKey('featured-mission-${featured.id}'),
                              mission: featured,
                              resolveImage: _catalog.community?.missionImageUrl,
                              bookmark: _bookmark(featured.id),
                              onOpen: () => _openMission(featured.id),
                            ),
                            top: 16,
                          )
                        else if (showFeatured && page.error == null)
                          _box(
                            page.waiting
                                ? const SizedBox(
                                    height: 116,
                                    child: MareaSkeleton(),
                                  )
                                : FeaturedMissionEmptyCard(
                                    hasMissions:
                                        items.isNotEmpty || nearby.isNotEmpty,
                                  ),
                            top: 16,
                          ),
                        if (showProximity)
                          SliverPadding(
                            padding: const EdgeInsets.only(top: 16),
                            sliver: SliverToBoxAdapter(
                              child: MissionProximityPanel(
                                catalog: _catalog,
                                missions: nearby,
                                onMap: _openMap,
                                onSettings: _locationSettings,
                                onOpen: _openMission,
                                bookmark: _bookmark,
                              ),
                            ),
                          ),
                        if (!hideEmptyResults)
                          _box(_catalogToolbar(context), top: 14),
                        _box(_catalogActions(), bottom: 6),
                      ],
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: missionCatalogInset,
                        ),
                        sliver: SliverList.builder(
                          itemCount: missions.length,
                          itemBuilder: (context, index) {
                            final mission = missions[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: MissionCatalogCard(
                                key: ValueKey(
                                  'mission-catalog-card-${mission.id}',
                                ),
                                mission: mission,
                                resolveImage:
                                    _catalog.community?.missionImageUrl,
                                distance: _catalog.distanceTo(mission),
                                bookmark: _bookmark(mission.id),
                                onOpen: () => _openMission(mission.id),
                              ),
                            );
                          },
                        ),
                      ),
                      if (!hideEmptyResults) _box(_feedback(missions.isEmpty)),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );

  List<NearbyMission> _nearbyPreview(
    List<Mission> catalog,
    String? featuredId,
  ) {
    if (!_catalog.showNearby) return const [];
    final preview = _catalog.nearby
        .where((item) => item.mission.id != featuredId)
        .take(3)
        .toList();
    final previewIds = preview.map((item) => item.mission.id).toSet();
    if (catalog.length > 1 &&
        catalog.every((item) => previewIds.contains(item.id))) {
      // Leave a result for Explorar when the whole catalog is in walking range.
      final catalogIds = catalog.map((item) => item.id).toSet();
      preview.removeAt(
        preview.lastIndexWhere((item) => catalogIds.contains(item.mission.id)),
      );
    }
    return preview;
  }

  Widget _feedback(bool empty) {
    final page = _catalog.catalog;
    if (page.waiting) {
      return empty
          ? const SizedBox(height: 104, child: MareaSkeleton())
          : const SizedBox(height: 20, child: MareaSkeleton(compact: true));
    }
    if (page.error case final error?) {
      return MissionCatalogNotice(
        message: error,
        action: 'Reintentar',
        onAction: _catalog.loadCatalog,
      );
    }
    if (page.hasMore) {
      return Center(
        child: TextButton(
          onPressed: _catalog.loadCatalog,
          child: const Text('Cargar más misiones'),
        ),
      );
    }
    if (empty) {
      final message = widget.savedOnly
          ? 'Aún no has guardado misiones.'
          : _catalog.query.isNotEmpty
          ? 'No encontramos misiones para esta búsqueda.'
          : 'No hay misiones disponibles con estos filtros.';
      return MissionCatalogNotice(
        message: message,
        action: _catalog.query.isNotEmpty ? 'Limpiar búsqueda' : null,
        onAction: _catalog.query.isNotEmpty
            ? () {
                _search.clear();
                _catalog.type('');
              }
            : null,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _box(Widget child, {double top = 0, double bottom = 0}) =>
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          missionCatalogInset,
          top,
          missionCatalogInset,
          bottom,
        ),
        sliver: SliverToBoxAdapter(child: child),
      );
}
