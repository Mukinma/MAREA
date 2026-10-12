import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/data/mission_social_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/models/mission_social.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/social_panels.dart';
import 'package:marea/shared/widgets/marea_skeleton.dart';

Future<void> showMissionCommentsPanel(
  BuildContext context, {
  required Mission mission,
  required MissionSocialRepository repository,
  required CommunityRepository community,
  required String? viewerId,
  required CommentDraft draft,
  required Future<void> Function() onChanged,
  bool moderator = false,
  String? commentId,
  Future<void> Function()? onReady,
}) => showSocialPanel<void>(
  context,
  MissionCommentsPanel(
    mission: mission,
    repository: repository,
    community: community,
    viewerId: viewerId,
    draft: draft,
    onChanged: onChanged,
    moderator: moderator,
    commentId: commentId,
    onReady: onReady,
  ),
);

class MissionCommentsPanel extends StatefulWidget {
  const MissionCommentsPanel({
    required this.mission,
    required this.repository,
    required this.community,
    required this.viewerId,
    required this.draft,
    required this.onChanged,
    this.moderator = false,
    this.commentId,
    this.onReady,
    super.key,
  });
  final Mission mission;
  final MissionSocialRepository repository;
  final CommunityRepository community;
  final String? viewerId, commentId;
  final bool moderator;
  final CommentDraft draft;
  final Future<void> Function()? onReady;
  final Future<void> Function() onChanged;
  @override
  State<MissionCommentsPanel> createState() => _MissionCommentsPanelState();
}

class _MissionCommentsPanelState extends State<MissionCommentsPanel> {
  final _comments = <MissionComment>[];
  final _authors = <String, CommunityProfile>{};
  bool _loading = true, _sending = false, _more = true;
  String? _error;
  bool _ready = false;
  int _offset = 0;
  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.repository.comments(
        widget.mission.id,
        offset: reset ? 0 : _offset,
      );
      MissionComment? highlighted;
      if (reset &&
          widget.commentId != null &&
          !rows.any((c) => c.id == widget.commentId)) {
        highlighted = await widget.repository.comment(widget.commentId!);
      }
      final authors = await widget.community.profiles(
        ids: {
          ...rows.map((c) => c.authorId),
          if (highlighted != null) highlighted.authorId,
        }.toList(),
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _comments.clear();
          _offset = 0;
        }
        _offset += rows.length;
        for (final c in rows) {
          if (!_comments.any((v) => v.id == c.id)) _comments.add(c);
        }
        if (highlighted != null && highlighted.missionId == widget.mission.id) {
          _comments.insert(0, highlighted);
        }
        _authors.addEntries(authors.map((a) => MapEntry(a.id, a)));
        _more = rows.length == 30;
        _loading = false;
      });
      if (!_ready &&
          (widget.commentId == null ||
              _comments.any((c) => c.id == widget.commentId))) {
        await widget.onReady?.call();
        _ready = true;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = communityError(e);
        });
      }
    }
  }

  Future<void> _send() async {
    final body = widget.draft.text.trim();
    if (_sending) return;
    if (body.isEmpty || body.length > 1000) {
      setState(() => _error = 'Escribe entre 1 y 1.000 caracteres.');
      return;
    }
    if (widget.draft.submitted != body) {
      widget.draft.submitted = body;
      widget.draft.operationId = const Uuid().v4();
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.repository.createComment(
        widget.mission.id,
        body,
        widget.draft.operationId!,
      );
      if (!mounted) return;
      widget.draft.clear();
      widget.draft.submitted = null;
      widget.draft.operationId = null;
      await _load(reset: true);
      await widget.onChanged();
    } catch (e) {
      if (mounted) setState(() => _error = communityError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(MissionComment c) async {
    if (!await confirmCommunityDelete(context)) return;
    if (!mounted) return;
    await runCommunityAction(
      context,
      () => widget.repository.deleteComment(c.id),
      success: 'Comentario retirado.',
    );
    if (mounted) {
      // Reconcile a lost deletion response with the server before offering retry.
      await _load(reset: true);
      try {
        await widget.onChanged();
      } catch (e) {
        if (mounted) setState(() => _error = communityError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) => SocialPanelFrame(
    title: 'Comentarios',
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.draft,
          enabled: !_sending && widget.viewerId != null,
          maxLength: 1000,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Tu comentario'),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _sending || widget.viewerId == null ? null : _send,
            icon: const Icon(Icons.send_outlined),
            label: Text(_sending ? 'Enviando…' : 'Enviar'),
          ),
        ),
      ],
    ),
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (widget.commentId != null &&
            !_loading &&
            !_comments.any((c) => c.id == widget.commentId))
          const CommunityNotice(message: 'Este comentario fue retirado.'),
        for (final c in _comments)
          Container(
            key: ValueKey(c.id),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.id == widget.commentId
                  ? AppColors.mint
                  : AppColors.paper,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _authors[c.authorId]?.fullName ??
                            'Cuenta no disponible',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (c.authorId == widget.viewerId ||
                        widget.mission.authorId == widget.viewerId ||
                        widget.moderator)
                      IconButton(
                        tooltip: 'Retirar comentario',
                        onPressed: () => _delete(c),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                  ],
                ),
                SelectableText(
                  c.body,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  socialDate(c.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        if (_error != null)
          CommunityNotice(
            message: _error!,
            onRetry: () => _load(reset: _comments.isEmpty),
          ),
        if (_loading && _comments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: MareaSkeleton(kind: SkeletonKind.list)),
          ),
        if (!_loading && _comments.isEmpty && _error == null)
          const CommunityNotice(
            message: 'Abre la conversación con el primer comentario.',
          ),
        if (!_loading && _more && _comments.isNotEmpty)
          TextButton(
            onPressed: _load,
            child: const Text('Cargar más comentarios'),
          ),
      ],
    ),
  );
}
