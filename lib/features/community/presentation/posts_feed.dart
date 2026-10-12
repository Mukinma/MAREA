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
    this.showHeading = true,
    this.showRefresh = true,
    super.key,
  });
  final AppSessionController controller;
  final String? authorId, category;
  final String query;
  final bool savedOnly, showHeading, showRefresh;
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

  Widget _homeActions() {
    final post = widget.post;
    final enabled = !_busy && !post.hidden && widget.viewerId != null;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (widget.socialRepository != null) ...[
          ReactionButton(
            inline: true,
            selected: _stats?.myReaction,
            count: _stats?.reactionCount ?? 0,
            enabled: enabled,
            onSelected: _react,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Comentarios',
                onPressed: enabled ? _comments : null,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
              ),
              Text(
                '${_stats?.commentCount ?? 0}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
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
        IconButton(
          tooltip: _saved ? 'Quitar guardado' : 'Guardar',
          onPressed: enabled ? () => _save(!_saved) : null,
          icon: Icon(
            _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _homeContent(double width) {
    final post = widget.post;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _openHomePost,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                post.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                  color: AppColors.brandNavy,
                ),
              ),
            ),
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
        Text(
          post.body,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            height: 1.3,
            color: AppColors.textPrimary,
          ),
        ),
        if (_homeBodyTruncated(width))
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'Ver menos' : 'Ver más'),
          ),
        if (post.price != null)
          Text(
            '\$${post.price!.toStringAsFixed(2)} MXN',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.mist,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            communityCategories[post.category] ?? 'Otros',
            style: const TextStyle(fontSize: 10, color: AppColors.brandNavy),
          ),
        ),
      ],
    );
  }

  double _homePhotoHeight(double width) {
    TextPainter measure(String text, TextStyle style, {int? maxLines}) =>
        TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: maxLines,
        )..layout(maxWidth: width);
    final title = measure(
      widget.post.title,
      const TextStyle(
        fontFamily: 'NunitoSans',
        fontSize: 18,
        height: 1.12,
        fontWeight: FontWeight.w800,
      ),
    );
    final body = measure(
      widget.post.body,
      const TextStyle(fontFamily: 'NunitoSans', fontSize: 12, height: 1.3),
      maxLines: _expanded ? null : 3,
    );
    return (title.height < 48 ? 48 : title.height) +
        ((widget.post.location != null || widget.post.coordinates != null)
            ? 48
            : 0) +
        body.height +
        (_homeBodyTruncated(width) ? 48 : 0) +
        30;
  }

  bool _homeBodyTruncated(double width) {
    final painter = TextPainter(
      text: TextSpan(
        text: widget.post.body,
        style: const TextStyle(
          fontFamily: 'NunitoSans',
          fontSize: 12,
          height: 1.3,
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 3,
    )..layout(maxWidth: width);
    return painter.didExceedMaxLines;
  }

  Future<void> _openHomePost() async {
    await context.push('/posts/${widget.post.id}');
    if (mounted) await widget.onChanged();
  }

  bool _homeImageFailed = false;
  Widget _homePhoto(String url) => InkWell(
    onTap: _openHomePost,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_homeImageFailed) {
              setState(() => _homeImageFailed = true);
            }
          });
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  Widget _homeCard() {
    final post = widget.post;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/people/${post.authorId}'),
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
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
                                    backgroundColor: AppColors.mint,
                                    child: Text(widget.author?.initials ?? 'M'),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.author?.fullName ??
                                        'Perfil de MAREA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${socialDate(post.createdAt)} · ${post.kind.label}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
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
                    icon: const Icon(Icons.more_horiz),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              FutureBuilder<String>(
                future: _url,
                builder: (_, snapshot) => LayoutBuilder(
                  builder: (context, bounds) {
                    final hasPhoto =
                        post.imagePath != null &&
                        !_homeImageFailed &&
                        !snapshot.hasError;
                    final enlarged =
                        MediaQuery.textScalerOf(context).scale(12) > 18;
                    if (!hasPhoto) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _homeContent(bounds.maxWidth),
                          _homeActions(),
                        ],
                      );
                    }
                    final photo = snapshot.hasData
                        ? _homePhoto(snapshot.data!)
                        : const MareaSkeleton(kind: SkeletonKind.image);
                    if (enlarged) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AspectRatio(aspectRatio: 1.93, child: photo),
                          _homeContent(bounds.maxWidth),
                          _homeActions(),
                        ],
                      );
                    }
                    final photoWidth = (bounds.maxWidth - 10) * .56;
                    final inlineActions =
                        bounds.maxWidth - photoWidth - 10 >= 270;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: photoWidth,
                              height:
                                  _homePhotoHeight(
                                    bounds.maxWidth - photoWidth - 10,
                                  ) +
                                  (inlineActions ? 48 : 0),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 130,
                                ),
                                child: photo,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _homeContent(
                                    bounds.maxWidth - photoWidth - 10,
                                  ),
                                  if (inlineActions) _homeActions(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!inlineActions) _homeActions(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
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
