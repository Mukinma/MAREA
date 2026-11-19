import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_radius.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/features/chat/models/chat_models.dart';
import 'package:marea/features/chat/presentation/chat_widgets.dart';

class ChatConversationScreen extends StatefulWidget {
  const ChatConversationScreen({
    required this.controller,
    required this.conversationId,
    this.embedded = false,
    this.onConversationChanged,
    super.key,
  });

  final AppSessionController controller;
  final String conversationId;
  final bool embedded;
  final VoidCallback? onConversationChanged;

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

enum _ConversationAction { block, report }

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  StreamSubscription<void>? _subscription;
  List<ChatMessage> _messages = [];
  ChatConversation? _chat;
  String? _error;
  String? _sendError;
  bool _loading = true;
  bool _busy = false;
  bool _blockedHere = false;
  int _messageRevision = 0;

  String get _id => widget.conversationId;
  String? get _accountId => widget.controller.profile?.id;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repository = widget.controller.chatRepository;
    if (repository == null) {
      _loading = false;
      return;
    }
    if (!_loading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final revision = ++_messageRevision;
    try {
      final conversations = await repository.conversations();
      if (!mounted) return;
      final chat = conversations.where((chat) => chat.id == _id).firstOrNull;
      final messages = chat == null
          ? const <ChatMessage>[]
          : await repository.messages(_id);
      if (!mounted) return;
      setState(() {
        _chat = chat;
        if (revision == _messageRevision) _messages = messages;
        _loading = false;
      });
      if (chat?.accepted == true) {
        _subscription ??= repository
            .changes(_id)
            .listen(
              (_) => unawaited(_refreshMessages()),
              onError: (Object error) => _showError(error),
            );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _refreshMessages() async {
    final revision = ++_messageRevision;
    try {
      final messages = await widget.controller.chatRepository!.messages(_id);
      if (!mounted || revision != _messageRevision) return;
      setState(() => _messages = messages);
    } catch (error) {
      if (mounted && revision == _messageRevision) {
        _showError(error, onRetry: _refreshMessages);
      }
    }
  }

  void _showError(Object error, {VoidCallback? onRetry}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.tr(error.toString())),
        action: onRetry == null
            ? null
            : SnackBarAction(
                label: AppLocalizations.tr('Reintentar'),
                onPressed: onRetry,
              ),
      ),
    );
  }

