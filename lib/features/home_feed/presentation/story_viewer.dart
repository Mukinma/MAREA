import 'dart:async';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/home_feed/data/stories_repository.dart';
import 'package:marea/features/home_feed/models/story.dart';
import 'package:marea/features/shell/presentation/marea_create_action.dart';
import 'package:marea/features/showcase/presentation/create_screen.dart';

class StoryViewer extends StatefulWidget {
  const StoryViewer({
    required this.stories,
    required this.batch,
    required this.repository,
    required this.profiles,
    required this.controller,
    this.viewerId,
    super.key,
  });
  final List<Story> stories;
  final StoryBatch batch;
  final StoriesRepository repository;
  final Map<String, CommunityProfile> profiles;
  final AppSessionController controller;
  final String? viewerId;
  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _progress;
  Timer? _expiry;
  int _index = 0;
  bool _holding = false,
      _paused = false,
      _background = false,
      _covered = false,
      _profileOpen = false,
      _creationOpen = false,
      _menuOpen = false,
      _loaded = false,
      _busy = false;
  Future<String>? _url;
  String? _error;
  Story get _story => widget.stories[_index];
  bool get _shouldPause =>
      _holding ||
      _paused ||
      _background ||
      _covered ||
      _profileOpen ||
      _creationOpen ||
      _menuOpen ||
      !_loaded ||
      _busy;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _progress =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) {
              _progress.reset();
              _sync();
            }
          });
    _prepare();
    _expiry = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && !_story.isAvailableAt(widget.batch.now)) _move(1);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _covered = ModalRoute.isCurrentOf(context) == false;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _expiry?.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _background = state != AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    if (_shouldPause) {
      _progress.stop();
    } else {
      _progress.forward();
    }
  }

  void _prepare() {
    _progress.reset();
    _loaded = false;
    _error = null;
    _url = _story.imagePath == null ? null : widget.repository.imageUrl(_story);
    if (_url == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ready(_story.id));
    }
  }

  void _ready(String id) {
    if (!mounted || _story.id != id || _loaded) return;
    if (!_story.isAvailableAt(widget.batch.now)) {
      _move(1);
      return;
    }
    setState(() => _loaded = true);
    _sync();
    widget.repository.markSeen(id).catchError((Object e) {
      if (mounted && _story.id == id) {
        setState(() => _error = communityError(e));
      }
    });
  }

  void _move(int direction) {
    if (!mounted ||
        _busy ||
        _covered ||
        _profileOpen ||
        _creationOpen ||
        _menuOpen ||
        _background) {
      return;
    }
    var next = _index + direction;
    while (next >= 0 &&
        next < widget.stories.length &&
        !widget.stories[next].isAvailableAt(widget.batch.now)) {
      next += direction;
    }

    if (next >= widget.stories.length) {
      Navigator.of(context).pop();
      return;
    }
    if (next < 0) {
      _progress.reset();
      _sync();
      return;
    }
    setState(() {
      _index = next;
      _paused = false;
      _prepare();
    });
  }

  void _handleContentTap(TapUpDetails details, Size size) {
    if (_busy || _profileOpen || _menuOpen || _background) return;
    _move(details.localPosition.dx < size.width / 2 ? -1 : 1);
  }

  Future<void> _profile() async {
    _profileOpen = true;
    _sync();
    await context.push('/people/${_story.authorId}');
    if (mounted) {
      _profileOpen = false;
      _sync();
    }
  }

  Future<void> _create() async {
    _creationOpen = true;
    _sync();
    try {
      await showCreateMenu(context, widget.controller);
    } finally {
      if (mounted) {
        _creationOpen = false;
        _sync();
      }
    }
  }

  Future<void> _action(String action) async {
    setState(() => _busy = true);
    _sync();
    try {
      if (action == 'delete') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.tr('¿Eliminar historia?')),
            content: Text(
              AppLocalizations.tr(
                'Dejará de estar disponible para la comunidad.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.tr('Cancelar')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.tr('Eliminar')),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await widget.repository.delete(_story.id);
          if (mounted) Navigator.of(context).pop();
        }
      } else {
        final reason = TextEditingController();
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.tr('Reportar historia')),
            content: TextField(
              controller: reason,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.tr('Motivo (mínimo 5 caracteres)'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.tr('Cancelar')),
              ),
              FilledButton(
                onPressed: () {
                  if (reason.text.trim().length >= 5) {
                    Navigator.pop(context, reason.text.trim());
                  }
                },
                child: Text(AppLocalizations.tr('Enviar reporte')),
              ),
            ],
          ),
        );
        // The dialog route can remain mounted through its closing animation.
        if (result != null) {
          await widget.repository.report(_story.id, result);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.tr('Reporte enviado'))),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = communityError(e));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _sync();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = _story;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _move(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _move(1),
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final viewerWidth = constraints.maxWidth < 640
                  ? constraints.maxWidth
                  : 640.0;
              return Center(
                child: SizedBox(
                  key: const Key('story-viewer-frame'),
                  width: viewerWidth,
                  height: constraints.maxHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_url != null)
                        FutureBuilder<String>(
                          future: _url,
                          builder: (_, snapshot) {
                            if (snapshot.hasError) return _imageError();
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return Image.network(
                              snapshot.data!,
                              fit: BoxFit.contain,
                              frameBuilder: (_, child, frame, synchronous) {
                                if (frame != null || synchronous) {
                                  WidgetsBinding.instance.addPostFrameCallback(
                                    (_) => _ready(story.id),
                                  );
                                }
                                return child;
                              },
                              errorBuilder: (_, _, _) => _imageError(),
                            );
                          },
                        ),
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black87,
                                  Colors.transparent,
                                  Colors.black87,
                                ],
                                stops: [0, .38, 1],
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (details) => _handleContentTap(
                          details,
                          Size(viewerWidth, constraints.maxHeight),
                        ),
                        onLongPressStart: (_) {
                          _holding = true;
                          _sync();
                        },
                        onLongPressEnd: (_) {
                          _holding = false;
                          _sync();
                        },
                        onLongPressCancel: () {
                          _holding = false;
                          _sync();
                        },
                        child: const SizedBox.expand(),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: AppLocalizations.tr(
                                        'Cerrar historia',
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextButton(
                                        onPressed: _profile,
                                        style: TextButton.styleFrom(
                                          alignment: Alignment.centerLeft,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text(
                                          widget
                                                  .profiles[story.authorId]
                                                  ?.fullName ??
                                              AppLocalizations.tr('Historia'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (GoRouter.maybeOf(context) != null &&
                                        canOpenCreateMenu(widget.controller))
                                      MareaCreateAction(
                                        selected: false,
                                        expanded: false,
                                        stacked: false,
                                        enabled: !_busy,
                                        onTap: _create,
                                      ),
                                    PopupMenuButton<String>(
                                      tooltip: AppLocalizations.tr('Acciones'),
                                      enabled: !_busy,
                                      iconColor: Colors.white,
                                      onOpened: () {
                                        _menuOpen = true;
                                        _sync();
                                      },
                                      onCanceled: () {
                                        _menuOpen = false;
                                        _sync();
                                      },
                                      onSelected: (action) {
                                        _menuOpen = false;
                                        _action(action);
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value:
                                              story.authorId == widget.viewerId
                                              ? 'delete'
                                              : 'report',
                                          child: Text(
                                            AppLocalizations.tr(
                                              story.authorId == widget.viewerId
                                                  ? 'Eliminar historia'
                                                  : 'Reportar historia',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                AnimatedBuilder(
                                  animation: _progress,
                                  builder: (_, _) => Row(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < widget.stories.length;
                                        i++
                                      )
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 2,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: i < _index
                                                  ? 1
                                                  : i == _index
                                                  ? _progress.value
                                                  : 0,
                                              backgroundColor: Colors.white24,
                                              color: AppColors.aqua,
                                            ),
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
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 0,
                        child: SafeArea(
                          top: false,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: constraints.maxHeight * .42,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        tooltip: AppLocalizations.tr(
                                          _paused
                                              ? 'Reanudar historia'
                                              : 'Pausar historia',
                                        ),
                                        color: Colors.white,
                                        onPressed: () {
                                          setState(() => _paused = !_paused);
                                          _sync();
                                        },
                                        icon: Icon(
                                          _paused
                                              ? Icons.play_arrow_rounded
                                              : Icons.pause_rounded,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        tooltip: AppLocalizations.tr(
                                          'Historia siguiente',
                                        ),
                                        color: Colors.white,
                                        onPressed: () => _move(1),
                                        icon: const Icon(
                                          Icons.skip_next_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (story.text.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        8,
                                        16,
                                        8,
                                        18,
                                      ),
                                      child: Text(
                                        story.text,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: story.imagePath == null
                                              ? 26
                                              : 18,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _storyTag(
                                        Icons.sell_outlined,
                                        communityCategories[story.category] ??
                                            'Otros',
                                      ),
                                      if (story.targetType != null)
                                        _storyTag(
                                          Icons.people_outline,
                                          story.targetType!.databaseValue,
                                        ),
                                    ],
                                  ),
                                  if (_error != null)
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _storyTag(IconData icon, String label) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    ),
  );

  Widget _imageError() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Text(
          AppLocalizations.tr('No pudimos cargar esta foto.'),
          style: TextStyle(color: Colors.white),
        ),
        TextButton(
          onPressed: () => setState(_prepare),
          child: Text(AppLocalizations.tr('Reintentar')),
        ),
      ],
    ),
  );
}
