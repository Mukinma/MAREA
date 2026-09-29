import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/models/post_social.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/social_panels.dart';

class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({
    required this.controller,
    required this.onOpen,
    super.key,
  });
  final AppSessionController controller;
  final ValueChanged<SocialNotification> onOpen;
  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  final _items = <SocialNotification>[];
  final _authors = <String, CommunityProfile>{};
  bool _unreadOnly = false, _loading = true, _more = true, _busy = false;
  String? _error;
  DateTime? _cutoff;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load(reset: true);
    widget.controller.notifications?.refresh();
  }

  Future<void> _load({bool reset = false}) async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.controller.socialRepository!.notifications(
        unreadOnly: _unreadOnly,
        offset: reset ? 0 : _items.length,
      );
      // Snapshot watermark is a server timestamp, independent of the device clock.
      final authors = rows.isEmpty
          ? <CommunityProfile>[]
          : await widget.controller.communityRepository!.profiles(
              ids: rows.map((n) => n.actorId).toSet().toList(),
            );
      if (!mounted || generation != _generation) return;
      setState(() {
        if (reset) {
          _items.clear();
          _cutoff = rows.firstOrNull?.createdAt;
        }
        _items.addAll(rows.where((row) => !_items.any((n) => n.id == row.id)));
        _authors.addEntries(authors.map((a) => MapEntry(a.id, a)));
        _more = rows.length == 30;
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

  Future<void> _markAll() async {
    if (_cutoff == null || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.controller.socialRepository!.markRead(before: _cutoff);
      await widget.controller.notifications?.refresh();
      if (mounted) await _load(reset: true);
    } catch (e) {
      if (mounted) setState(() => _error = communityError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _verb(NotificationKind kind) => switch (kind) {
    NotificationKind.reaction => 'reaccionó a',
    NotificationKind.comment => 'comentó en',
    NotificationKind.interest => 'quiere colaborar en',
  };
  @override
  Widget build(BuildContext context) => SocialPanelFrame(
    title: 'Notificaciones',
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todo'),
                selected: !_unreadOnly,
                onSelected: (_) {
                  setState(() => _unreadOnly = false);
                  _load(reset: true);
                },
              ),
              ChoiceChip(
                label: const Text('Sin leer'),
                selected: _unreadOnly,
                onSelected: (_) {
                  setState(() => _unreadOnly = true);
                  _load(reset: true);
                },
              ),
              TextButton(
                onPressed: _busy || _cutoff == null ? null : _markAll,
                child: Text(_busy ? 'Marcando…' : 'Marcar todo como leído'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final n in _items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: n.isUnread ? AppColors.mint : AppColors.paper,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Icon(switch (n.kind) {
                        NotificationKind.reaction =>
                          Icons.favorite_border_rounded,
                        NotificationKind.comment =>
                          Icons.chat_bubble_outline_rounded,
                        NotificationKind.interest => Icons.handshake_outlined,
                      }, color: AppColors.textSecondary),
                      title: Text(
                        '${_authors[n.actorId]?.fullName ?? 'Cuenta no disponible'} ${_verb(n.kind)} «${n.postTitle}».',
                      ),
                      subtitle: Text(socialDate(n.createdAt)),
                      trailing: n.isUnread
                          ? Semantics(
                              label: 'Sin leer',
                              child: Icon(
                                Icons.circle,
                                size: 8,
                                color: AppColors.aqua,
                              ),
                            )
                          : null,
                      onTap: () => widget.onOpen(n),
                    ),
                  ),
                ),
              if (_error != null)
                CommunityNotice(
                  message: _error!,
                  onRetry: () => _load(reset: _items.isEmpty),
                ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!_loading && _error == null && _items.isEmpty)
                CommunityNotice(
                  message: _unreadOnly
                      ? 'Estás al día. No hay notificaciones sin leer.'
                      : 'Aquí aparecerán las reacciones, comentarios e intereses que recibas.',
                ),
              if (!_loading && _more && _items.isNotEmpty)
                TextButton(
                  onPressed: _load,
                  child: const Text('Cargar más notificaciones'),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<void> openNotifications(
  BuildContext context,
  AppSessionController controller,
) async {
  final router = GoRouter.of(context);
  if (controller.socialRepository == null) return;
  final selected = await showSocialPanel<SocialNotification>(
    context,
    NotificationsPanel(
      controller: controller,
      onOpen: (n) => Navigator.of(context, rootNavigator: true).pop(n),
    ),
  );
  if (selected == null || !context.mounted) return;
  await router.push(
    Uri(
      path: '/posts/${selected.postId}',
      queryParameters: {
        'notification': selected.id,
        if (selected.kind == NotificationKind.comment) ...{
          'panel': 'comments',
          if (selected.sourceId != null) 'comment': selected.sourceId!,
        },
        if (selected.kind == NotificationKind.interest) ...{
          'panel': 'interest',
          if (selected.sourceId != null) 'interest': selected.sourceId!,
        },
      },
    ).toString(),
  );
  await controller.notifications?.refresh();
}
