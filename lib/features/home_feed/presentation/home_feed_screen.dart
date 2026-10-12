import 'package:marea/features/community/models/mission_social.dart';
import 'package:marea/features/home_feed/data/home_feed_repository.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/home_feed/models/home_feed_models.dart';
import 'package:marea/features/home_feed/presentation/stories_rail.dart';
import 'package:marea/features/home_feed/presentation/mission_feed_card.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/shared/widgets/marea_panel.dart';
import 'package:marea/shared/widgets/marea_refresh_indicator.dart';
import 'package:marea/shared/widgets/marea_skeleton.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({required this.controller, super.key});
  final AppSessionController controller;
  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final _scroll = ScrollController();
  final _legacyPosts = GlobalKey<PostsFeedState>();
  final _stories = GlobalKey<StoriesRailState>();
  final _entries = <HomeFeedEntry>[];
  final _authors = <String, CommunityProfile>{};
  final _stats = <String, PostSocialStats>{};
  final _missionStats = <String, MissionSocialStats>{};
  Set<String> _saved = {}, _savedMissions = {};
  HomeFeedMode _mode = HomeFeedMode.forYou;
  HomeFeedKind _kind = HomeFeedKind.all;
  String? _category, _error, _locationError;
  String? _viewerId;
  double? _latitude, _longitude;
  int _radius = 10, _generation = 0, _revision = 0;
  bool _loading = false, _locating = false;
  Map<String, dynamic>? _cursor;
  Timer? _expiry;
  HomeFeedFilter get _filter => HomeFeedFilter(
    mode: _mode,
    kind: _kind,
    category: _category,
    latitude: _latitude,
    longitude: _longitude,
    radiusKm: _radius,
  );
  @override
  void initState() {
    super.initState();
    _viewerId = widget.controller.profile?.id;
    _latitude = widget.controller.profile?.locationLatitude;
    _longitude = widget.controller.profile?.locationLongitude;
    _revision = widget.controller.homeFeedRevision;
    widget.controller.addListener(_sessionChanged);
    _scroll.addListener(_onScroll);
    _load(reset: true);
    _expiry = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _entries.any((e) => e.mission?.isExpired == true)) {
        setState(
          () => _entries.removeWhere((e) => e.mission?.isExpired == true),
        );
      }
    });
  }

  void _sessionChanged() {
    final viewerId = widget.controller.profile?.id;
    if (_viewerId != viewerId) {
      _viewerId = viewerId;
      _revision = widget.controller.homeFeedRevision;
      ++_generation;
      setState(() {
        _entries.clear();
        _authors.clear();
        _stats.clear();
        _missionStats.clear();
        _saved = {};
        _savedMissions = {};
        _cursor = null;
        _error = null;
        _locationError = null;
        _loading = false;
        _mode = HomeFeedMode.forYou;
        _kind = HomeFeedKind.all;
        _category = null;
        _latitude = widget.controller.profile?.locationLatitude;
        _longitude = widget.controller.profile?.locationLongitude;
      });
      if (viewerId != null) _load(reset: true);
      return;
    }
    if (_revision == widget.controller.homeFeedRevision) return;
    _revision = widget.controller.homeFeedRevision;
    _refresh();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sessionChanged);
    _expiry?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 600 &&
        !_loading &&
        _cursor != null &&
        _error == null) {
      _load();
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      widget.controller.homeFeedRepository == null
          ? (_legacyPosts.currentState?.reload() ?? Future<void>.value())
          : _load(reset: true),
      _stories.currentState?.reload() ?? Future<void>.value(),
    ]);
  }

  Future<void> _load({bool reset = false}) async {
    if (widget.controller.status == AuthStatus.unauthenticated) return;
    final repo = widget.controller.homeFeedRepository;
    if (repo == null) return;
    if (!reset && (_loading || _cursor == null)) return;
    if (_filter.validate() != null) return;
    final generation = ++_generation;
    final filter = _filter;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await repo.page(filter, cursor: reset ? null : _cursor);
      final community = widget.controller.communityRepository;
      final postIds = page.entries
          .where((e) => e.post != null)
          .map((e) => e.id)
          .toList();
      final results = await Future.wait<dynamic>([
        community?.profiles(
              ids: page.entries.map((e) => e.authorId).toSet().toList(),
            ) ??
            Future.value(<CommunityProfile>[]),
        widget.controller.socialRepository?.stats(postIds) ??
            Future.value(<String, PostSocialStats>{}),
        community?.savedPostIds() ?? Future.value(<String>{}),
        community?.savedMissionIds() ?? Future.value(<String>{}),
        widget.controller.missionSocialRepository?.stats(
              page.entries
                  .where((e) => e.mission != null)
                  .map((e) => e.id)
                  .toList(),
            ) ??
            Future.value(<String, MissionSocialStats>{}),
      ]);
      if (!mounted || generation != _generation) return;
      setState(() {
        if (reset) {
          _entries.clear();
          _authors.clear();
          _stats.clear();
          _missionStats.clear();
        }
        final seen = _entries.map((e) => e.key).toSet();
        _entries.addAll(page.entries.where((e) => seen.add(e.key)));
        _authors.addEntries(
          (results[0] as List<CommunityProfile>).map((p) => MapEntry(p.id, p)),
        );
        _stats.addAll(results[1] as Map<String, PostSocialStats>);
        _missionStats.addAll(results[4] as Map<String, MissionSocialStats>);
        _saved = results[2] as Set<String>;
        _savedMissions = results[3] as Set<String>;
        _cursor = page.cursor;
        _loading = false;
      });
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() {
          if (e is HomeFeedCursorExpired) {
            _cursor = null;
            _error = e.toString();
          } else {
            _error = communityError(e);
          }
          _loading = false;
        });
      }
    }
  }

  Future<void> _select(HomeFeedMode mode) async {
    if (mode == _mode) return;
    ++_generation;
    setState(() {
      _mode = mode;
      _entries.clear();
      _cursor = null;
      _error = null;
      _loading = false;
    });
    if (mode == HomeFeedMode.nearby &&
        (_latitude == null || _longitude == null)) {
      await _locate();
    } else {
      await _load(reset: true);
    }
  }

  Future<void> _locate() async {
    final generation = _generation;
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final position = await const GeolocatorDeviceLocationService().current(
        requestPermission: true,
        isCurrent: () => mounted && generation == _generation,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      await _load(reset: true);
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(
          () => _locationError = e is DeviceLocationFailure
              ? e.message
              : communityError(e),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickLocation() async {
    final point = await showCommunityLocationPicker(
      context,
      repository: widget.controller.locationRepository,
      initial: _latitude == null || _longitude == null
          ? null
          : PostLocationSelection(
              label: 'Punto elegido',
              coordinates: PostCoordinates(
                latitude: _latitude!,
                longitude: _longitude!,
                precision: PostLocationPrecision.approximate,
              ),
            ),
    );
    if (!mounted || point == null) return;
    setState(() {
      _latitude = point.coordinates.latitude;
      _longitude = point.coordinates.longitude;
      _locationError = null;
    });
    if (_mode == HomeFeedMode.nearby) await _load(reset: true);
  }

  Future<void> _filters() async {
    var category = _category;
    var kind = _kind;
    var radius = _radius;
    final applied = await showMareaBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filtrar Inicio',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text('Contenido'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final value in HomeFeedKind.values)
                    ChoiceChip(
                      label: Text(switch (value) {
                        HomeFeedKind.all => 'Todo',
                        HomeFeedKind.post => 'Publicaciones',
                        HomeFeedKind.mission => 'Misiones',
                      }),
                      selected: kind == value,
                      onSelected: (_) => update(() => kind = value),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Categoría'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: category == null,
                    onSelected: (_) => update(() => category = null),
                  ),
                  for (final entry in communityCategories.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: category == entry.key,
                      onSelected: (_) => update(() => category = entry.key),
                    ),
                ],
              ),
              if (_mode == HomeFeedMode.nearby) ...[
                const SizedBox(height: 16),
                const Text('Distancia'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final km in [5, 10, 25, 50])
                      ChoiceChip(
                        label: Text('$km km'),
                        selected: radius == km,
                        onSelected: (_) => update(() => radius = km),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Aplicar filtros'),
              ),
              TextButton(
                onPressed: () => update(() {
                  category = null;
                  kind = HomeFeedKind.all;
                  radius = 10;
                }),
                child: const Text('Restablecer'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || applied != true) return;
    ++_generation;
    setState(() {
      _category = category;
      _kind = kind;
      _radius = radius;
      _entries.clear();
      _cursor = null;
      _loading = false;
    });
    await _load(reset: true);
  }

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StoriesRail(key: _stories, controller: widget.controller),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final mode in HomeFeedMode.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(switch (mode) {
                          HomeFeedMode.forYou => 'Para ti',
                          HomeFeedMode.nearby => 'Cerca',
                          HomeFeedMode.following => 'Siguiendo',
                          HomeFeedMode.trending => 'Tendencias',
                        }),
                        selected: _mode == mode,
                        showCheckmark: false,
                        selectedColor: AppColors.brandNavy,
                        backgroundColor: const Color(0xFFF0F5FB),
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        labelStyle: TextStyle(
                          color: _mode == mode
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        onSelected: (_) => _select(mode),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Filtrar Inicio',
            onPressed: _filters,
            icon: Badge(
              isLabelVisible: _category != null || _kind != HomeFeedKind.all,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      if (_mode == HomeFeedMode.nearby) ...[
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              'A $_radius km',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            TextButton.icon(
              onPressed: _locating ? null : _locate,
              icon: const Icon(Icons.my_location, size: 18),
              label: Text(_locating ? 'Localizando…' : 'Mi ubicación'),
            ),
            TextButton(
              onPressed: _pickLocation,
              child: const Text('Elegir punto'),
            ),
          ],
        ),
        if (_locationError != null) CommunityNotice(message: _locationError!),
      ],
      if (widget.controller.profile?.role == ProfileRole.admin)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () async {
              await context.push('/moderation');
              if (mounted) _refresh();
            },
            icon: const Icon(Icons.shield_outlined),
            label: const Text('Moderación'),
          ),
        ),
      const SizedBox(height: 12),
    ],
  );
  Widget _entry(HomeFeedEntry entry) {
    final repo = widget.controller.communityRepository;
    if (repo == null) {
      return const CommunityNotice(message: 'La comunidad no está disponible.');
    }
    if (entry.mission != null) {
      return MissionFeedCard(
        key: ValueKey(entry.key),
        mission: entry.mission!,
        stats: _missionStats[entry.id],
        onStats: (value) => _missionStats[entry.id] = value,
        author: _authors[entry.authorId],
        controller: widget.controller,
        saved: _savedMissions.contains(entry.id),
        onSaved: (value) {
          if (mounted) {
            setState(() {
              if (value) {
                _savedMissions.add(entry.id);
              } else {
                _savedMissions.remove(entry.id);
              }
            });
          }
        },
        onChanged: () => _load(reset: true),
      );
    }
    return PostCard(
      key: ValueKey(entry.key),
      post: entry.post!,
      homePresentation: true,
      locationRepository: widget.controller.locationRepository,
      author: _authors[entry.authorId],
      repository: repo,
      viewerId: widget.controller.profile?.id,
      saved: _saved.contains(entry.id),
      socialRepository: widget.controller.socialRepository,
      mediaRepository: widget.controller.mediaRepository,
      stats: _stats[entry.id],
      publicUrl: widget.controller.publicUrl,
      moderator: widget.controller.profile?.role == ProfileRole.admin,
      onStats: (value) => _stats[entry.id] = value,
      onChanged: () => _load(reset: true),
      onSaved: (value) {
        if (mounted) {
          setState(() {
            if (value) {
              _saved.add(entry.id);
            } else {
              _saved.remove(entry.id);
            }
          });
        }
      },
    );
  }

  Widget _footer() => Column(
    children: [
      if (_loading)
        const Padding(
          padding: EdgeInsets.all(24),
          child: MareaSkeleton(kind: SkeletonKind.post),
        ),
      if (_error != null)
        CommunityNotice(
          message: _error!,
          onRetry: () => _load(reset: _entries.isEmpty || _cursor == null),
        ),
      if (!_loading && _error == null && _entries.isEmpty)
        CommunityNotice(
          message: _mode == HomeFeedMode.following
              ? 'No hay contenido de personas que sigues. Encuentra personas en Explorar y pulsa Seguir.'
              : _mode == HomeFeedMode.nearby &&
                    (_latitude == null || _longitude == null)
              ? 'Elige tu ubicación para ver qué hay cerca.'
              : 'No hay contenido con estos filtros. Vuelve más tarde o cambia los filtros.',
        ),
      if (!_loading && _cursor != null && _error == null)
        TextButton(onPressed: _load, child: const Text('Cargar más')),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    if (widget.controller.homeFeedRepository == null) {
      return CommunityPage(
        title: '',
        maxWidth: 820,
        children: [
          _header(),
          PostsFeed(
            key: _legacyPosts,
            controller: widget.controller,
            showHeading: false,
            showRefresh: false,
          ),
        ],
      );
    }
    return MareaRefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(6, 4, 6, bottom + 32),
        itemCount: _entries.length + 2,
        itemBuilder: (_, index) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: index == 0
                ? _header()
                : index == _entries.length + 1
                ? _footer()
                : _entry(_entries[index - 1]),
          ),
        ),
      ),
    );
  }
}
