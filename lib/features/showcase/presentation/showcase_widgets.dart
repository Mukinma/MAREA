import 'package:marea/shared/widgets/marea_surface.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/showcase/data/showcase_repository.dart';
import 'package:marea/features/showcase/models/showcase.dart';

class ShowcasePhoto extends StatefulWidget {
  const ShowcasePhoto({
    required this.path,
    required this.repository,
    this.height = 220,
    super.key,
  });
  final String path;
  final ShowcaseRepository repository;
  final double height;
  @override
  State<ShowcasePhoto> createState() => _ShowcasePhotoState();
}

class _ShowcasePhotoState extends State<ShowcasePhoto> {
  late Future<String> _url;
  Timer? _timer;
  void _load() {
    _timer?.cancel();
    _url = widget.repository.imageUrl(widget.path);
    _timer = Timer(const Duration(minutes: 9), () {
      if (mounted) setState(_load);
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ShowcasePhoto old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path || old.repository != widget.repository) _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _fallback() => SizedBox(
    height: widget.height,
    child: Center(
      child: IconButton(
        tooltip: 'Volver a cargar fotografía',
        onPressed: () => setState(_load),
        icon: const Icon(Icons.refresh),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _url,
    builder: (_, snapshot) => snapshot.hasData
        ? Image.network(
            snapshot.data!,
            height: widget.height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
          )
        : snapshot.hasError
        ? _fallback()
        : SizedBox(
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          ),
  );
}

class ShowcaseList extends StatefulWidget {
  const ShowcaseList({
    required this.controller,
    this.ownerId,
    this.query = '',
    this.category,
    this.kind,
    this.management = false,
    this.savedOnly = false,
    this.compact = false,
    super.key,
  });
  final AppSessionController controller;
  final String? ownerId, category;
  final String query;
  final ShowcaseKind? kind;
  final bool management, savedOnly, compact;
  @override
  State<ShowcaseList> createState() => _ShowcaseListState();
}

class _ShowcaseListState extends State<ShowcaseList> {
  final List<ShowcaseItem> _items = [];
  bool _loading = false, _more = true;
  String? _error;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void didUpdateWidget(ShowcaseList old) {
    super.didUpdateWidget(old);
    if (old.ownerId != widget.ownerId ||
        old.query != widget.query ||
        old.category != widget.category ||
        old.kind != widget.kind ||
        old.savedOnly != widget.savedOnly ||
        old.management != widget.management ||
        old.controller != widget.controller) {
      _load(reset: true);
    }
  }

  Future<void> _load({bool reset = false}) async {
    final repo = widget.controller.showcaseRepository;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) _items.clear();
    });
    try {
      if (repo == null) throw StateError('showcase repository missing');
      final page = await repo.items(
        ownerId: widget.ownerId,
        query: widget.query,
        category: widget.category,
        kind: widget.kind,
        management: widget.management,
        savedOnly: widget.savedOnly,
        offset: _items.length,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _items.addAll(page);
        _more = page.length == 30;
      });
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() => _error = communityError(e));
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_items.isEmpty && !_loading && _error == null)
        CommunityNotice(
          message: widget.management
              ? 'Agrega tu primera ficha.'
              : widget.savedOnly
              ? 'Todavía no tienes fichas guardadas.'
              : 'No hay fichas disponibles aquí todavía.',
        ),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = widget.compact
              ? (constraints.maxWidth >= 336 ? 2 : 1)
              : constraints.maxWidth >= 800
              ? 3
              : constraints.maxWidth >= 500
              ? 2
              : 1;
          final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final item in _items)
                SizedBox(
                  width: width,
                  child: MareaCard(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        await context.push('/showcase/${item.id}');
                        if (mounted) await _load(reset: true);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (item.imagePaths.isNotEmpty)
                            ShowcasePhoto(
                              path: item.imagePaths.first,
                              repository: widget.controller.showcaseRepository!,
                              height: widget.compact ? width * .72 : 180,
                            )
                          else
                            Container(
                              height: widget.compact ? width * .72 : 120,
                              color: AppColors.mint,
                              child: const Icon(
                                Icons.design_services_outlined,
                                size: 42,
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.all(widget.compact ? 12 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                if (!widget.compact) Text(item.kind.label),
                                if (item.kind != ShowcaseKind.project)
                                  Text(
                                    item.price == null
                                        ? 'Consultar precio'
                                        : '\$${item.price!.toStringAsFixed(2)} MXN',
                                  ),
                                if (widget.management) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      Chip(label: Text(item.status.label)),
                                      if (!item.available)
                                        const Chip(
                                          label: Text('No disponible'),
                                        ),
                                      if (item.hidden)
                                        const Chip(
                                          label: Text('Oculto por moderación'),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      if (_loading)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      if (_error != null)
        CommunityNotice(
          message: _error!,
          onRetry: () => _load(reset: _items.isEmpty),
        ),
      if (_more && !_loading && _error == null && _items.isNotEmpty)
        TextButton(onPressed: _load, child: const Text('Cargar más fichas')),
    ],
  );
}
