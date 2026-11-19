import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/core/localization/on_device_post_translator.dart';
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
    this.profilePresentation = false,
    this.showEmpty = true,
    this.sectionHeader,
    this.alwaysShowSectionHeader = false,
    super.key,
  });
  final AppSessionController controller;
  final String? authorId, category;
  final String query;
  final Widget? sectionHeader;
  final bool profilePresentation, showEmpty, alwaysShowSectionHeader;
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
        _error = AppLocalizations.tr(
          'Las publicaciones no están disponibles. Vuelve a iniciar la aplicación.',
        );
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
      if (widget.sectionHeader != null &&
          (widget.alwaysShowSectionHeader ||
              _posts.isNotEmpty ||
              _loading ||
              _error != null))
        widget.sectionHeader!,
      if (widget.showHeading || widget.showRefresh)
        Row(
          children: [
            if (widget.showHeading)
              Expanded(
                child: Text(
                  AppLocalizations.tr(
                    widget.authorId != null
                        ? 'Publicaciones'
                        : widget.savedOnly
                        ? 'Tus guardados'
                        : 'Publicaciones recientes',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              )
            else
              const Spacer(),
            if (widget.showRefresh)
              IconButton(
                tooltip: AppLocalizations.tr('Actualizar publicaciones'),
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
          profilePresentation: widget.profilePresentation,
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
          contentTranslator: widget.controller.postContentTranslator,
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
      else if (widget.showEmpty && _error == null && _posts.isEmpty)
        CommunityNotice(
          message: AppLocalizations.tr(
            widget.savedOnly
                ? 'Guarda las publicaciones que te interesen para encontrarlas aquí.'
                : widget.authorId != null
                ? 'Este espacio está listo para sus primeras publicaciones.'
                : 'Todavía no hay publicaciones con estos filtros. Comparte la primera idea.',
          ),
        ),
      if (!_loading && _more && _posts.isNotEmpty)
        TextButton(
          onPressed: _load,
          child: Text(AppLocalizations.tr('Cargar más publicaciones')),
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
    this.profilePresentation = false,
    this.detailPresentation = false,
    this.onComments,
    this.onHomeCategory,
    this.locationRepository,
    this.moderator = false,
    this.publicUrl = 'https://marea-azul.netlify.app/',
    this.contentTranslator,
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
  final PostContentTranslator? contentTranslator;
  final bool saved, moderator, homePresentation, detailPresentation;
  final bool profilePresentation;
  final VoidCallback? onComments;
  final Future<void> Function() onChanged;
  final ValueChanged<bool>? onSaved, onSaveSettled;
  final ValueChanged<String>? onHomeCategory;
  @override
  PostCardState createState() => PostCardState();
}

class PostCardState extends State<PostCard> {
  PostContentTranslator get _translator =>
      widget.contentTranslator ?? LocalPostContentTranslator.shared;

  bool _busy = false, _expanded = false, _panel = false;
  bool _translating = false, _sameLanguage = false;
  String? _targetLanguage, _translationError;
  int _translationGeneration = 0;
  TranslatedPostContent? _translatedContent;
  late bool _saved = widget.saved;
  late PostSocialStats? _stats = widget.stats;
  final _draft = CommentDraft();
  Future<String>? _url;

  String get _displayTitle => _translatedContent?.title ?? widget.post.title;
  String get _displayBody => _translatedContent?.body ?? widget.post.body;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_targetLanguage != locale) _resetTranslation();
    _targetLanguage = locale;
  }

  void _resetTranslation() {
    _translationGeneration++;
    _translatedContent = null;
    _sameLanguage = false;
    _translationError = null;
    _translating = false;
  }

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
    _url = widget.post.imagePath == null
        ? null
        : widget.repository.imageUrl(widget.post.imagePath!);
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _saved = widget.saved;
    if (oldWidget.viewerId != widget.viewerId ||
        oldWidget.post.id != widget.post.id) {
      ++_reactionGeneration;
      _reacting = false;
      _stats = widget.stats;
      _draft.clear();
      _draft.operationId = null;
      _draft.submitted = null;
    }
    if (oldWidget.stats != widget.stats && !_reacting) _stats = widget.stats;
    if (oldWidget.post.imagePath != widget.post.imagePath) _loadImage();
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.title != widget.post.title ||
        oldWidget.post.body != widget.post.body) {
      _resetTranslation();
    }
  }

  Future<void> _translateContent() async {
    final translator = _translator;
    if (!translator.isSupported || _translating) return;
    if (_translatedContent != null || _sameLanguage) {
      setState(_resetTranslation);
      return;
    }

    final targetLanguage = _targetLanguage!;
    final generation = ++_translationGeneration;
    setState(() {
      _translating = true;
      _translationError = null;
      _sameLanguage = false;
    });
    try {
      final result = await translator.translate(
        title: widget.post.title,
        body: widget.post.body,
        targetLanguage: targetLanguage,
      );
      if (!mounted || generation != _translationGeneration) return;
      setState(() {
        _translatedContent = result.alreadyInTargetLanguage ? null : result;
        _sameLanguage = result.alreadyInTargetLanguage;
      });
    } on PostTranslationException catch (error) {
      if (!mounted || generation != _translationGeneration) return;
      setState(
        () => _translationError = AppLocalizations.tr(switch (error.failure) {
          PostTranslationFailure.languageUndetermined =>
            'No pudimos identificar el idioma de esta publicación.',
          PostTranslationFailure.unsupportedLanguage =>
            'Todavía no podemos traducir publicaciones en este idioma.',
          PostTranslationFailure.modelUnavailable =>
            'No se pudo descargar el modelo de traducción. Conéctate a internet e inténtalo de nuevo.',
        }),
      );
    } on Exception {
      if (!mounted || generation != _translationGeneration) return;
      setState(
        () => _translationError = AppLocalizations.tr(
          'No se pudo traducir la publicación. Revisa tu conexión e inténtalo de nuevo.',
        ),
      );
    } finally {
      if (mounted && generation == _translationGeneration) {
        setState(() => _translating = false);
      }
    }
  }

  Widget _translationControl({bool compact = false}) {
    final available = _translator.isSupported;
    final onPressed = _translating || !available ? null : _translateContent;
    final icon = _translating
        ? const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.translate_rounded, size: 17);
    final label = Text(
      AppLocalizations.tr(
        _translatedContent != null ? 'Ver original' : 'Traducir publicación',
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compact)
          TextButton.icon(
            onPressed: onPressed,
            icon: icon,
            label: label,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsetsDirectional.only(end: 8),
              textStyle: Theme.of(context).textTheme.labelMedium,
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: icon,
            label: label,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandNavy,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size(48, 44),
            ),
          ),
        if (!available)
          Text(
            AppLocalizations.tr(
              'La traducción no está disponible en este dispositivo.',
            ),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        if (_sameLanguage)
          Text(
            AppLocalizations.tr(
              'Esta publicación ya está en el idioma seleccionado.',
            ),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        if (_translationError != null)
          Text(
            _translationError!,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
      ],
    );
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
              AppLocalizations.tr(
                next
                    ? 'Publicación guardada.'
                    : 'Publicación retirada de Guardados.',
              ),
            ),
            action: SnackBarAction(
              label: AppLocalizations.tr('Deshacer'),
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
      await _openPost();
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
        }, success: AppLocalizations.tr('Publicación eliminada.'));
      }
      return;
    }
    final reason = await askCommunityText(
      context,
      title: AppLocalizations.tr('Reportar publicación'),
      label: AppLocalizations.tr('Cuéntanos qué ocurre'),
      maxLength: 500,
    );
    if (reason != null && mounted) {
      await _action(
        () => widget.repository.report(postId: post.id, reason: reason),
        reload: false,
        success: AppLocalizations.tr('Reporte enviado a moderación.'),
      );
    }
  }

  Future<void> showOptions() async {
    if (_busy) return;
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
                title: Text(
                  AppLocalizations.tr(_saved ? 'Quitar guardado' : 'Guardar'),
                ),
                onTap: () => Navigator.pop(context, 'save'),
              ),
            if (!widget.detailPresentation)
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: Text(AppLocalizations.tr('Ver detalles')),
                onTap: () => Navigator.pop(context, 'details'),
              ),
            if (widget.post.authorId == widget.viewerId) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(AppLocalizations.tr('Editar')),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  AppLocalizations.tr('Eliminar'),
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(AppLocalizations.tr('Reportar')),
                onTap: () => Navigator.pop(context, 'report'),
              ),
          ],
        ),
      ),
    );
    if (value != null && mounted) await _option(value);
  }

  Future<void> _share() async {
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

  Widget _postActions() {
    final enabled = !_busy && !widget.post.hidden && widget.viewerId != null;
    final commentCount = _stats?.commentCount ?? 0;
    final commentLabel = AppLocalizations.tr('Comentarios');
    final onComments = widget.onComments ?? _comments;
    return Wrap(
      key: Key(
        widget.homePresentation
            ? 'home-post-action-row'
            : 'detail-post-action-row',
      ),
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
          Semantics(
            button: true,
            enabled: enabled,
            label: commentLabel,
            value: '$commentCount',
            onTap: enabled ? onComments : null,
            excludeSemantics: true,
            child: IconButton(
              tooltip: commentLabel,
              onPressed: enabled ? onComments : null,
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 5,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  Text(
                    '$commentCount',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
        IconButton(
          tooltip: AppLocalizations.tr(_saved ? 'Quitar guardado' : 'Guardar'),
          isSelected: _saved,
          onPressed: enabled ? () => _save(!_saved) : null,
          selectedIcon: const Icon(
            Icons.bookmark_rounded,
            color: AppColors.aquaDark,
          ),
          icon: const Icon(Icons.bookmark_border_rounded),
        ),
        IconButton(
          tooltip: AppLocalizations.tr('Compartir'),
          onPressed: enabled ? _share : null,
          icon: const Icon(Icons.ios_share_rounded, size: 21),
        ),
      ],
    );
  }

  Widget _postCategory() {
    final category = widget.post.category;
    final visual = CategoryVisuals.forCategory(category);
    final name = AppLocalizations.tr(communityCategories[category] ?? 'Otros');
    final icon = Icon(visual.icon, size: 15, color: AppColors.brandNavy);
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppColors.brandNavy,
      fontWeight: FontWeight.w800,
    );
    final onCategory = widget.onHomeCategory;
    if (onCategory == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: visual.color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              icon,
              Text(name, style: labelStyle),
            ],
          ),
        ),
      );
    }
    return Semantics(
      label: AppLocalizations.trTemplate('Ver publicaciones de {category}', {
        'category': name,
      }),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: visual.color,
          foregroundColor: AppColors.brandNavy,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          minimumSize: const Size(48, 28),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: labelStyle,
        ),
        icon: icon,
        label: Text(name),
        onPressed: () => onCategory(category),
      ),
    );
  }

  Widget _authorLine() {
    final styles = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => context.push('/people/${widget.post.authorId}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 36,
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
                    widget.author?.fullName ??
                        AppLocalizations.tr('Perfil de MAREA'),
                    style: styles.titleSmall?.copyWith(
                      color: AppColors.brandNavy,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppLocalizations.trTemplate('{date} · {kind}', {
                      'date': socialDate(widget.post.createdAt),
                      'kind': AppLocalizations.tr(widget.post.kind.label),
                    }),
                    style: styles.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _overflows(String value, TextStyle style, int lines, double width) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: lines,
    )..layout(maxWidth: width);
    final truncated = painter.didExceedMaxLines;
    painter.dispose();
    return truncated;
  }

  Widget _homeCopy() {
    final styles = Theme.of(context).textTheme;
    final titleStyle = styles.titleLarge!.copyWith(
      height: 1.18,
      color: AppColors.brandNavy,
      fontWeight: FontWeight.w900,
      letterSpacing: -.35,
    );
    final bodyStyle = styles.bodyMedium!;
    return LayoutBuilder(
      builder: (context, bounds) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _openPost,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
            ),
          ),
          if (_displayBody.isNotEmpty)
            Text(
              _displayBody,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: bodyStyle,
            ),
          if (_overflows(_displayTitle, titleStyle, 2, bounds.maxWidth) ||
              _overflows(_displayBody, bodyStyle, 3, bounds.maxWidth))
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: _openPost,
                style: TextButton.styleFrom(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                ),
                child: Text(AppLocalizations.tr('Leer publicación')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _postContext() {
    final post = widget.post;
    final theme = Theme.of(context);
    final hasLocation =
        post.location != null || post.coordinates != null || post.city != null;
    if (post.price == null && !hasLocation) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.price case final price?)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              '\$${price.toStringAsFixed(2)} MXN',
              style: theme.textTheme.titleMedium,
            ),
          ),
        if (hasLocation)
          if (widget.homePresentation)
            FeedCityLabel(
              contentKind: 'post',
              contentId: post.id,
              city: post.city,
              coordinates: post.coordinates,
              repository: widget.locationRepository,
              fallbackLabel: AppLocalizations.tr('Ver ubicación'),
              onTap: post.coordinates == null ? _openPost : _openPostMap,
            )
          else
            _readerLocation(),
      ],
    );
  }

  void _openPostMap() => showPostLocationViewer(
    context,
    label:
        widget.post.location ??
        widget.post.city?.name ??
        AppLocalizations.tr('Ubicación'),
    coordinates: widget.post.coordinates!,
  );

  Widget _readerLocation() {
    final post = widget.post;
    final label = post.location ?? post.city?.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        if (post.coordinates != null)
          TextButton.icon(
            onPressed: _openPostMap,
            style: TextButton.styleFrom(
              padding: const EdgeInsetsDirectional.only(end: 8),
            ),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: Text(AppLocalizations.tr('Ver mapa')),
          ),
      ],
    );
  }

  Future<void> _openPost() async {
    await context.push('/posts/${widget.post.id}');
    if (mounted) await widget.onChanged();
  }

  void _openPhoto(String url) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PostPhotoViewer(url: url, title: _displayTitle),
      ),
    );
  }

  Widget _postPhoto({required bool preview}) => LayoutBuilder(
    builder: (context, bounds) {
      final slotHeight = (bounds.maxWidth * (preview ? .625 : .9))
          .clamp(0, preview ? 376.0 : MediaQuery.sizeOf(context).height * .47)
          .toDouble();
      final placeholder = SizedBox(
        height: slotHeight,
        child: const MareaSkeleton(kind: SkeletonKind.image),
      );
      Widget error() => SizedBox(height: slotHeight, child: _photoError());
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: AppColors.profileCanvas,
          child: FutureBuilder<String>(
            future: _url,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return placeholder;
              }
              final url = snapshot.data;
              if (url == null) return error();
              return Image.network(
                url,
                width: bounds.maxWidth,
                height: preview ? slotHeight : null,
                fit: preview ? BoxFit.cover : BoxFit.contain,
                excludeFromSemantics: true,
                frameBuilder: (context, child, frame, synchronous) {
                  if (frame == null && !synchronous) return placeholder;
                  final label = AppLocalizations.tr(
                    preview ? 'Abrir publicación' : 'Ampliar foto',
                  );
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: slotHeight.clamp(0, 84).toDouble(),
                      maxHeight: slotHeight,
                    ),
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        child,
                        Positioned.fill(
                          child: Tooltip(
                            message: label,
                            child: Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                onTap: preview
                                    ? _openPost
                                    : () => _openPhoto(url),
                              ),
                            ),
                          ),
                        ),
                        if (!preview)
                          const PositionedDirectional(
                            end: 10,
                            bottom: 10,
                            child: IgnorePointer(
                              child: CircleAvatar(
                                backgroundColor: AppColors.brandNavy,
                                foregroundColor: Colors.white,
                                child: Icon(Icons.fullscreen_rounded),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                errorBuilder: (_, _, _) => error(),
              );
            },
          ),
        ),
      );
    },
  );

  Widget _photoError() =>
      Center(child: SingleChildScrollView(child: _imageError()));

  Widget _homeCard() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _authorLine()),
                IconButton(
                  tooltip: AppLocalizations.tr('Acciones'),
                  onPressed: _busy ? null : showOptions,
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
            if (widget.post.hidden)
              Text(
                AppLocalizations.tr('Oculta por moderación'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _postCategory(),
            ),
            _homeCopy(),
            if (_url != null) ...[
              const SizedBox(height: 12),
              _postPhoto(preview: true),
            ],
            _postContext(),
            _translationControl(compact: true),
            const Divider(height: 1, color: AppColors.border),
            _postActions(),
          ],
        ),
      ),
    ),
  );

  Widget _detailArticle() {
    final styles = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _authorLine(),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _postCategory(),
        ),
        const SizedBox(height: 10),
        Semantics(
          header: true,
          container: true,
          label: _displayTitle,
          excludeSemantics: true,
          child: SelectableText(
            _displayTitle,
            style: styles.headlineMedium?.copyWith(
              color: AppColors.brandNavy,
              height: 1.14,
              letterSpacing: -.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (_url != null) ...[
          const SizedBox(height: 16),
          _postPhoto(preview: false),
        ],
        if (_displayBody.isNotEmpty) ...[
          const SizedBox(height: 16),
          Semantics(
            container: true,
            label: _displayBody,
            excludeSemantics: true,
            child: SelectableText(
              _displayBody,
              style: styles.bodyLarge?.copyWith(height: 1.55),
            ),
          ),
        ],
        _postContext(),
        _translationControl(compact: true),
        _collaborationAction(),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.border),
        _postActions(),
      ],
    );
  }

  Widget _rail({bool horizontal = false}) {
    final stats = _stats;
    final active = stats?.myReaction;
    final enabled = !_busy && !widget.post.hidden && widget.viewerId != null;
    final actions = <Widget>[
      if (widget.socialRepository != null && !widget.post.hidden) ...[
        ReactionButton(
          selected: active,
          inline: horizontal,
          count: stats?.reactionCount ?? 0,
          enabled: enabled,
          onSelected: _react,
        ),
        if (!horizontal) const SizedBox(height: 8),
        if (horizontal)
          TextButton.icon(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: enabled ? _comments : null,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            label: Text(
              '${stats?.commentCount ?? 0}',
              semanticsLabel:
                  '${AppLocalizations.tr('Comentarios')} ${stats?.commentCount ?? 0}',
            ),
          )
        else ...[
          MareaActionButton(
            tooltip: AppLocalizations.tr('Comentarios'),
            onPressed: enabled ? _comments : null,
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats?.commentCount ?? 0}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
        ],
      ],
      MareaActionButton(
        tooltip: AppLocalizations.tr('Compartir'),
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
      if (!horizontal) const SizedBox(height: 8),
      MareaActionButton(
        tooltip: AppLocalizations.tr('Acciones'),
        onPressed: _busy ? null : showOptions,
        icon: Icon(
          _saved ? Icons.bookmark_rounded : Icons.more_horiz_rounded,
          color: _saved ? AppColors.aquaDark : AppColors.textSecondary,
        ),
      ),
      if (!horizontal)
        Text(
          AppLocalizations.tr('Más'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      if (_busy)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            AppLocalizations.tr('Guardando…'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11),
          ),
        ),
    ];
    return horizontal
        ? Wrap(
            key: const Key('profile-post-actions'),
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          )
        : SizedBox(
            width: 56,
            child: Column(mainAxisSize: MainAxisSize.min, children: actions),
          );
  }

  Widget _reading() {
    final post = widget.post;
    final compact = widget.profilePresentation || widget.homePresentation;
    final bodyStyle = TextStyle(
      fontFamily: 'NunitoSans',
      fontSize: widget.homePresentation
          ? 14
          : compact
          ? 15
          : 16,
      height: widget.homePresentation
          ? 1.35
          : compact
          ? 1.4
          : 1.5,
      color: AppColors.textPrimary,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.homePresentation || post.imagePath == null)
          Text(
            _displayTitle,
            style: TextStyle(
              fontSize: widget.profilePresentation ? 19 : 21,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
        if (!widget.homePresentation || post.imagePath == null)
          SizedBox(height: widget.profilePresentation ? 5 : 10),
        Text(
          _displayBody,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: bodyStyle,
        ),
        _translationControl(),
        LayoutBuilder(
          builder: (context, bounds) {
            final painter = TextPainter(
              text: TextSpan(text: _displayBody, style: bodyStyle),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              maxLines: 3,
            )..layout(maxWidth: bounds.maxWidth);
            final overflows = painter.didExceedMaxLines;
            painter.dispose();
            return overflows
                ? TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      AppLocalizations.tr(_expanded ? 'Ver menos' : 'Ver más'),
                    ),
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
                    label: Text(AppLocalizations.tr('Ver mapa')),
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
        _collaborationAction(),
      ],
    );
  }

  Widget _collaborationAction() {
    final post = widget.post;
    if (!post.allowsCollaboration ||
        post.authorId == widget.viewerId ||
        widget.socialRepository == null ||
        post.hidden) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: AppColors.mint,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onPressed: _stats?.interestSent == true || _busy ? null : _collaborate,
        icon: Icon(
          _stats?.interestSent == true
              ? Icons.check_rounded
              : Icons.handshake_outlined,
        ),
        label: Text(
          AppLocalizations.tr(
            _stats?.interestSent == true
                ? 'Interés enviado'
                : 'Me interesa colaborar',
          ),
        ),
      ),
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
          Text(
            AppLocalizations.tr('La fotografía no está disponible.'),
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: () => setState(_loadImage),
            child: Text(AppLocalizations.tr('Reintentar')),
          ),
        ],
      ),
    ),
  );
  String _metadata(BuildContext context) {
    final post = widget.post;
    final category = ProfilePreferences.interests[post.category];
    final kind = AppLocalizations.tr(post.kind.label);
    if (widget.profilePresentation) {
      return [
        MaterialLocalizations.of(
          context,
        ).formatShortDate(post.createdAt.toLocal()),
        if (post.kind != PostKind.community) kind,
        if (category != null && post.category != 'otros')
          AppLocalizations.tr(category),
      ].join(' · ');
    }
    return AppLocalizations.trTemplate('{date} · {kind} · {category}', {
      'date': socialDate(post.createdAt),
      'kind': kind,
      'category': AppLocalizations.tr(category ?? 'Otros'),
    });
  }

  Widget _postSurface(Widget child) => widget.profilePresentation
      ? Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        )
      : MareaCard(
          margin: const EdgeInsets.only(bottom: 24),
          clipBehavior: Clip.antiAlias,
          child: child,
        );

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    if (widget.homePresentation) return _homeCard();
    if (widget.detailPresentation) return _detailArticle();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: _postSurface(
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.profilePresentation
                      ? null
                      : () => context.push('/people/${post.authorId}'),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: widget.profilePresentation ? 2 : 8,
                    ),
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
                                foregroundColor: widget.profilePresentation
                                    ? AppColors.brandNavy
                                    : null,
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
                                widget.author?.fullName ??
                                    AppLocalizations.tr('Perfil de MAREA'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _metadata(context),
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
                  Text(
                    AppLocalizations.tr('Oculta por moderación'),
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                const SizedBox(height: 12),
                if (widget.profilePresentation) ...[
                  if (_url != null) ...[_image(), const SizedBox(height: 12)],
                  _reading(),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  _rail(horizontal: true),
                ] else
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

class _PostPhotoViewer extends StatefulWidget {
  const _PostPhotoViewer({required this.url, required this.title});

  final String url, title;

  @override
  State<_PostPhotoViewer> createState() => _PostPhotoViewerState();
}

class _PostPhotoViewerState extends State<_PostPhotoViewer> {
  final _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _zoom(Size viewport) {
    final next = Matrix4.identity();
    if (_transform.value.getMaxScaleOnAxis() < 1.1) {
      next
        ..translateByDouble(-viewport.width / 2, -viewport.height / 2, 0, 1)
        ..scaleByDouble(2, 2, 1, 1);
    }
    _transform.value = next;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => Scaffold(
      backgroundColor: AppColors.brandNavy,
      appBar: AppBar(
        backgroundColor: AppColors.brandNavy,
        foregroundColor: Colors.white,
        titleTextStyle: Theme.of(
          context,
        ).appBarTheme.titleTextStyle?.copyWith(color: Colors.white),
        leading: IconButton(
          tooltip: AppLocalizations.tr('Cerrar'),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          ValueListenableBuilder<Matrix4>(
            valueListenable: _transform,
            builder: (_, value, _) {
              final zoomed = value.getMaxScaleOnAxis() >= 1.1;
              return IconButton(
                tooltip: AppLocalizations.tr(
                  zoomed ? 'Restablecer zoom' : 'Acercar',
                ),
                onPressed: () => _zoom(
                  Size(
                    bounds.maxWidth,
                    bounds.maxHeight -
                        MediaQuery.paddingOf(context).top -
                        kToolbarHeight,
                  ),
                ),
                icon: Icon(
                  zoomed ? Icons.zoom_out_rounded : Icons.zoom_in_rounded,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: InteractiveViewer(
          transformationController: _transform,
          maxScale: 4,
          child: SizedBox.expand(
            child: Image.network(
              widget.url,
              fit: BoxFit.contain,
              semanticLabel: AppLocalizations.tr('Fotografía'),
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  AppLocalizations.tr('La fotografía no está disponible.'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
