import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/data/social_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';

Future<T?> showSocialPanel<T>(BuildContext context, Widget child) {
  final previous = FocusManager.instance.primaryFocus;
  final future = MediaQuery.sizeOf(context).width >= 760
      ? showDialog<T>(
          context: context,
          builder: (_) => Dialog(
            alignment: Alignment.centerRight,
            insetPadding: const EdgeInsets.all(20),
            child: SizedBox(
              width: 440,
              height: MediaQuery.sizeOf(context).height - 40,
              child: child,
            ),
          ),
        )
      : showModalBottomSheet<T>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: AppColors.surface,
          builder: (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: SizedBox(
              height:
                  (MediaQuery.sizeOf(ctx).height -
                      MediaQuery.viewInsetsOf(ctx).bottom) *
                  .88,
              child: child,
            ),
          ),
        );
  return future.whenComplete(() {
    if (previous?.context != null && previous!.canRequestFocus) {
      previous.requestFocus();
    }
  });
}

class SocialPanelFrame extends StatelessWidget {
  const SocialPanelFrame({
    required this.title,
    required this.child,
    this.footer,
    super.key,
  });
  final String title;
  final Widget child;
  final Widget? footer;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Expanded(child: child),
        if (footer != null)
          Flexible(
            flex: 2,
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: footer!,
              ),
            ),
          ),
      ],
    ),
  );
}

class CommentDraft extends TextEditingController {
  String? operationId, submitted;
}

class CommentsPanel extends StatefulWidget {
  const CommentsPanel({
    required this.post,
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
  final CommunityPost post;
  final SocialRepository repository;
  final CommunityRepository community;
  final String? viewerId, commentId;
  final bool moderator;
  final CommentDraft draft;
  final Future<void> Function()? onReady;
  final Future<void> Function() onChanged;
  @override
  State<CommentsPanel> createState() => _CommentsPanelState();
}

class _CommentsPanelState extends State<CommentsPanel> {
  final _comments = <PostComment>[];
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
        widget.post.id,
        offset: reset ? 0 : _offset,
      );
      PostComment? highlighted;
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
        if (highlighted != null && highlighted.postId == widget.post.id) {
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
        widget.post.id,
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

  Future<void> _delete(PostComment c) async {
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
          enabled: !_sending,
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
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
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
                        widget.post.authorId == widget.viewerId ||
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
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
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

class CollaborationPanel extends StatefulWidget {
  const CollaborationPanel({
    required this.postId,
    required this.repository,
    this.onSent,
    super.key,
  });
  final Future<void> Function()? onSent;
  final String postId;
  final SocialRepository repository;
  @override
  State<CollaborationPanel> createState() => _CollaborationPanelState();
}

class _CollaborationPanelState extends State<CollaborationPanel> {
  final _message = TextEditingController();
  bool _busy = false, _sent = false;
  String? _error;
  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty || text.length > 1000) {
      setState(() => _error = 'Escribe entre 1 y 1.000 caracteres.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.sendInterest(widget.postId, text);
      if (mounted) setState(() => _sent = true);
      await widget.onSent?.call();
    } catch (e) {
      if (mounted) setState(() => _error = communityError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SocialPanelFrame(
    title: 'Me interesa colaborar',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_sent) ...[
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.aquaDark,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Interés enviado',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const Text(
            'El autor recibió tu mensaje. Solo ustedes dos pueden consultarlo.',
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Listo'),
          ),
        ] else ...[
          const Text(
            'Cuéntale al autor cómo te gustaría participar. Este mensaje es privado y no inicia un chat.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _message,
            enabled: !_busy,
            maxLength: 1000,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Tu mensaje'),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _send,
            child: Text(_busy ? 'Enviando…' : 'Enviar interés'),
          ),
        ],
      ],
    ),
  );
}

Future<void> sharePost(
  BuildContext context,
  Uri url, {
  Future<ShareResult> Function(ShareParams)? share,
}) async {
  final origin = context.findRenderObject() as RenderBox?;
  final position = origin == null
      ? null
      : origin.localToGlobal(Offset.zero) & origin.size;
  final option = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.share_outlined),
          title: const Text('Compartir enlace'),
          onTap: () => Navigator.pop(ctx, 'share'),
        ),
        ListTile(
          leading: const Icon(Icons.link_rounded),
          title: const Text('Copiar enlace'),
          onTap: () => Navigator.pop(ctx, 'copy'),
        ),
      ],
    ),
  );
  if (option == null || !context.mounted) return;
  Future<void> copy() async {
    await runCommunityAction(
      context,
      () => Clipboard.setData(ClipboardData(text: url.toString())),
      success: 'Enlace copiado.',
    );
  }

  if (option == 'copy') {
    await copy();
    return;
  }
  try {
    final result = await (share ?? SharePlus.instance.share)(
      ShareParams(uri: url, sharePositionOrigin: position),
    );
    if (result.status == ShareResultStatus.unavailable && context.mounted) {
      await _offerCopy(context, copy);
    }
  } catch (_) {
    if (context.mounted) await _offerCopy(context, copy);
  }
}

Future<void> _offerCopy(
  BuildContext context,
  Future<void> Function() copy,
) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Compartir enlace'),
      content: const Text(
        'Puedes copiar el enlace y enviarlo desde otra aplicación.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Copiar enlace'),
        ),
      ],
    ),
  );
  if (yes == true) await copy();
}

String socialDate(DateTime time) {
  final d = time.toLocal();
  return '${d.day}/${d.month}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
