import 'package:marea/features/home_feed/presentation/feed_city_label.dart';
import 'package:marea/features/location/data/location_repository.dart';
import 'package:marea/features/home_feed/presentation/home_feed_screen.dart';
import 'package:marea/shared/widgets/marea_panel.dart';
import 'package:marea/shared/widgets/marea_action_button.dart';
import 'package:marea/shared/widgets/marea_skeleton.dart';
import 'package:marea/core/config/app_config.dart';
import 'reaction_button.dart';
import 'package:marea/features/community/data/social_repository.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/community/presentation/social_panels.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/shared/widgets/profile_image.dart';
import 'package:marea/shared/widgets/marea_surface.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/category_visuals.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/profile/models/profile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.controller, super.key});
  final AppSessionController controller;
  @override
  Widget build(BuildContext context) => HomeFeedScreen(controller: controller);
}

class PostsFeed extends StatefulWidget {
  const PostsFeed({
    required this.controller,
    this.authorId,
    this.query = '',
    this.category,
    this.savedOnly = false,
    this.discoverOnly = false,
    this.showHeading = true,
    this.showRefresh = true,
    this.homePresentation = false,
    super.key,
  });
  final AppSessionController controller;
  final String? authorId, category;
  final String query;
  final bool savedOnly,
      discoverOnly,
      showHeading,
      showRefresh,
      homePresentation;
  @override
  State<PostsFeed> createState() => PostsFeedState();
}

class PostsFeedState extends State<PostsFeed> {
  final _posts = <CommunityPost>[];
  final _authors = <String, CommunityProfile>{};
  final _stats = <String, PostSocialStats>{};
  Set<String> _saved = {};
  bool _loading = true, _more = true;
  String? _error;
  int _generation = 0;
  CommunityRepository? get _repo => widget.controller.communityRepository;
  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void didUpdateWidget(PostsFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authorId != widget.authorId ||
        oldWidget.query != widget.query ||
        oldWidget.category != widget.category ||
        oldWidget.savedOnly != widget.savedOnly ||
        oldWidget.discoverOnly != widget.discoverOnly ||
        oldWidget.controller != widget.controller) {
      _load(reset: true);
    }
  }

  Future<void> _load({bool reset = false}) async {
    final repo = _repo;
    if (repo == null) {
      setState(() {
        _loading = false;
        _error =
            'Las publicaciones no están disponibles. Vuelve a iniciar la aplicación.';
      });
      return;
    }
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await repo.posts(
        authorId: widget.authorId,
        query: widget.query,
        category: widget.category,
        savedOnly: widget.savedOnly,
        discoverOnly: widget.discoverOnly,
        offset: reset ? 0 : _posts.length,
      );
      final authors = posts.isEmpty
          ? <CommunityProfile>[]
          : await repo.profiles(
              ids: posts.map((p) => p.authorId).toSet().toList(),
            );
      final saved = await repo.savedPostIds();
      final stats = await widget.controller.socialRepository?.stats(
        posts.map((p) => p.id).toList(),
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        if (reset) {
          _posts.clear();
          _authors.clear();
          _stats.clear();
        }
        _posts.addAll(posts);
        if (stats != null) _stats.addAll(stats);
        _authors.addEntries(authors.map((p) => MapEntry(p.id, p)));
        _saved = saved;
        _more = posts.length == 30;
        _loading = false;
      });
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = communityError(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> reload() => _load(reset: true);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.showHeading || widget.showRefresh)
        Row(
          children: [
            if (widget.showHeading)
              Expanded(
                child: Text(
                  widget.authorId != null
                      ? 'Publicaciones'
                      : widget.savedOnly
                      ? 'Tus guardados'
                      : 'Publicaciones recientes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              )
            else
              const Spacer(),
            if (widget.showRefresh)
              IconButton(
                tooltip: 'Actualizar publicaciones',
                onPressed: _loading ? null : () => _load(reset: true),
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
      if (widget.showHeading) const SizedBox(height: 12),
      for (final post in _posts)
        PostCard(
          key: ValueKey(post.id),
          post: post,
          homePresentation: widget.homePresentation,
          locationRepository: widget.homePresentation
              ? widget.controller.locationRepository
              : null,
          author: _authors[post.authorId],
          repository: _repo!,
          viewerId: widget.controller.profile?.id,
          saved: _saved.contains(post.id),
          socialRepository: widget.controller.socialRepository,
          mediaRepository: widget.controller.mediaRepository,
          stats: _stats[post.id],
          publicUrl: widget.controller.publicUrl,
          moderator: widget.controller.profile?.role == ProfileRole.admin,
          onStats: (stats) => _stats[post.id] = stats,
          onChanged: () => _load(reset: true),
          onSaved: (saved) {
            setState(() {
              if (saved) {
                _saved.add(post.id);
              } else {
                _saved.remove(post.id);
                if (widget.savedOnly) {
                  // Keep the row available while its save operation can be undone.
                }
              }
            });
          },
          onSaveSettled: (saved) {
            if (mounted && widget.savedOnly && !saved) {
              setState(() => _posts.removeWhere((p) => p.id == post.id));
            }
          },
        ),
      if (_error != null)
        CommunityNotice(
          message: _error!,
          onRetry: () => _load(reset: _posts.isEmpty),
        ),
      if (_loading && _posts.isEmpty)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: MareaSkeleton(kind: SkeletonKind.post)),
        )
      else if (_error == null && _posts.isEmpty)
        CommunityNotice(
          message: widget.savedOnly
              ? 'Guarda las publicaciones que te interesen para encontrarlas aquí.'
              : widget.authorId != null
              ? 'Este espacio está listo para sus primeras publicaciones.'
              : 'Todavía no hay publicaciones con estos filtros. Comparte la primera idea.',
        ),
      if (!_loading && _more && _posts.isNotEmpty)
        TextButton(
          onPressed: _load,
          child: const Text('Cargar más publicaciones'),
        ),
    ],
  );
}

