import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/home_feed/data/stories_repository.dart';
import 'package:marea/features/home_feed/models/story.dart';

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
  bool _paused = false,
      _holding = false,
      _background = false,
      _profileOpen = false,
      _menuOpen = false,
      _loaded = false,
      _busy = false;
  Future<String>? _url;
  String? _error;
  Story get _story => widget.stories[_index];
  bool get _shouldPause =>
      _paused ||
      _holding ||
      _background ||
      _profileOpen ||
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
            if (s == AnimationStatus.completed) _move(1);
          });
    _prepare();
    _expiry = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && !_story.isAvailableAt(widget.batch.now)) _move(1);
    });
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
    if (!mounted || _busy || _profileOpen || _menuOpen || _background) return;
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
      _prepare();
    });
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

  Future<void> _action(String action) async {
    _busy = true;
    _sync();
    try {
      if (action == 'delete') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Eliminar historia?'),
            content: const Text(
              'Dejará de estar disponible para la comunidad.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
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
            title: const Text('Reportar historia'),
            content: TextField(
              controller: reason,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo (mínimo 5 caracteres)',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (reason.text.trim().length >= 5) {
                    Navigator.pop(context, reason.text.trim());
                  }
                },
                child: const Text('Enviar reporte'),
              ),
            ],
          ),
        );
        // The dialog route can remain mounted through its closing animation.
        if (result != null) {
          await widget.repository.report(_story.id, result);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Reporte enviado')));
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
        const SingleActivator(LogicalKeyboardKey.space): () {
          setState(() => _paused = !_paused);
          _sync();
        },
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.brandNavy,
          appBar: AppBar(
            backgroundColor: AppColors.brandNavy,
            foregroundColor: Colors.white,
            title: TextButton(
              onPressed: _profile,
              child: Text(
                widget.profiles[story.authorId]?.fullName ?? 'Historia',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            actions: [
              IconButton(
                tooltip: _paused ? 'Reanudar historia' : 'Pausar historia',
                onPressed: () {
                  setState(() => _paused = !_paused);
                  _sync();
                },
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
              ),
              PopupMenuButton<String>(
                enabled: !_busy,
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
                    value: story.authorId == widget.viewerId
                        ? 'delete'
                        : 'report',
                    child: Text(
                      story.authorId == widget.viewerId
                          ? 'Eliminar historia'
                          : 'Reportar historia',
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (_, _) => Row(
                      children: [
                        for (var i = 0; i < widget.stories.length; i++)
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
                ),
                Expanded(
                  child: GestureDetector(
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
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (_url != null)
                            FutureBuilder<String>(
                              future: _url,
                              builder: (_, snapshot) {
                                if (snapshot.hasError) return _imageError();
                                if (!snapshot.hasData) {
                                  return const Padding(
                                    padding: EdgeInsets.all(40),
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                return Image.network(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
                                  frameBuilder: (_, child, frame, synchronous) {
                                    if (frame != null || synchronous) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback(
                                            (_) => _ready(story.id),
                                          );
                                    }
                                    return child;
                                  },
                                  errorBuilder: (_, _, _) => _imageError(),
                                );
                              },
                            ),
                          if (story.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                story.text,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: story.imagePath == null ? 26 : 18,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Historia anterior',
                      color: Colors.white,
                      onPressed: _busy ? null : () => _move(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '${_index + 1}/${widget.stories.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      tooltip: 'Historia siguiente',
                      color: Colors.white,
                      onPressed: _busy ? null : () => _move(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageError() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const Text(
          'No pudimos cargar esta foto.',
          style: TextStyle(color: Colors.white),
        ),
        TextButton(
          onPressed: () => setState(_prepare),
          child: const Text('Reintentar'),
        ),
      ],
    ),
  );
}
