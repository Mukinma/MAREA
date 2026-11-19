import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/category_visuals.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/shared/widgets/marea_skeleton.dart';

class PostSearchScreen extends StatefulWidget {
  const PostSearchScreen({
    required this.controller,
    this.initialCategory,
    this.discoverOnly = false,
    super.key,
  });

  final AppSessionController controller;
  final String? initialCategory;
  final bool discoverOnly;

  @override
  State<PostSearchScreen> createState() => _PostSearchScreenState();
}

class _PostSearchScreenState extends State<PostSearchScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _posts = <CommunityPost>[];
  Timer? _debounce;
  String? _category, _error;
  String _query = '';
  int _generation = 0, _offset = 0;
  bool _loading = false, _paging = false, _more = false;

  bool get _browsing => _query.isEmpty && _category == null && !widget.discoverOnly;
  bool get _shortQuery => _query.isNotEmpty && _query.runes.length < 2;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    if (!_browsing) _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _search({bool debounce = false}) {
    _debounce?.cancel();
    ++_generation;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() {
      _query = _input.text.trim();
      _posts.clear();
      _offset = 0;
      _more = false;
      _paging = false;
      _error = null;
      _loading = !_browsing && !_shortQuery;
    });
    if (!_loading) return;
    if (debounce) {
      _debounce = Timer(const Duration(milliseconds: 300), _page);
    } else {
      _page();
    }
  }

  Future<void> _page() async {
    if (_paging) return;
    final generation = _generation;
    final viewerId = widget.controller.profile?.id;
    final repository = widget.controller.communityRepository;
    setState(() {
      _loading = true;
      _paging = true;
      _error = null;
    });
    bool current() =>
        mounted &&
        generation == _generation &&
        viewerId == widget.controller.profile?.id;
    try {
      if (repository == null) {
        throw StateError('Community repository unavailable');
      }
      final rows = await repository.posts(
        query: _query,
        category: _category,
        visibleOnly: true,
        discoverOnly: widget.discoverOnly,
        offset: _offset,
      );
      if (!current()) return;
      final authors = rows.isEmpty
          ? <CommunityProfile>[]
          : await repository.profiles(
              ids: rows.map((post) => post.authorId).toSet().toList(),
            );
      if (!current()) return;
      setState(() {
        final seen = _posts.map((post) => post.id).toSet();
        final visibleAuthors = authors.map((author) => author.id).toSet();
        _posts.addAll(
          rows.where(
            (post) =>
                visibleAuthors.contains(post.authorId) && seen.add(post.id),
          ),
        );
        _offset += rows.length;
        _more = rows.length == SupabaseCommunityRepository.pageSize;
        _loading = false;
        _paging = false;
      });
    } catch (_) {
      if (!current()) return;
      setState(() {
        _loading = false;
        _paging = false;
        _error = AppLocalizations.tr('No se pudo completar la búsqueda.');
      });
    }
  }

  void _selectCategory(String? category) {
    _category = category == _category ? null : category;
    if (_input.text.trim().isEmpty) _focus.unfocus();
    _search();
  }

  RegExp? get _match => _query.isEmpty
      ? null
      : RegExp(RegExp.escape(_query), caseSensitive: false, unicode: true);

  Future<void> _openPost(CommunityPost post) async {
    final generation = _generation;
    final viewer = widget.controller.profile?.id;
    _focus.unfocus();
    await context.push('/posts/${post.id}');
    bool current() =>
        mounted &&
        generation == _generation &&
        viewer == widget.controller.profile?.id;
    if (!current()) return;
    try {
      final repository = widget.controller.communityRepository!;
      final latest = await repository.post(post.id);
      if (!current()) return;
      final match = _match;
      if (latest != null &&
          !latest.hidden &&
          (_category == null || latest.category == _category) &&
          (match == null ||
              match.hasMatch(latest.title) ||
              match.hasMatch(latest.body))) {
        final authors = await repository.profiles(ids: [latest.authorId]);
        if (!current()) return;
        final index = _posts.indexWhere((result) => result.id == post.id);
        if (index < 0) return;
        setState(() {
          if (authors.any((author) => author.id == latest.authorId)) {
            _posts[index] = latest;
          } else {
            _posts.removeAt(index);
          }
        });
      } else {
        final index = _posts.indexWhere((result) => result.id == post.id);
        if (index < 0) return;
        setState(() {
          _posts.removeAt(index);
          _offset--;
        });
      }
    } catch (_) {
      // A temporary refresh failure leaves the existing results usable.
    }
  }

  Widget _categoryChip(String id, String name) {
    final visual = CategoryVisuals.forCategory(id);
    return FilterChip(
      label: Text(AppLocalizations.tr(name)),
      avatar: Icon(visual.icon, size: 17, color: AppColors.brandNavy),
      selected: _category == id,
      selectedColor: AppColors.navigationAqua,
      backgroundColor: visual.color,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      onSelected: (_) => _selectCategory(id),
    );
  }

  Widget _topics() => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.tr('Explora por categoría'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final entry in communityCategories.entries)
              _categoryChip(entry.key, entry.value),
          ],
        ),
      ],
    ),
  );

  Widget _filters() => SingleChildScrollView(
    key: ValueKey(_category),
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      spacing: 8,
      children: [
        FilterChip(
          label: Text(AppLocalizations.tr('Todas')),
          selected: _category == null,
          selectedColor: AppColors.navigationAqua,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          onSelected: (_) => _selectCategory(null),
        ),
        if (_category case final category?)
          _categoryChip(category, communityCategories[category]!),
        for (final entry in communityCategories.entries)
          if (entry.key != _category) _categoryChip(entry.key, entry.value),
      ],
    ),
  );

  Widget _result(CommunityPost post) {
    final styles = Theme.of(context).textTheme;
    final match = _match;
    final snippet = _snippet(post.body, match);
    final visual = CategoryVisuals.forCategory(post.category);
    return InkWell(
      key: ValueKey(post.id),
      onTap: () => _openPost(post),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: visual.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(visual.icon, size: 19, color: AppColors.brandNavy),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.tr(
                      communityCategories[post.category] ?? 'Otros',
                    ),
                    style: styles.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    _emphasize(post.title, match),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: styles.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandNavy,
                    ),
                  ),
                  if (snippet.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text.rich(
                      _emphasize(snippet, match),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: styles.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _snippet(String body, RegExp? pattern) {
    final text = body.trim().replaceAll(RegExp(r'\s+'), ' ');
    final match = pattern?.firstMatch(text);
    if (match == null) return text;
    final before = text.substring(0, match.start);
    final tail = before.characters.takeLast(32).toString();
    if (tail.length == before.length) return text;
    final startsAtWord = before[before.length - tail.length - 1] == ' ';
    final context = startsAtWord
        ? tail
        : tail.replaceFirst(RegExp(r'^\S+\s?'), '');
    return '… ${context.trimLeft()}${text.substring(match.start)}';
  }

  TextSpan _emphasize(String text, RegExp? pattern) {
    final match = pattern?.firstMatch(text);
    if (match == null) return TextSpan(text: text);
    return TextSpan(
      children: [
        TextSpan(text: text.substring(0, match.start)),
        TextSpan(
          text: match[0],
          style: const TextStyle(
            color: AppColors.brandNavy,
            backgroundColor: AppColors.navigationAqua,
            fontWeight: FontWeight.w800,
          ),
        ),
        TextSpan(text: text.substring(match.end)),
      ],
    );
  }

  Widget _notice(String message, {VoidCallback? onRetry}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: Column(
      children: [
        Semantics(
          container: true,
          liveRegion: true,
          child: Text(
            AppLocalizations.tr(message),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.tr('Reintentar')),
          ),
      ],
    ),
  );

  Widget _results() => ListView.builder(
    controller: _scroll,
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    itemCount: _posts.length + 1,
    itemBuilder: (context, index) {
      if (index < _posts.length) {
        return Column(
          children: [
            _result(_posts[index]),
            const Divider(height: 1, color: AppColors.border),
          ],
        );
      }
      if (_browsing) return _topics();
      if (_shortQuery) {
        return _notice('Escribe al menos dos caracteres.');
      }
      if (_error case final error?) {
        return _notice(error, onRetry: _page);
      }
      if (_loading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: MareaSkeleton(kind: SkeletonKind.list),
        );
      }
      if (_posts.isEmpty && !_more) {
        return _notice(
          'No encontramos publicaciones. Prueba otras palabras o cambia de categoría.',
        );
      }
      return _more
          ? Center(
              child: TextButton(
                onPressed: _page,
                child: Text(AppLocalizations.tr('Cargar más')),
              ),
            )
          : const SizedBox(height: 16);
    },
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    appBar: AppBar(
      backgroundColor: AppColors.surface,
      leading: IconButton(
        tooltip: AppLocalizations.tr('Volver'),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(AppLocalizations.tr('Buscar')),
      actions: [
        PopupMenuButton<String>(
          tooltip: AppLocalizations.tr('Buscar'),
          icon: const Icon(Icons.more_vert),
          itemBuilder: (_) => [
            PopupMenuItem(value: '/search/people', child: Text(AppLocalizations.tr('Personas'))),
            PopupMenuItem(value: '/search/showcases', child: Text(AppLocalizations.tr('Fichas'))),
          ],
          onSelected: (path) => context.push(path),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _input,
                  focusNode: _focus,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => _search(debounce: true),
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.tr('Título o texto'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _input.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: AppLocalizations.tr('Borrar búsqueda'),
                            onPressed: () {
                              _input.clear();
                              _focus.requestFocus();
                              _search();
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                if (!_browsing) _filters(),
                Expanded(child: _results()),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