class PostCard extends StatefulWidget {
  const PostCard({
    required this.post,
    required this.repository,
    required this.viewerId,
    required this.saved,
    required this.onChanged,
    this.onSaved,
    this.onSaveSettled,
    this.author,
    this.socialRepository,
    this.mediaRepository,
    this.stats,
    this.onStats,
    this.homePresentation = false,
    this.onHomeCategory,
    this.locationRepository,
    this.moderator = false,
    this.publicUrl = 'https://marea-azul.netlify.app/',
    super.key,
  });
  final CommunityPost post;
  final CommunityProfile? author;
  final CommunityRepository repository;
  final SocialRepository? socialRepository;
  final ProfileMediaRepository? mediaRepository;
  final LocationRepository? locationRepository;
  final PostSocialStats? stats;
  final ValueChanged<PostSocialStats>? onStats;
  final String? viewerId;
  final String publicUrl;
  final bool saved, moderator, homePresentation;
  final Future<void> Function() onChanged;
  final ValueChanged<bool>? onSaved, onSaveSettled;
  final ValueChanged<String>? onHomeCategory;
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _busy = false, _expanded = false, _panel = false;
  late bool _saved = widget.saved;
  late PostSocialStats? _stats = widget.stats;
  final _draft = CommentDraft();
  Future<String>? _url;
  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _loadImage() {
    _homeImageFailed = false;
    _url = widget.post.imagePath == null
        ? null
        : widget.repository.imageUrl(widget.post.imagePath!);
  }

  @override
  void didUpdateWidget(PostCard old) {
    super.didUpdateWidget(old);
    _saved = widget.saved;
    if (old.viewerId != widget.viewerId || old.post.id != widget.post.id) {
      ++_reactionGeneration;
      _reacting = false;
      _stats = widget.stats;
      _draft.clear();
      _draft.operationId = null;
      _draft.submitted = null;
    }
    if (old.stats != widget.stats && !_reacting) _stats = widget.stats;
    if (old.post.imagePath != widget.post.imagePath) _loadImage();
  }

  Future<void> _action(
    Future<void> Function() action, {
    bool reload = true,
    String? success,
  }) async {
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    final ok = await runCommunityAction(context, action, success: success);
    if (mounted) setState(() => _busy = false);
    if (ok && mounted && reload) await widget.onChanged();
  }

  Future<void> _refreshStats() async {
    final social = widget.socialRepository;
    if (social == null) return;
    final stats = await social.stats([widget.post.id]);
    if (!mounted) return;
    setState(() => _stats = stats[widget.post.id]);
    if (_stats != null) widget.onStats?.call(_stats!);
  }

  PostReaction? _desiredReaction;
  bool _reacting = false;
  int _reactionRevision = 0, _reactionGeneration = 0;

