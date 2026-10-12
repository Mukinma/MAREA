import 'package:flutter/material.dart';
import 'package:marea/core/config/app_config.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/data/mission_social_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/models/mission_social.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/mission_social_panels.dart';
import 'package:marea/features/community/presentation/reaction_button.dart';
import 'package:marea/features/community/presentation/social_panels.dart';

/// Typed mission interactions; saving and applying belong to the enclosing card.
class MissionSocialActions extends StatefulWidget {
  const MissionSocialActions({
    required this.mission,
    required this.repository,
    required this.community,
    required this.config,
    required this.viewerId,
    this.stats,
    this.onStats,
    this.trailingCTA,
    this.moderator = false,
    super.key,
  });
  final Mission mission;
  final MissionSocialRepository repository;
  final CommunityRepository community;
  final AppConfig config;
  final String? viewerId;
  final MissionSocialStats? stats;
  final ValueChanged<MissionSocialStats>? onStats;
  final Widget? trailingCTA;
  final bool moderator;
  @override
  State<MissionSocialActions> createState() => _MissionSocialActionsState();
}

class _MissionSocialActionsState extends State<MissionSocialActions> {
  late MissionSocialStats _stats;
  final _draft = CommentDraft();
  bool _busy = false;
  String? _error;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _stats = widget.stats ?? MissionSocialStats(missionId: widget.mission.id);
    if (widget.stats == null) _loadStats();
  }

  @override
  void didUpdateWidget(MissionSocialActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mission.id != widget.mission.id ||
        oldWidget.viewerId != widget.viewerId ||
        oldWidget.repository != widget.repository) {
      _generation++;
      _draft.clear();
      _draft.operationId = null;
      _draft.submitted = null;
      _busy = false;
      _error = null;
      _stats = widget.stats ?? MissionSocialStats(missionId: widget.mission.id);
      if (widget.stats == null) _loadStats();
    } else if (oldWidget.stats != widget.stats && widget.stats != null) {
      _stats = widget.stats!;
    }
  }

  Future<void> _loadStats() async {
    final generation = _generation;
    try {
      await _refresh();
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = communityError(error));
      }
    }
  }

  Future<void> _refresh() async {
    final generation = _generation;
    final rows = await widget.repository.stats([widget.mission.id]);
    if (!mounted || generation != _generation) return;
    final stats = rows[widget.mission.id];
    if (stats != null) {
      setState(() => _stats = stats);
      widget.onStats?.call(stats);
    }
  }

  Future<void> _react(PostReaction? next) async {
    if (_busy || widget.viewerId == null) return;
    final generation = _generation;
    final previous = _stats;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.setReaction(widget.mission.id, next);
      if (!mounted || generation != _generation) return;
      // Update only after a confirmed write, then reconcile server totals.
      final stats = MissionSocialStats(
        missionId: widget.mission.id,
        reactionCount:
            previous.reactionCount +
            (previous.myReaction == null && next != null
                ? 1
                : previous.myReaction != null && next == null
                ? -1
                : 0),
        commentCount: previous.commentCount,
        myReaction: next,
      );
      setState(() => _stats = stats);
      widget.onStats?.call(stats);
      await _refresh();
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = communityError(error));
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _comments() => showMissionCommentsPanel(
    context,
    mission: widget.mission,
    repository: widget.repository,
    community: widget.community,
    viewerId: widget.viewerId,
    draft: _draft,
    onChanged: _refresh,
    moderator: widget.moderator,
  );
  @override
  void dispose() {
    _generation++;
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 8,
        children: [
          ReactionButton(
            selected: _stats.myReaction,
            count: _stats.reactionCount,
            enabled: !_busy && widget.viewerId != null,
            onSelected: _react,
            inline: true,
            compact: true,
          ),
          TextButton.icon(
            onPressed: _comments,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 22),
            label: Text(
              '${_stats.commentCount}',
              style: const TextStyle(fontSize: 11),
              semanticsLabel: '${_stats.commentCount} comentarios',
            ),
          ),
          IconButton(
            tooltip: 'Compartir misión',
            onPressed: () =>
                sharePost(context, widget.config.missionUrl(widget.mission.id)),
            icon: const Icon(Icons.shortcut_rounded, size: 22),
          ),
          if (widget.trailingCTA != null) widget.trailingCTA!,
        ],
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
    ],
  );
}
