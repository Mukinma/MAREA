import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/l10n/app_localizations.dart';
import 'package:marea/l10n/app_localizations_es.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/chat/data/chat_repository.dart';
import 'package:marea/features/chat/models/chat_models.dart';

import 'package:marea/core/localization/app_localizations.dart' as core_l10n;
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
  List<ChatConversation> _items = [];
  String? _selectedId;
  String? _error;
  bool _loading = true;
  bool _initialRequestShown = false;
  ChatRepository get _repo => widget.controller.chatRepository!;
  AppLocalizations get _l10n =>
      AppLocalizations.of(context) ?? AppLocalizationsEs();
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _repo.conversations();
      if (mounted) {
        setState(() {
          _items = items;
          _selectedId =
              items.any(
                (conversation) =>
                    conversation.id == widget.initialConversationId &&
                    conversation.accepted,
              )
              ? widget.initialConversationId
              : _selectedId;
          _loading = false;
          _error = null;
        });
        final initial = items
            .where(
              (conversation) =>
                  conversation.id == widget.initialConversationId &&
                  conversation.pending &&
                  conversation.recipientId == widget.controller.profile?.id,
            )
            .firstOrNull;
        if (initial != null && !_initialRequestShown) {
          _initialRequestShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _reviewPendingRequest(initial);
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return Scaffold(
      appBar: AppBar(title: Text(core_l10n.AppLocalizations.tr(l10n.mensajes))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(core_l10n.AppLocalizations.tr(_error!)))
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 800;
                final list = _list(wide);
                if (!wide) {
                  return RefreshIndicator(onRefresh: _load, child: list);
                }
                final selected = _items
                    .where((c) => c.id == _selectedId)
                    .firstOrNull;
                return Row(
                  children: [
                    SizedBox(width: 340, child: list),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: selected == null
                          ? Center(child: Text(core_l10n.AppLocalizations.tr(l10n.seleccionaConversacion)))
                          : ChatConversationScreen(
                              controller: widget.controller,
                              conversationId: selected.id,
                              embedded: true,
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _list(bool wide) {
    final l10n = _l10n;
    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 180),
          Center(child: Text(core_l10n.AppLocalizations.tr(l10n.sinConversaciones))),
        ],
      );
    }
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (_, i) {
        final chat = _items[i];
        final preview =
            chat.lastMessageBody ??
            (chat.pending
                ? (chat.requesterId == widget.controller.profile?.id
                      ? core_l10n.AppLocalizations.tr(l10n.solicitudEnviada)
                      : core_l10n.AppLocalizations.tr(l10n.solicitudMensaje))
                : '@${chat.otherUsername}');
        return ListTile(
          selected: chat.id == _selectedId,
          leading: CircleAvatar(
            child: Text(
              chat.otherName.isEmpty ? '?' : chat.otherName[0].toUpperCase(),
            ),
          ),
          title: Text(chat.otherName),
          subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: chat.pending
              ? const Icon(Icons.mark_email_unread_outlined)
              : null,
          onTap: () {
            final incomingRequest =
                chat.pending &&
                chat.recipientId == widget.controller.profile?.id;
            if (incomingRequest) {
              _reviewPendingRequest(chat);
            } else if (wide) {
              setState(() => _selectedId = chat.id);
            } else if (chat.accepted) {
              context.push('/messages/${chat.id}');
            }
          },
        );
      },
    );
  }

  Future<void> _reviewPendingRequest(ChatConversation chat) async {
    final l10n = _l10n;
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(core_l10n.AppLocalizations.tr(l10n.solicitudMensaje)),
        content: Text(
          core_l10n.AppLocalizations.tr(
            l10n.solicitudChatQuiereIniciar(chat.otherName),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'profile'),
            child: Text(core_l10n.AppLocalizations.tr(l10n.verPerfil)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'reject'),
            child: Text(core_l10n.AppLocalizations.tr(l10n.rechazar)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'accept'),
            child: Text(core_l10n.AppLocalizations.tr(l10n.aceptar)),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'profile') {
      context.push('/people/${chat.requesterId}');
      return;
    }
    try {
      if (action == 'accept') {
        await _repo.accept(chat.id);
      } else {
        await _repo.reject(chat.id);
      }
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(core_l10n.AppLocalizations.tr(error.toString()))),
        );
      }
    }
  }
}

