import 'package:marea/core/localization/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/community/presentation/posts_feed.dart';
import 'package:marea/features/home_feed/data/home_feed_repository.dart';
import 'package:marea/features/home_feed/models/home_feed_models.dart';
import 'package:marea/features/home_feed/presentation/home_feed_controls.dart';
import 'package:marea/features/home_feed/presentation/stories_rail.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/shared/widgets/marea_refresh_indicator.dart';
import 'package:marea/shared/widgets/marea_skeleton.dart';
import 'package:marea/shared/widgets/marea_surface.dart';

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
  final _posts = <CommunityPost>[];
  final _authors = <String, CommunityProfile>{};
  final _stats = <String, PostSocialStats>{};
  Set<String> _saved = {};
  HomeFeedMode _mode = HomeFeedMode.forYou;
  String? _category, _error, _locationError;
  String? _viewerId;
  double? _latitude, _longitude;
  int _radius = 10, _generation = 0, _revision = 0, _locationRequest = 0;
  bool _loading = false, _locating = false;
  Map<String, dynamic>? _cursor;

  bool get _hasLocation => _latitude != null && _longitude != null;

  HomeFeedFilter get _filter => HomeFeedFilter(
    mode: _mode,
    kind: HomeFeedKind.post,
    category: _category,
    latitude: _mode == HomeFeedMode.nearby ? _latitude : null,
    longitude: _mode == HomeFeedMode.nearby ? _longitude : null,
    radiusKm: _mode == HomeFeedMode.nearby ? _radius : 10,
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
  }

  void _sessionChanged() {
    final profile = widget.controller.profile;
    if (_viewerId != profile?.id) {
      _viewerId = profile?.id;
      _revision = widget.controller.homeFeedRevision;
      ++_generation;
      ++_locationRequest;
      setState(() {
        _posts.clear();
        _authors.clear();
        _stats.clear();
        _saved = {};
        _cursor = null;
        _error = null;
        _locationError = null;
        _loading = false;
        _locating = false;
        _mode = HomeFeedMode.forYou;
        _category = null;
        _radius = 10;
        _latitude = profile?.locationLatitude;
        _longitude = profile?.locationLongitude;
      });
      if (_viewerId != null) _refresh();
      return;
    }
    if (_revision == widget.controller.homeFeedRevision) return;
    _revision = widget.controller.homeFeedRevision;
    _refresh();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sessionChanged);
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
    if (repo == null || (!reset && (_loading || _cursor == null))) return;
    final filter = _filter;
    if (filter.validate() != null) return;

    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) _cursor = null;
    });
    try {
      final page = await repo.page(filter, cursor: _cursor);
      if (!mounted || generation != _generation) return;
      final posts = page.entries.map((entry) => entry.post).nonNulls.toList();
      final community = widget.controller.communityRepository;
      final postIds = posts.map((post) => post.id).toSet().toList();
      final authorIds = posts.map((post) => post.authorId).toSet().toList();
      final authorsFuture = authorIds.isEmpty
          ? Future.value(<CommunityProfile>[])
          : community?.profiles(ids: authorIds) ??
                Future.value(<CommunityProfile>[]);
      final statsFuture = postIds.isEmpty
          ? Future.value(<String, PostSocialStats>{})
          : widget.controller.socialRepository?.stats(postIds) ??
                Future.value(<String, PostSocialStats>{});
      final savedFuture = postIds.isEmpty
          ? Future.value(_saved)
          : community?.savedPostIds() ?? Future.value(<String>{});
      final results = await Future.wait<Object>([
        authorsFuture,
        statsFuture,
        savedFuture,
      ]);
      final authors = results[0] as List<CommunityProfile>;
      final stats = results[1] as Map<String, PostSocialStats>;
      final saved = results[2] as Set<String>;
      if (!mounted || generation != _generation) return;
      setState(() {
        if (reset) {
          _posts.clear();
          _authors.clear();
          _stats.clear();
        }
        final seen = _posts.map((post) => post.id).toSet();
        _posts.addAll(posts.where((post) => seen.add(post.id)));
        _authors.addEntries(
          authors.map((profile) => MapEntry(profile.id, profile)),
        );
        _stats.addAll(stats);
        _saved = {...saved};
        _cursor = page.cursor;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        if (error is HomeFeedCursorExpired) _cursor = null;
        _error = error is HomeFeedCursorExpired
            ? error.toString()
            : communityError(error);
        _loading = false;
      });
    }
  }

  Future<void> _changeFeed(
    VoidCallback update, {
    bool scrollToTop = true,
  }) async {
    ++_generation;
    setState(() {
      update();
      _posts.clear();
      _cursor = null;
      _error = null;
      _loading = false;
    });
    if (scrollToTop && _scroll.hasClients) _scroll.jumpTo(0);
    await _load(reset: true);
  }

  void _select(HomeFeedMode mode) {
    if (mode == _mode) return;
    ++_locationRequest;
    _changeFeed(() {
      _mode = mode;
      _locating = false;
      _locationError = null;
    });
  }

  void _applyCategory(String? category) {
    if (category == _category) return;
    _changeFeed(() => _category = category);
  }

  Future<void> _locate() async {
    final request = ++_locationRequest;
    bool isCurrent() => mounted && request == _locationRequest;
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final position = await const GeolocatorDeviceLocationService().current(
        requestPermission: true,
        isCurrent: isCurrent,
      );
      if (!isCurrent()) return;
      await _changeFeed(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locating = false;
      }, scrollToTop: false);
    } catch (error) {
      if (!isCurrent()) return;
      setState(() {
        _locating = false;
        _locationError = error is DeviceLocationFailure
            ? error.message
            : communityError(error);
      });
    }
  }

  Future<void> _pickLocation() async {
    final request = ++_locationRequest;
    if (_locating) setState(() => _locating = false);
    final point = await showCommunityLocationPicker(
      context,
      repository: widget.controller.locationRepository,
      initial: !_hasLocation
          ? null
          : PostLocationSelection(
              label: AppLocalizations.tr('Punto elegido'),
              coordinates: PostCoordinates(
                latitude: _latitude!,
                longitude: _longitude!,
                precision: PostLocationPrecision.approximate,
              ),
            ),
    );
    if (!mounted || request != _locationRequest || point == null) return;
    await _changeFeed(() {
      _latitude = point.coordinates.latitude;
      _longitude = point.coordinates.longitude;
      _locationError = null;
    }, scrollToTop: false);
  }

  void _searchPosts() {
    context.push(
      Uri(
        path: '/search/posts',
        queryParameters: _category == null ? null : {'category': _category!},
      ).toString(),
    );
  }

  Future<void> _filters() async {
    final viewer = _viewerId;
    final mode = _mode;
    final filters = await showHomeFeedFilters(
      context,
      category: _category,
      radius: _radius,
      nearby: mode == HomeFeedMode.nearby,
    );
    if (!mounted || filters == null || viewer != _viewerId || mode != _mode) {
      return;
    }
    if (filters.category == _category && filters.radius == _radius) return;
    await _changeFeed(() {
      _category = filters.category;
      _radius = filters.radius;
    });
  }

  Widget _locationControls() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          if (_hasLocation)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Text(
                'Radio de $_radius km',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          TextButton.icon(
            onPressed: _locating ? null : _locate,
            icon: const Icon(Icons.my_location_rounded, size: 18),
            label: Text(_locating ? 'Localizando…' : 'Mi ubicación'),
          ),
          if (_hasLocation)
            TextButton(
              onPressed: _pickLocation,
              child: Text(AppLocalizations.tr('Elegir punto')),
            ),
        ],
      ),
      if (_locationError != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _locationError!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
    ],
  );

  Widget _entry(CommunityPost post) {
    final repo = widget.controller.communityRepository;
    if (repo == null) {
      return CommunityNotice(
        message: AppLocalizations.tr('La comunidad no está disponible.'),
      );
    }
    return PostCard(
      key: ValueKey(post.id),
      post: post,
      homePresentation: true,
      locationRepository: widget.controller.locationRepository,
      author: _authors[post.authorId],
      repository: repo,
      viewerId: _viewerId,
      saved: _saved.contains(post.id),
      socialRepository: widget.controller.socialRepository,
      mediaRepository: widget.controller.mediaRepository,
      stats: _stats[post.id],
      publicUrl: widget.controller.publicUrl,
      contentTranslator: widget.controller.postContentTranslator,
      moderator: widget.controller.profile?.role == ProfileRole.admin,
      onHomeCategory: _applyCategory,
      onStats: (value) => _stats[post.id] = value,
      onChanged: () => _load(reset: true),
      onSaved: (value) {
        if (!mounted) return;
        setState(() {
          if (value) {
            _saved.add(post.id);
          } else {
            _saved.remove(post.id);
          }
        });
      },
    );
  }

  Widget _empty() {
    final (icon, message, action, onAction) = switch ((
      _mode,
      _hasLocation,
      _category,
    )) {
      (HomeFeedMode.nearby, false, _) => (
        Icons.place_outlined,
        'Elige un punto para ver publicaciones cercanas.',
        'Elegir punto',
        _pickLocation,
      ),
      (_, _, String()) => (
        Icons.filter_alt_off_outlined,
        'No hay publicaciones de esta categoría en esta vista.',
        'Quitar filtro',
        () => _applyCategory(null),
      ),
      (HomeFeedMode.following, _, _) => (
        Icons.people_outline_rounded,
        'Aún no hay publicaciones de perfiles que sigues.',
        'Explorar perfiles',
        () => context.push('/explore?section=people'),
      ),
      (HomeFeedMode.nearby, _, _) => (
        Icons.place_outlined,
        'Aún no hay publicaciones en este radio.',
        'Elegir punto',
        _pickLocation,
      ),
      (HomeFeedMode.trending, _, _) => (
        Icons.trending_up_rounded,
        'Aún no hay publicaciones en tendencias.',
        'Ver Para ti',
        () => _select(HomeFeedMode.forYou),
      ),
      _ => (
        Icons.edit_note_rounded,
        'Aún no hay publicaciones para ti.',
        null,
        null,
      ),
    };
    return _FeedNotice(
      icon: icon,
      message: message,
      action: action,
      onAction: onAction,
    );
  }

  Widget _footer() {
    if (_loading) {
      return const MareaSurface(
        color: AppColors.surface,
        radius: 20,
        child: MareaSkeleton(kind: SkeletonKind.post),
      );
    }
    if (_error != null) {
      return _FeedNotice(
        icon: Icons.error_outline_rounded,
        message: _error!,
        action: 'Reintentar',
        onAction: () => _load(reset: _cursor == null),
      );
    }
    if (_cursor != null) {
      return Center(
        child: TextButton(onPressed: _load, child: const Text('Cargar más')),
      );
    }
    return _posts.isEmpty ? _empty() : const SizedBox.shrink();
  }

  Widget _inColumn(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 712),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final paginated = widget.controller.homeFeedRepository != null;
    return ColoredBox(
      color: AppColors.profileCanvas,
      child: MareaRefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          key: const Key('home-feed-scroll'),
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: _inColumn(
                StoriesRail(key: _stories, controller: widget.controller),
              ),
            ),
            if (widget.controller.profile?.role == ProfileRole.admin)
              SliverToBoxAdapter(
                child: _inColumn(
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      icon: const Icon(Icons.shield_outlined, size: 18),
                      label: const Text('Moderación'),
                      onPressed: () async {
                        await context.push('/moderation');
                        if (mounted) await _refresh();
                      },
                    ),
                  ),
                ),
              ),
            if (paginated) ...[
              PinnedHeaderSliver(
                child: ColoredBox(
                  color: AppColors.profileCanvas,
                  child: _inColumn(
                    HomeFeedControls(
                      mode: _mode,
                      category: _category,
                      hasCustomRadius:
                          _mode == HomeFeedMode.nearby && _radius != 10,
                      onMode: _select,
                      onFilters: _filters,
                      onSearch: _searchPosts,
                      onClearCategory: () => _applyCategory(null),
                    ),
                  ),
                ),
              ),
              if (_mode == HomeFeedMode.nearby)
                SliverToBoxAdapter(child: _inColumn(_locationControls())),
              SliverList.builder(
                itemCount: _posts.length,
                itemBuilder: (_, index) => _inColumn(_entry(_posts[index])),
              ),
              SliverToBoxAdapter(child: _inColumn(_footer())),
            ] else ...[
              if (widget.controller.communityRepository != null)
                SliverToBoxAdapter(
                  child: _inColumn(
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: _searchPosts,
                        icon: const Icon(Icons.search_rounded),
                        label: Text(
                          AppLocalizations.tr('Buscar publicaciones'),
                        ),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: _inColumn(
                  PostsFeed(
                    key: _legacyPosts,
                    controller: widget.controller,
                    showHeading: false,
                    showRefresh: false,
                    homePresentation: true,
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).bottom + 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedNotice extends StatelessWidget {
  const _FeedNotice({
    required this.icon,
    required this.message,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => MareaSurface(
    color: AppColors.surface,
    radius: 20,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    child: Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, color: AppColors.aquaDark, size: 24),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          liveRegion: true,
          child: Text(
            AppLocalizations.tr(message),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.brandNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (action case final label?)
          TextButton(
            onPressed: onAction,
            child: Text(AppLocalizations.tr(label)),
          ),
      ],
    ),
  );
}
