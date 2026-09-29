import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/profile/models/profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.controller, super.key});
  final AppSessionController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _postsFeedKey = GlobalKey<_PostsFeedState>();

  Future<void> _refresh() =>
      _postsFeedKey.currentState?.reload() ?? Future<void>.value();

  @override
  Widget build(BuildContext context) {
    final profile = widget.controller.profile;
    return CommunityPage(
      title: 'La ciudad se encuentra aquí',
      subtitle: 'Ideas, proyectos y oportunidades de la comunidad MAREA.',
      onRefresh: _refresh,
      children: [
        if (profile != null)
          Card(
            color: AppColors.mist,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.go('/create'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.lavender,
                      child: Text(
                        profile.fullName.isEmpty
                            ? 'M'
                            : profile.fullName[0].toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '¿Qué quieres mover hoy en tu comunidad?',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.add_circle_outline_rounded),
                  ],
                ),
              ),
            ),
          ),
        if (profile != null) const SizedBox(height: 16),
        if (profile != null)
          Card(
            color: AppColors.mint,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.userType.headline,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(profile.userType.description),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.go('/create'),
                        icon: const Icon(Icons.add),
                        label: const Text('Compartir publicación'),
                      ),
                      OutlinedButton(
                        onPressed: () => context.go('/missions'),
                        child: const Text('Encontrar misiones'),
                      ),
                      if (profile.role == ProfileRole.admin)
                        OutlinedButton.icon(
                          onPressed: () async {
                            await context.push('/moderation');
                            if (mounted) _refresh();
                          },
                          icon: const Icon(Icons.shield_outlined),
                          label: const Text('Moderación'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        PostsFeed(key: _postsFeedKey, controller: widget.controller),
      ],
    );
  }
}

class PostsFeed extends StatefulWidget {
  const PostsFeed({
    required this.controller,
    this.authorId,
    this.query = '',
    this.category,
    this.savedOnly = false,
    super.key,
  });
  final AppSessionController controller;
  final String? authorId, category;
  final String query;
  final bool savedOnly;
  @override
  State<PostsFeed> createState() => _PostsFeedState();
}