class ChatConversationScreen extends StatefulWidget {
  const ChatConversationScreen({
    required this.controller,
    required this.conversationId,
    this.embedded = false,
    super.key,
  });
  final AppSessionController controller;
  final String conversationId;
  final bool embedded;
  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  ChatConversation? _conversation;
  StreamSubscription<void>? _subscription;
  bool _busy = false;
  ChatRepository get _repo => widget.controller.chatRepository!;
  AppLocalizations get _l10n =>
      AppLocalizations.of(context) ?? AppLocalizationsEs();
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await _repo.conversations();
      final found = all.where((c) => c.id == widget.conversationId).firstOrNull;
      final messages = await _repo.messages(widget.conversationId);
      if (mounted) {
        setState(() {
          _conversation = found;
          _messages = messages;
        });
      }
      _subscription = _repo.changes(widget.conversationId).listen((_) async {
        final next = await _repo.messages(widget.conversationId);
        if (mounted) setState(() => _messages = next);
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(core_l10n.AppLocalizations.tr(error.toString()))),
        );
      }
    }
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await _repo.send(widget.conversationId, body);
      _text.clear();
      final next = await _repo.messages(widget.conversationId);
      if (mounted) setState(() => _messages = next);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(core_l10n.AppLocalizations.tr(error.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reviewRequest() async {
    final l10n = _l10n;
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(core_l10n.AppLocalizations.tr(l10n.solicitudMensaje)),
        content: Text(
          core_l10n.AppLocalizations.tr(
            l10n.solicitudChatQuiereIniciar(
              _conversation?.otherName ??
                  core_l10n.AppLocalizations.tr(l10n.estaPersona),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'reject'),
            child: Text(core_l10n.AppLocalizations.tr(l10n.rechazar)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'accept'),
            child: Text(core_l10n.AppLocalizations.tr(l10n.aceptar)),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    try {
      if (action == 'accept') {
        await _repo.accept(widget.conversationId);
      } else {
        await _repo.reject(widget.conversationId);
      }
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(core_l10n.AppLocalizations.tr(error.toString()))),
        );
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final chat = _conversation;
    final isRequester = chat?.requesterId == widget.controller.profile?.id;
    final appBar = AppBar(
      title: Text(chat?.otherName ?? core_l10n.AppLocalizations.tr(l10n.chat)),
      actions: [
        if (chat != null)
          PopupMenuButton<String>(
            onSelected: (value) async {
              final l10n = _l10n;
              if (value == 'block') {
                await _repo.block(
                  chat.requesterId == widget.controller.profile?.id
                      ? chat.recipientId
                      : chat.requesterId,
                  true,
                );
              }
              if (value == 'report') {
                await _repo.report(chat.id, null, 'Contenido inapropiado');
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(core_l10n.AppLocalizations.tr(l10n.accionRegistrada))));
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'block', child: Text(core_l10n.AppLocalizations.tr(l10n.bloquearUsuario))),
              PopupMenuItem(
                value: 'report',
                child: Text(core_l10n.AppLocalizations.tr(l10n.reportarConversacion)),
              ),
            ],
          ),
      ],
    );
    final body = chat == null
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              if (chat.pending)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: isRequester
                      ? Text(core_l10n.AppLocalizations.tr(l10n.solicitudEnviadaPodrasEscribir))
                      : Row(
                          children: [
                            Expanded(
                              child: Text(core_l10n.AppLocalizations.tr(l10n.estaPersonaQuiereConversar)),
                            ),
                            TextButton(
                              onPressed: _reviewRequest,
                              child: Text(core_l10n.AppLocalizations.tr(l10n.revisarSolicitud)),
                            ),
                          ],
                        ),
                ),
              if (chat.status == 'rejected')
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(core_l10n.AppLocalizations.tr(l10n.solicitudChatRechazada)),
                ),
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Text(
                          chat.pending
                              ? core_l10n.AppLocalizations.tr(l10n.aunNoHayMensajes)
                              : core_l10n.AppLocalizations.tr(l10n.iniciaLaConversacion),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        controller: _scroll,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final message = _messages[i];
                          final mine =
                              message.senderId == widget.controller.profile?.id;
                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              constraints: const BoxConstraints(maxWidth: 320),
                              decoration: BoxDecoration(
                                color: mine
                                    ? Colors.lightBlue.shade100
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(message.body),
                            ),
                          );
                        },
                      ),
              ),
              if (chat.accepted)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _text,
                            maxLines: 4,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: core_l10n.AppLocalizations.tr(l10n.escribeUnMensaje),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _busy ? null : _send,
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                )
              else if (chat.status == 'blocked')
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(core_l10n.AppLocalizations.tr(l10n.chatBloqueadoTemporalmente)),
                ),
            ],
          );
    if (widget.embedded) {
      return Column(
        children: [
          appBar,
          Expanded(child: body),
        ],
      );
    }
    return Scaffold(appBar: appBar, body: body);
  }
}