  PostSocialStats _withReaction(PostSocialStats before, PostReaction? value) =>
      PostSocialStats(
        postId: before.postId,
        reactionCount:
            (before.reactionCount +
                    (before.myReaction == null && value != null ? 1 : 0) -
                    (before.myReaction != null && value == null ? 1 : 0))
                .clamp(0, 1 << 31),
        commentCount: before.commentCount,
        myReaction: value,
        interestSent: before.interestSent,
      );

  Future<void> _react(PostReaction? value) async {
    _desiredReaction = value;
    ++_reactionRevision;
    final before = _stats;
    final optimistic = _withReaction(
      _stats ?? PostSocialStats(postId: widget.post.id),
      value,
    );
    setState(() => _stats = optimistic);
    widget.onStats?.call(optimistic);
    if (_reacting) return;
    _reacting = true;
    final generation = _reactionGeneration;
    final social = widget.socialRepository!;
    final postId = widget.post.id;
    // Serialize writes. A later tap updates the UI immediately and is sent next.
    var confirmed = before ?? PostSocialStats(postId: widget.post.id);
    while (mounted && generation == _reactionGeneration) {
      final revision = _reactionRevision;
      final target = _desiredReaction;
      try {
        await social.setReaction(postId, target);
        confirmed = _withReaction(confirmed, target);
      } catch (error) {
        if (!mounted || generation != _reactionGeneration) break;
        if (revision == _reactionRevision) {
          setState(() => _stats = confirmed);
          widget.onStats?.call(confirmed);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(communityError(error))));
        }
      }
      if (!mounted || generation != _reactionGeneration) break;
      if (revision == _reactionRevision) {
        // A successful write is authoritative; a failed refresh must not undo it.
        try {
          final rows = await social.stats([postId]);
          if (mounted &&
              generation == _reactionGeneration &&
              revision == _reactionRevision &&
              rows[widget.post.id] != null) {
            setState(() => _stats = rows[widget.post.id]);
            widget.onStats?.call(_stats!);
          }
        } catch (_) {}
        if (revision == _reactionRevision) break;
      }
    }
    if (generation == _reactionGeneration) _reacting = false;
  }

  Future<void> _comments() async {
    if (_panel || widget.socialRepository == null) return;
    _panel = true;
    try {
      await showSocialPanel(
        context,
        CommentsPanel(
          post: widget.post,
          repository: widget.socialRepository!,
          community: widget.repository,
          viewerId: widget.viewerId,
          moderator: widget.moderator,
          draft: _draft,
          onChanged: _refreshStats,
        ),
      );
    } finally {
      _panel = false;
    }
  }

  Future<void> _collaborate() async {
    if (_panel || widget.socialRepository == null) return;
    _panel = true;
    try {
      await showSocialPanel<bool>(
        context,
        CollaborationPanel(
          postId: widget.post.id,
          repository: widget.socialRepository!,
          onSent: () => _action(_refreshStats, reload: false),
        ),
      );
    } finally {
      _panel = false;
    }
  }

  Future<void> _save(bool next) async {
    await _action(() async {
      await widget.repository.setSaved(widget.post.id, next);
      if (mounted) {
        setState(() => _saved = next);
        widget.onSaved?.call(next);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        final confirmation = ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            persist: false,
            showCloseIcon: true,
            content: Text(
              next
                  ? 'Publicación guardada.'
                  : 'Publicación retirada de Guardados.',
            ),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () => _save(!next),
            ),
          ),
        );
        confirmation.closed.then((reason) {
          if (mounted &&
              reason != SnackBarClosedReason.action &&
              _saved == next) {
            widget.onSaveSettled?.call(next);
          }
        });
      }
    }, reload: false);
  }

  Future<void> _option(String value) async {
    final post = widget.post;
    if (value == 'save') {
      await _save(!_saved);
      return;
    }
    if (value == 'details') {
      await context.push('/posts/${post.id}');
      return;
    }
    if (value == 'edit') {
      await context.push('/posts/${post.id}/edit');
      if (mounted) await widget.onChanged();
      return;
    }
    if (value == 'delete') {
      if (await confirmCommunityDelete(context) && mounted) {
        await _action(() async {
          await widget.repository.deletePost(post.id);
          if (post.imagePath != null) {
            try {
              await widget.repository.removeImage(post.imagePath!);
            } catch (_) {}
          }
        }, success: 'Publicación eliminada.');
      }
      return;
    }
    final reason = await askCommunityText(
      context,
      title: 'Reportar publicación',
      label: 'Cuéntanos qué ocurre',
      maxLength: 500,
    );
    if (reason != null && mounted) {
      await _action(
        () => widget.repository.report(postId: post.id, reason: reason),
        reload: false,
        success: 'Reporte enviado a moderación.',
      );
    }
  }

  Future<void> _options() async {
    final value = await showMareaBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.post.hidden)
              ListTile(
                leading: Icon(
                  _saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                ),
                title: Text(_saved ? 'Quitar guardado' : 'Guardar'),
                onTap: () => Navigator.pop(context, 'save'),
              ),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Ver detalles'),
              onTap: () => Navigator.pop(context, 'details'),
            ),
            if (widget.post.authorId == widget.viewerId) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Eliminar',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Reportar'),
                onTap: () => Navigator.pop(context, 'report'),
              ),
          ],
        ),
      ),
    );
    if (value != null && mounted) await _option(value);
  }

  Widget _homeActions({bool vertical = false}) {
    final post = widget.post;
    final enabled = !_busy && !post.hidden && widget.viewerId != null;
    final commentCount = _stats?.commentCount ?? 0;
    final actions = <Widget>[
      if (widget.socialRepository != null) ...[
        ReactionButton(
          inline: true,
          compact: vertical,
          stackedCount: vertical,
          selected: _stats?.myReaction,
          count: _stats?.reactionCount ?? 0,
          enabled: enabled,
          onSelected: _react,
        ),
        Semantics(
          button: true,
          enabled: enabled,
          label: 'Comentarios',
          value: '$commentCount',
          onTap: enabled ? _comments : null,
          excludeSemantics: true,
          child: IconButton(
            tooltip: 'Comentarios',
            onPressed: enabled ? _comments : null,
            icon: Flex(
              direction: vertical ? Axis.vertical : Axis.horizontal,
              mainAxisSize: MainAxisSize.min,
              spacing: vertical ? 3 : 5,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                Flexible(
                  child: Text(
                    '$commentCount',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: vertical
                        ? Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            height: 1.1,
                          )
                        : Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      IconButton(
        tooltip: _saved ? 'Quitar guardado' : 'Guardar',
        onPressed: enabled ? () => _save(!_saved) : null,
        icon: Icon(
          _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          size: 22,
        ),
      ),
      IconButton(
        tooltip: 'Compartir',
        onPressed: enabled
            ? () => sharePost(
                context,
                AppConfig.fromValues(
                  supabaseUrl: '',
                  supabaseAnonKey: '',
                  publicUrl: widget.publicUrl,
                ).postUrl(post.id),
              )
            : null,
        icon: const Icon(Icons.shortcut_rounded, size: 22),
      ),
    ];
    if (!vertical) {
      return Wrap(
        key: const Key('home-post-action-row'),
        crossAxisAlignment: WrapCrossAlignment.center,
        children: actions,
      );
    }

    final color = _homeCategory.color;
    return DecoratedBox(
      key: const Key('home-post-action-rail'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, Color.lerp(color, AppColors.surface, .56)!],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions,
      ),
    );
  }

  CategoryVisual get _homeCategory =>
      CategoryVisuals.values[widget.post.category] ??
      CategoryVisuals.values['otros']!;

  Widget _homeCategoryChip() {
    final category = widget.post.category;
    final visual = _homeCategory;
    final name = communityCategories[category] ?? 'Otros';
    final label = Text(name);
    final onCategory = widget.onHomeCategory;
    if (onCategory == null) {
      return Chip(
        avatar: Icon(visual.icon, size: 16),
        label: label,
        backgroundColor: visual.color,
      );
    }
    void filterCategory() => onCategory(category);
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: 'Ver publicaciones de $name',
      onTap: filterCategory,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: visual.color,
          foregroundColor: AppColors.brandNavy,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(48, 36),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        icon: Icon(visual.icon, size: 16),
        label: label,
        onPressed: filterCategory,
      ),
    );
  }

  Widget _homeContent({required bool photo}) {
    final post = widget.post;
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium!;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _homeCategoryChip(),
        InkWell(
          onTap: _openHomePost,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                post.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.brandNavy,
                  fontWeight: FontWeight.w900,
                  height: 1.16,
                  letterSpacing: -.35,
                ),
              ),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, bounds) {
            final painter = TextPainter(
              text: TextSpan(text: post.body, style: bodyStyle),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              maxLines: 3,
            )..layout(maxWidth: bounds.maxWidth);
            final truncated = painter.didExceedMaxLines;
            painter.dispose();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.body,
                  maxLines: _expanded ? null : 3,
                  overflow: _expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: bodyStyle,
                ),
                if (truncated)
                  TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(_expanded ? 'Ver menos' : 'Ver más'),
                  ),
              ],
            );
          },
        ),
        if (post.price != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '\$${post.price!.toStringAsFixed(2)} MXN',
              style: theme.textTheme.titleMedium,
            ),
          ),
        if (post.location != null || post.coordinates != null)
          FeedCityLabel(
            contentKind: 'post',
            contentId: post.id,
            city: post.city,
            coordinates: post.coordinates,
            repository: widget.locationRepository,
            onTap: () => post.coordinates == null
                ? _openHomePost()
                : showPostLocationViewer(
                    context,
                    label: post.location ?? 'Ubicación',
                    coordinates: post.coordinates!,
                  ),
          ),
      ],
    );

    if (photo) return content;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(AppColors.surface, _homeCategory.color, .27),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
        child: content,
      ),
    );
  }

  Future<void> _openHomePost() async {
    await context.push('/posts/${widget.post.id}');
    if (mounted) await widget.onChanged();
  }

  bool _homeImageFailed = false;
  Widget _homePhoto(String url, Future<String>? request) => Semantics(
    label: 'Abrir foto de ${widget.post.title}',
    button: true,
    child: InkWell(
      onTap: _openHomePost,
      borderRadius: BorderRadius.circular(18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && request == _url && !_homeImageFailed) {
                setState(() => _homeImageFailed = true);
              }
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );

  Widget _homeCard() {
    final post = widget.post;
    final theme = Theme.of(context);
    final request = _url;
    return MareaCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/people/${post.authorId}'),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox.square(
                            dimension: 40,
                            child: ClipOval(
                              child: ProfileImage(
                                path: widget.author?.avatarPath,
                                repository: widget.mediaRepository,
                                fallback: CircleAvatar(
                                  backgroundColor: AppColors.mint,
                                  child: Text(widget.author?.initials ?? 'M'),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.author?.fullName ?? 'Perfil de MAREA',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.brandNavy,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${socialDate(post.createdAt)} · ${post.kind.label}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Acciones',
                  onPressed: _busy ? null : _options,
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
            if (post.hidden)
              Text('Oculta por moderación', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: request,
              builder: (_, snapshot) => LayoutBuilder(
                builder: (context, bounds) {
                  final photo =
                      request != null &&
                      !_homeImageFailed &&
                      !snapshot.hasError;
                  final hasRail =
                      photo &&
                      bounds.maxWidth >= 296 &&
                      MediaQuery.textScalerOf(context).scale(14) <= 18;
                  final image =
                      snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData
                      ? _homePhoto(snapshot.data!, request)
                      : const ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(18)),
                          child: MareaSkeleton(kind: SkeletonKind.image),
                        );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasRail)
                        SizedBox(
                          height: ((bounds.maxWidth - 68) * .78)
                              .clamp(208, 376)
                              .toDouble(),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: image),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 60,
                                child: _homeActions(vertical: true),
                              ),
                            ],
                          ),
                        )
                      else if (photo)
                        AspectRatio(aspectRatio: 1.5, child: image),
                      if (photo) const SizedBox(height: 6),
                      _homeContent(photo: photo),
                      if (!hasRail) _homeActions(),
                      if (hasRail) const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rail() {
    final stats = _stats;
    final active = stats?.myReaction;
    final enabled = !_busy && !widget.post.hidden && widget.viewerId != null;
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.socialRepository != null && !widget.post.hidden) ...[
            ReactionButton(
              selected: active,
              count: stats?.reactionCount ?? 0,
              enabled: enabled,
              onSelected: _react,
            ),
            const SizedBox(height: 8),
            MareaActionButton(
              tooltip: 'Comentarios',
              onPressed: enabled ? _comments : null,
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${stats?.commentCount ?? 0}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
          ],
          MareaActionButton(
            tooltip: 'Compartir',
            onPressed: enabled
                ? () async {
                    if (_panel) return;
                    _panel = true;
                    try {
                      await sharePost(
                        context,
                        AppConfig.fromValues(
                          supabaseUrl: '',
                          supabaseAnonKey: '',
                          publicUrl: widget.publicUrl,
                        ).postUrl(widget.post.id),
                      );
                    } finally {
                      _panel = false;
                    }
                  }
                : null,
            icon: const Icon(
              Icons.ios_share_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          MareaActionButton(
            tooltip: 'Acciones',
            onPressed: _busy ? null : _options,
            icon: Icon(
              _saved ? Icons.bookmark_rounded : Icons.more_horiz_rounded,
              color: _saved ? AppColors.aquaDark : AppColors.textSecondary,
            ),
          ),
          const Text(
            'Más',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Guardando…',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _reading() {
    final post = widget.post;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.homePresentation || post.imagePath == null)
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
        if (!widget.homePresentation || post.imagePath == null)
          const SizedBox(height: 10),
        Text(
          post.body,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: widget.homePresentation ? 14 : 16,
            height: widget.homePresentation ? 1.35 : 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        LayoutBuilder(
          builder: (context, bounds) {
            final painter = TextPainter(
              text: TextSpan(
                text: post.body,
                style: TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: widget.homePresentation ? 14 : 16,
                  height: widget.homePresentation ? 1.35 : 1.5,
                ),
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              maxLines: 3,
            )..layout(maxWidth: bounds.maxWidth);
            return painter.didExceedMaxLines
                ? TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(_expanded ? 'Ver menos' : 'Ver más'),
                  )
                : const SizedBox.shrink();
          },
        ),
        if (post.location != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                Text(
                  post.location!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (post.coordinates != null)
                  TextButton.icon(
                    onPressed: () => showPostLocationViewer(
                      context,
                      label: post.location!,
                      coordinates: post.coordinates!,
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Ver mapa'),
                  ),
              ],
            ),
          ),
        if (post.price != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '\$${post.price!.toStringAsFixed(2)} MXN',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        if (post.allowsCollaboration &&
            post.authorId != widget.viewerId &&
            widget.socialRepository != null &&
            !post.hidden)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.mint,
                foregroundColor: AppColors.textPrimary,
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: _stats?.interestSent == true || _busy
                  ? null
                  : _collaborate,
              icon: Icon(
                _stats?.interestSent == true
                    ? Icons.check_rounded
                    : Icons.handshake_outlined,
              ),
              label: Text(
                _stats?.interestSent == true
                    ? 'Interés enviado'
                    : 'Me interesa colaborar',
              ),
            ),
          ),
      ],
    );
  }

  Widget _image() => AspectRatio(
    aspectRatio: 3 / 5,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: AppColors.paper,
        child: FutureBuilder<String>(
          future: _url,
          builder: (context, snapshot) => snapshot.hasData
              ? Image.network(
                  snapshot.data!,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const MareaSkeleton(kind: SkeletonKind.image),
                  errorBuilder: (_, _, _) => _imageError(),
                )
              : snapshot.hasError
              ? _imageError()
              : const Center(child: MareaSkeleton(kind: SkeletonKind.image)),
        ),
      ),
    ),
  );
  Widget _imageError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          const Text(
            'La fotografía no está disponible.',
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: () => setState(_loadImage),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    if (widget.homePresentation) return _homeCard();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: MareaCard(
          margin: const EdgeInsets.only(bottom: 24),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/people/${post.authorId}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: ClipOval(
                            child: ProfileImage(
                              path: widget.author?.avatarPath,
                              repository: widget.mediaRepository,
                              fallback: CircleAvatar(
                                backgroundColor: AppColors.lavender,
                                child: Text(widget.author?.initials ?? 'M'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.author?.fullName ?? 'Perfil de MAREA',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${socialDate(post.createdAt)} · ${post.kind.label} · ${ProfilePreferences.interests[post.category] ?? 'Otros'}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (post.hidden)
                  const Text(
                    'Oculta por moderación',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, bounds) {
                    final wide = bounds.maxWidth >= 728;
                    final reading = _reading();
                    final rail = _rail();
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_url != null)
                            SizedBox(width: 300, child: _image()),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 20,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 320,
                                  ),
                                  child: reading,
                                ),
                              ),
                            ),
                          ),
                          rail,
                        ],
                      );
                    }
                    if (_url == null) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: reading,
                            ),
                          ),
                          rail,
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _image()),
                            const SizedBox(width: 8),
                            rail,
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
                          child: reading,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