class _PostsFeedState extends State<PostsFeed> {
  final _posts = <CommunityPost>[];
  final _authors = <String, CommunityProfile>{};
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
  void didUpdateWidget(PostsFeed old) {
    super.didUpdateWidget(old);
    if (old.authorId != widget.authorId ||
        old.query != widget.query ||
        old.category != widget.category ||
        old.savedOnly != widget.savedOnly ||
        old.controller != widget.controller) {
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
      if (reset) {
        _posts.clear();
        _authors.clear();
      }
    });
    try {
      final posts = await repo.posts(
        authorId: widget.authorId,
        query: widget.query,
        category: widget.category,
        savedOnly: widget.savedOnly,
        offset: _posts.length,
      );
      final authors = posts.isEmpty
          ? <CommunityProfile>[]
          : await repo.profiles(
              ids: posts.map((p) => p.authorId).toSet().toList(),
            );
      final saved = await repo.savedPostIds();
      if (!mounted || generation != _generation) return;
      setState(() {
        _posts.addAll(posts);
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
      Row(
        children: [
          Expanded(
            child: Text(
              widget.authorId != null
                  ? 'Publicaciones'
                  : widget.savedOnly
                  ? 'Tus guardados'
                  : 'Publicaciones recientes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Actualizar publicaciones',
            onPressed: _loading ? null : () => _load(reset: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      const SizedBox(height: 8),
      for (final post in _posts)
        PostCard(
          key: ValueKey(post.id),
          post: post,
          author: _authors[post.authorId],
          repository: _repo!,
          viewerId: widget.controller.profile?.id,
          saved: _saved.contains(post.id),
          onChanged: () => _load(reset: true),
          onSaved: (saved) {
            setState(() {
              if (saved) {
                _saved.add(post.id);
              } else {
                _saved.remove(post.id);
                if (widget.savedOnly) {
                  _posts.removeWhere((p) => p.id == post.id);
                }
              }
            });
          },
        ),
      if (_error != null)
        CommunityNotice(message: _error!, onRetry: () => _load(reset: true)),
      if (_loading)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
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
    this.author,
    super.key,
  });
  final CommunityPost post;
  final CommunityProfile? author;
  final CommunityRepository repository;
  final String? viewerId;
  final bool saved;
  final Future<void> Function() onChanged;
  final ValueChanged<bool>? onSaved;
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _busy = false;
  late bool _saved = widget.saved;
  Future<String>? _url;
  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() {
    _url = widget.post.imagePath == null
        ? null
        : widget.repository.imageUrl(widget.post.imagePath!);
  }

  @override
  void didUpdateWidget(PostCard old) {
    super.didUpdateWidget(old);
    _saved = widget.saved;
    if (old.post.imagePath != widget.post.imagePath) _loadImage();
  }

  Future<void> _action(
    Future<void> Function() action, {
    bool reload = true,
    String? success,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await runCommunityAction(context, action, success: success);
    if (mounted) setState(() => _busy = false);
    if (ok && mounted && reload) await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final owner = post.authorId == widget.viewerId;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/people/${post.authorId}'),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.lavender,
                          child: Text(widget.author?.initials ?? 'M'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.author?.fullName ?? 'Perfil de MAREA',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                widget.author?.userType.databaseValue ?? '',
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
                PopupMenuButton<String>(
                  enabled: !_busy,
                  tooltip: 'Opciones de publicación',
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await context.push('/posts/${post.id}/edit');
                      if (mounted) await widget.onChanged();
                    }
                    if (!context.mounted) return;
                    if (value == 'delete') {
                      if (await confirmCommunityDelete(context) && mounted) {
                        await _action(() async {
                          await widget.repository.deletePost(post.id);
                          if (post.imagePath != null) {
                            try {
                              await widget.repository.removeImage(
                                post.imagePath!,
                              );
                            } catch (_) {}
                          }
                        }, success: 'Publicación eliminada.');
                      }
                    }
                    if (!context.mounted) return;
                    if (value == 'report') {
                      final reason = await askCommunityText(
                        context,
                        title: 'Reportar publicación',
                        label: 'Cuéntanos qué ocurre',
                        maxLength: 500,
                      );
                      if (reason != null && mounted) {
                        await _action(
                          () => widget.repository.report(
                            postId: post.id,
                            reason: reason,
                          ),
                          reload: false,
                          success: 'Reporte enviado a moderación.',
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    if (owner) ...[
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar'),
                      ),
                    ] else
                      const PopupMenuItem(
                        value: 'report',
                        child: Text('Reportar'),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(post.kind.label),
                  backgroundColor: AppColors.mint,
                  side: BorderSide.none,
                ),
                Chip(
                  label: Text(
                    ProfilePreferences.interests[post.category] ?? 'Otros',
                  ),
                  side: BorderSide.none,
                ),
                if (post.hidden)
                  const Chip(label: Text('Oculta por moderación')),
              ],
            ),
            const SizedBox(height: 10),
            Text(post.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            SelectableText(post.body),
            if (_url != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: FutureBuilder<String>(
                  future: _url,
                  builder: (context, snapshot) => snapshot.hasData
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            snapshot.data!,
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const CommunityNotice(
                              message: 'La fotografía no está disponible.',
                            ),
                          ),
                        )
                      : snapshot.hasError
                      ? const Text('No pudimos cargar la fotografía.')
                      : const SizedBox(
                          height: 100,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                ),
              ),
            if (post.location != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(post.location!)),
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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _date(post.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                TextButton.icon(
                  onPressed: _busy || post.hidden
                      ? null
                      : () => _action(() async {
                          final next = !_saved;
                          await widget.repository.setSaved(post.id, next);
                          if (mounted) {
                            setState(() => _saved = next);
                            widget.onSaved?.call(next);
                          }
                        }, reload: false),
                  icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border),
                  label: Text(_saved ? 'Guardado' : 'Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _date(DateTime time) {
  final d = time.toLocal();
  return '${d.day}/${d.month}/${d.year}';
}
