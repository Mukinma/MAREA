import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_radius.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/features/chat/models/chat_models.dart';
import 'package:marea/features/chat/presentation/chat_conversation_screen.dart';
import 'package:marea/features/chat/presentation/chat_widgets.dart';

export 'chat_conversation_screen.dart' show ChatConversationScreen;

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({
    required this.controller,
    this.initialConversationId,
    super.key,
  });

  final AppSessionController controller;
  final String? initialConversationId;

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  List<ChatConversation>? _items;
  String? _selectedId;
  String? _handledInitialId;
  String? _error;
  Future<void>? _loading;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() => _loading ??= _fetch().whenComplete(() {
    _loading = null;
  });

  Future<void> _fetch() async {
    final repository = widget.controller.chatRepository;
    if (repository == null) {
      _error = 'Los mensajes no están disponibles en este momento.';
      return;
    }
    if (_error != null) setState(() => _error = null);
    try {
      final items = await repository.conversations();
      if (!mounted) return;
      setState(() {
        _items = [...items]
          ..sort(
            (a, b) => (b.lastMessageAt ?? b.createdAt).compareTo(
              a.lastMessageAt ?? a.createdAt,
            ),
          );
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      if (_items == null) {
        setState(() => _error = error.toString());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.tr(error.toString()))),
        );
      }
    }
  }

  Future<void> _openConversation(String id) async {
    await context.push(Uri(pathSegments: ['', 'messages', id]).toString());
    if (mounted) await _load();
  }

  void _handleInitialConversation(bool wide) {
    final id = widget.initialConversationId;
    if (id == null || id == _handledInitialId || _items == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.initialConversationId != id ||
          _handledInitialId == id ||
          ModalRoute.isCurrentOf(context) == false) {
        return;
      }
      _handledInitialId = id;
      if (!_items!.any((chat) => chat.id == id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.tr('Este chat ya no está disponible.'),
            ),
          ),
        );
      } else if (wide) {
        setState(() => _selectedId = id);
      } else {
        unawaited(_openConversation(id));
      }
    });
  }

  @override
  Widget build(BuildContext context) => ChatScaffold(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 800;
        _handleInitialConversation(wide);
        final inbox = Column(
          children: [
            ChatHeader(
              title: AppLocalizations.tr('Mensajes'),
              leading: const ChatBackButton(fallback: '/home'),
            ),
            Expanded(child: _inboxContent(wide)),
          ],
        );
        if (!wide) return inbox;

        final selectedId = _selectedId;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1184),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  SizedBox(width: 340, child: inbox),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: .62),
                        border: Border.all(color: AppColors.softBorder),
                        borderRadius: BorderRadius.circular(AppRadius.large),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.large),
                        child: selectedId == null
                            ? ChatNotice(
                                icon: Icons.forum_outlined,
                                title: AppLocalizations.tr(
                                  'Selecciona una conversación',
                                ),
                              )
                            : ChatConversationScreen(
                                key: ValueKey(selectedId),
                                controller: widget.controller,
                                conversationId: selectedId,
                                embedded: true,
                                onConversationChanged: _load,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _inboxContent(bool wide) {
    final error = _error;
    final items = _items;
    if (error != null || items?.isEmpty == true) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ChatNotice(
              icon: error == null
                  ? Icons.forum_outlined
                  : Icons.cloud_off_outlined,
              title: AppLocalizations.tr(
                error == null
                    ? 'Aún no tienes conversaciones.'
                    : 'No pudimos cargar tus mensajes.',
              ),
              description: error == null
                  ? AppLocalizations.tr(
                      'Puedes iniciar una conversación desde el perfil de otra cuenta.',
                    )
                  : AppLocalizations.tr(error),
              actions: [
                if (error != null && widget.controller.chatRepository != null)
                  TextButton(
                    onPressed: _load,
                    child: Text(AppLocalizations.tr('Reintentar')),
                  ),
              ],
            ),
          ],
        ),
      );
    }
    if (items == null) return const ChatLoading();

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            sliver: DecoratedSliver(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.large),
                border: Border.all(color: AppColors.softBorder),
              ),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  indent: 68,
                  endIndent: 12,
                  color: AppColors.softBorder,
                ),
                itemBuilder: (context, index) {
                  final chat = items[index];
                  return _ConversationRow(
                    chat: chat,
                    controller: widget.controller,
                    showChevron: !wide,
                    selected: wide && chat.id == _selectedId,
                    borderRadius: BorderRadius.vertical(
                      top: index == 0
                          ? const Radius.circular(AppRadius.large)
                          : Radius.zero,
                      bottom: index == items.length - 1
                          ? const Radius.circular(AppRadius.large)
                          : Radius.zero,
                    ),
                    onTap: wide
                        ? () => setState(() => _selectedId = chat.id)
                        : () => _openConversation(chat.id),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.chat,
    required this.controller,
    required this.showChevron,
    required this.selected,
    required this.borderRadius,
    required this.onTap,
  });

  final ChatConversation chat;
  final AppSessionController controller;
  final bool showChevron;
  final bool selected;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final status = switch (chat.status) {
      'pending' =>
        chat.requesterId == controller.profile?.id
            ? 'Solicitud enviada'
            : 'Solicitud de mensaje',
      'rejected' => 'Solicitud rechazada',
      'blocked' => 'Chat bloqueado',
      _ => null,
    };
    final preview = status != null
        ? AppLocalizations.tr(status)
        : chat.lastMessageBody ??
              (chat.otherUsername.isEmpty
                  ? AppLocalizations.tr('Aún no hay mensajes.')
                  : '@${chat.otherUsername}');
    final activity = (chat.lastMessageAt ?? chat.createdAt).toLocal();
    final localizations = MaterialLocalizations.of(context);
    final stamp = DateUtils.isSameDay(activity, DateTime.now())
        ? chatTime(context, activity)
        : localizations.formatCompactDate(activity);
    final stackTimestamp = MediaQuery.textScalerOf(context).scale(12) > 16;
    final timestamp = Text(stamp, style: theme.bodySmall);
    final subtitle = Text(
      preview,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.bodyMedium?.copyWith(
        color: status == null ? AppColors.textSecondary : AppColors.brandNavy,
        fontWeight: status == null ? null : FontWeight.w700,
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        type: MaterialType.transparency,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        child: Ink(
          color: selected ? AppColors.mist : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  ChatAvatar(
                    chat: chat,
                    repository: controller.mediaRepository,
                    size: 44,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat.otherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleMedium?.copyWith(
                            color: AppColors.brandNavy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        if (stackTimestamp) ...[
                          subtitle,
                          const SizedBox(height: AppSpacing.xxs),
                          timestamp,
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Expanded(child: subtitle),
                              const SizedBox(width: AppSpacing.xs),
                              timestamp,
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (showChevron) ...[
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
