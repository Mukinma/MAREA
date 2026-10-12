import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/home_feed/models/story.dart';
import 'package:marea/features/home_feed/presentation/story_viewer.dart';
import 'package:marea/shared/widgets/profile_image.dart';

class StoriesRail extends StatefulWidget {
  const StoriesRail({required this.controller, super.key});
  final AppSessionController controller;
  @override
  State<StoriesRail> createState() => StoriesRailState();
}

class StoriesRailState extends State<StoriesRail> {
  StoryBatch? _batch;
  final _profiles = <String, CommunityProfile>{};
  String? _error;
  String? _viewerId;
  bool _loading = false;
  Timer? _timer;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _viewerId = widget.controller.profile?.id;
    widget.controller.addListener(_sessionChanged);
    reload();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted &&
          _batch != null &&
          _batch!.stories.any((s) => !s.expiresAt.isAfter(_batch!.now))) {
        setState(
          () => _batch!.stories.removeWhere(
            (s) => !s.expiresAt.isAfter(_batch!.now),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sessionChanged);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> reload() async {
    if (widget.controller.status == AuthStatus.unauthenticated) return;
    final repo = widget.controller.storiesRepository;
    if (repo == null) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final batch = await repo.stories();
      final profiles =
          await widget.controller.communityRepository?.profiles(
            ids: batch.stories.map((s) => s.authorId).toSet().toList(),
          ) ??
          <CommunityProfile>[];
      if (!mounted || generation != _generation) return;
      setState(() {
        _batch = batch;
        _profiles.addEntries(profiles.map((p) => MapEntry(p.id, p)));
        _loading = false;
      });
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = communityError(e);
          _loading = false;
        });
      }
    }
  }

  void _sessionChanged() {
    final viewerId = widget.controller.profile?.id;
    if (viewerId == _viewerId) return;
    _viewerId = viewerId;
    ++_generation;
    setState(() {
      _batch = null;
      _profiles.clear();
      _loading = false;
      _error = null;
    });
    if (viewerId != null) reload();
  }

  Future<void> _create() async {
    await context.push('/stories/new');
    if (mounted) await reload();
  }

  Future<void> _view(List<Story> stories) async {
    final repo = widget.controller.storiesRepository;
    if (repo == null || stories.isEmpty) return;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => StoryViewer(
          stories: stories,
          batch: _batch!,
          repository: repo,
          profiles: _profiles,
          viewerId: widget.controller.profile?.id,
          controller: widget.controller,
        ),
      ),
    );
    if (mounted) await reload();
  }

  Widget _circle({
    required String label,
    required Widget avatar,
    required VoidCallback onTap,
    bool unread = false,
    bool create = false,
  }) => SizedBox(
    width: (64 * MediaQuery.textScalerOf(context).scale(11) / 11).clamp(
      64,
      128,
    ),
    child: Semantics(
      button: true,
      label: create ? 'Crear historia' : 'Historias de $label',
      value: unread ? 'Sin ver' : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: create
                        ? Colors.transparent
                        : unread
                        ? AppColors.aqua
                        : AppColors.border,
                    width: 2,
                  ),
                ),
                child: ClipOval(child: avatar),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.brandNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Story>>{};
    for (final story in _batch?.stories ?? <Story>[]) {
      if (story.isAvailableAt(_batch!.now)) {
        grouped.putIfAbsent(story.authorId, () => []).add(story);
      }
    }
    final ids = grouped.keys.toList()
      ..sort((a, b) {
        final own = widget.controller.profile?.id;
        if (a == own) return -1;
        if (b == own) return 1;
        final aSeen = grouped[a]!.every((s) => s.seen),
            bSeen = grouped[b]!.every((s) => s.seen);
        if (aSeen != bSeen) return aSeen ? 1 : -1;
        return grouped[b]!.last.createdAt.compareTo(grouped[a]!.last.createdAt);
      });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _circle(
                label: 'Tu historia',
                create: true,
                onTap: _create,
                avatar: const ColoredBox(
                  color: AppColors.mint,
                  child: Icon(Icons.add, color: AppColors.brandNavy),
                ),
              ),
              for (final id in ids)
                _circle(
                  label: id == widget.controller.profile?.id
                      ? 'Tú'
                      : _profiles[id]?.fullName ?? 'Usuario',
                  unread: grouped[id]!.any((s) => !s.seen),
                  onTap: () => _view(grouped[id]!),
                  avatar: ProfileImage(
                    path: _profiles[id]?.avatarPath,
                    repository: widget.controller.mediaRepository,
                    fallback: CircleAvatar(
                      backgroundColor: AppColors.mist,
                      child: Text(_profiles[id]?.initials ?? 'M'),
                    ),
                  ),
                ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        if (_error != null)
          TextButton.icon(
            onPressed: reload,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(_error!, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }
}