  Future<void> _send() async {
    final draft = _text.text;
    final message = draft.trim();
    if (message.isEmpty || _busy || _chat?.accepted != true || _blockedHere) {
      return;
    }
    setState(() {
      _busy = true;
      _sendError = null;
    });
    try {
      await widget.controller.chatRepository!.send(_id, message);
      if (!mounted) return;
      if (_text.text == draft) _text.clear();
      widget.onConversationChanged?.call();
      await _refreshMessages();
      if (!mounted || !_scroll.hasClients) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(0);
      } else {
        unawaited(
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _sendError = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _respond({required bool accept}) async {
    final chat = _chat;
    if (_busy ||
        chat == null ||
        !chat.pending ||
        chat.recipientId != _accountId) {
      return;
    }
    setState(() => _busy = true);
    try {
      final repository = widget.controller.chatRepository!;
      if (accept) {
        await repository.accept(_id);
      } else {
        await repository.reject(_id);
      }
      if (!mounted) return;
      widget.onConversationChanged?.call();
      await _load();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _otherAccountId(ChatConversation chat) =>
      chat.requesterId == _accountId ? chat.recipientId : chat.requesterId;

  void _openProfile(ChatConversation chat) {
    context.push(
      Uri(pathSegments: ['', 'people', _otherAccountId(chat)]).toString(),
    );
  }

  Future<void> _performAction(
    _ConversationAction action,
    ChatConversation chat,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repository = widget.controller.chatRepository!;
      switch (action) {
        case _ConversationAction.block:
          await repository.block(_otherAccountId(chat), true);
          if (mounted) setState(() => _blockedHere = true);
        case _ConversationAction.report:
          await repository.report(_id, null, 'Contenido inapropiado');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.tr('Acción registrada.'))),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = _chat;
    final showComposer =
        chat?.accepted == true && !_blockedHere && !_loading && _error == null;
    final header = ChatHeader(
      title: chat?.otherName ?? AppLocalizations.tr('Chat'),
      subtitle: chat == null || chat.otherUsername.isEmpty
          ? null
          : '@${chat.otherUsername}',
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.embedded) const ChatBackButton(fallback: '/messages'),
          if (chat != null) ...[
            if (!widget.embedded) const SizedBox(width: AppSpacing.xxs),
            ChatAvatar(
              chat: chat,
              repository: widget.controller.mediaRepository,
              size: 40,
            ),
          ],
        ],
      ),
      trailing: chat == null
          ? null
          : PopupMenuButton<_ConversationAction>(
              tooltip: AppLocalizations.tr('Más opciones'),
              enabled: !_busy,
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: AppColors.brandNavy,
              ),
              onSelected: (action) => _performAction(action, chat),
              itemBuilder: (_) => [
                if (!_blockedHere)
                  PopupMenuItem(
                    value: _ConversationAction.block,
                    child: Text(AppLocalizations.tr('Bloquear usuario')),
                  ),
                PopupMenuItem(
                  value: _ConversationAction.report,
                  child: Text(AppLocalizations.tr('Reportar conversación')),
                ),
              ],
            ),
    );
    final content = LayoutBuilder(
      builder: (context, viewport) => Column(
        children: [
          header,
          const Divider(height: 1, color: AppColors.softBorder),
          Expanded(child: _body(chat)),
          if (showComposer) _composer(viewport.maxHeight),
        ],
      ),
    );

    if (widget.embedded) return content;
    return ChatScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: content,
        ),
      ),
    );
  }

  Widget _body(ChatConversation? chat) {
    if (_loading) return const ChatLoading();
    final error = _error;
    if (error != null || chat == null) {
      return _scrollableNotice(
        ChatNotice(
          icon: error == null ? Icons.chat_bubble_outline : Icons.cloud_off,
          title: AppLocalizations.tr(
            error == null
                ? 'Este chat ya no está disponible.'
                : 'No pudimos cargar la conversación.',
          ),
          description: error == null ? null : AppLocalizations.tr(error),
          actions: [
            if (error != null)
              TextButton(
                onPressed: _load,
                child: Text(AppLocalizations.tr('Reintentar')),
              ),
          ],
        ),
      );
    }

    final notice = _statusNotice(chat);
    if (_messages.isEmpty) {
      return _scrollableNotice(
        notice ??
            ChatNotice(
              icon: Icons.chat_bubble_outline_rounded,
              title: AppLocalizations.tr('Inicia la conversación.'),
            ),
        nearTop: notice != null,
      );
    }

    return Column(
      children: [
        if (notice != null)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: notice,
            ),
          ),
        Expanded(
          flex: 2,
          child: ListView.builder(
            reverse: true,
            controller: _scroll,
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final date = message.createdAt.toLocal();
              final startsDay =
                  index == _messages.length - 1 ||
                  !DateUtils.isSameDay(
                    date,
                    _messages[index + 1].createdAt.toLocal(),
                  );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (startsDay)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Text(
                        MaterialLocalizations.of(context).formatFullDate(date),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  _MessageBubble(
                    message: message,
                    mine: message.senderId == _accountId,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _scrollableNotice(Widget child, {bool nearTop = false}) =>
      LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: nearTop
                  ? 0
                  : (constraints.maxHeight - AppSpacing.xxl).clamp(
                      0.0,
                      double.infinity,
                    ),
            ),
            child: Center(child: child),
          ),
        ),
      );

  Widget? _statusNotice(ChatConversation chat) {
    if (_blockedHere || chat.status == 'blocked') {
      return ChatNotice(
        icon: Icons.lock_outline_rounded,
        title: AppLocalizations.tr(
          _blockedHere
              ? 'Este chat está bloqueado.'
              : 'Este chat está bloqueado temporalmente.',
        ),
        card: true,
      );
    }
    if (chat.status == 'rejected') {
      return ChatNotice(
        icon: Icons.chat_bubble_outline_rounded,
        title: AppLocalizations.tr('Esta solicitud de chat fue rechazada.'),
        card: true,
      );
    }
    if (chat.pending && chat.requesterId == _accountId) {
      return ChatNotice(
        icon: Icons.schedule_rounded,
        title: AppLocalizations.tr('Solicitud enviada'),
        description: AppLocalizations.tr(
          'Podrás escribir cuando la otra persona acepte.',
        ),
        actions: [
          TextButton.icon(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(AppLocalizations.tr('Actualizar estado')),
          ),
        ],
        card: true,
      );
    }
    if (chat.pending && chat.recipientId == _accountId) {
      return ChatNotice(
        icon: Icons.mark_chat_unread_outlined,
        title: AppLocalizations.tr('Solicitud de mensaje'),
        description: AppLocalizations.trTemplate(
          '{name} quiere iniciar una conversación contigo.',
          {'name': chat.otherName},
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => _openProfile(chat),
            child: Text(AppLocalizations.tr('Ver perfil')),
          ),
          TextButton(
            onPressed: _busy ? null : () => _respond(accept: false),
            child: Text(AppLocalizations.tr('Rechazar')),
          ),
          FilledButton(
            onPressed: _busy ? null : () => _respond(accept: true),
            child: Text(AppLocalizations.tr('Aceptar')),
          ),
        ],
        card: true,
      );
    }
    return null;
  }

  Widget _composer(double viewportHeight) {
    final textTheme = Theme.of(context).textTheme;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.large),
      borderSide: const BorderSide(color: AppColors.softBorder),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.softBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_sendError case final error?)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: viewportHeight * .15),
                  child: SingleChildScrollView(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        AppLocalizations.tr(error),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: (viewportHeight * .38).clamp(48.0, 200.0),
                    ),
                    child: TextField(
                      controller: _text,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      minLines: 1,
                      style: textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.tr('Escribe un mensaje'),
                        hintMaxLines: 1,
                        fillColor: AppColors.paper,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder.copyWith(
                          borderSide: const BorderSide(
                            color: AppColors.actionBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                ValueListenableBuilder(
                  valueListenable: _text,
                  builder: (context, value, _) => IconButton.filled(
                    tooltip: AppLocalizations.tr('Enviar'),
                    onPressed: _busy || value.text.trim().isEmpty
                        ? null
                        : _send,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_upward_rounded),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: mine
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (constraints.maxWidth * .82).clamp(0.0, 520.0),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: BoxDecoration(
              color: mine ? AppColors.mist : AppColors.surface,
              border: Border.all(
                color: mine ? AppColors.border : AppColors.softBorder,
              ),
              borderRadius: BorderRadiusDirectional.only(
                topStart: const Radius.circular(AppRadius.medium),
                topEnd: const Radius.circular(AppRadius.medium),
                bottomStart: Radius.circular(mine ? AppRadius.medium : 5),
                bottomEnd: Radius.circular(mine ? 5 : AppRadius.medium),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(message.body, style: theme.bodyLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  chatTime(context, message.createdAt),
                  style: theme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
