import 'package:flutter/material.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/features/chat/data/chat_repository.dart';
import 'package:marea/features/chat/models/chat_models.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';

class ChatPrivacyScreen extends StatefulWidget {
  const ChatPrivacyScreen({
    required this.controller,
    this.repository,
    super.key,
  });

  final AppSessionController controller;
  final ChatPrivacyRepository? repository;

  @override
  State<ChatPrivacyScreen> createState() => _ChatPrivacyScreenState();
}

class _ChatPrivacyScreenState extends State<ChatPrivacyScreen> {
  late final _accountId = widget.controller.profile?.id;
  ChatPrivacySettings? _settings;
  String? _error;
  bool _busy = false;

  ChatPrivacyRepository? get _repository =>
      widget.repository ??
      switch (widget.controller.chatRepository) {
        final ChatPrivacyRepository repository => repository,
        _ => null,
      };

  bool get _sameAccount =>
      mounted &&
      _accountId != null &&
      widget.controller.profile?.id == _accountId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repository = _repository;
    if (repository == null) return;
    await _update(repository.privacySettings);
  }

  Future<void> _changeAudience(ChatRequestAudience? audience) async {
    final current = _settings;
    final repository = _repository;
    if (audience == null ||
        current == null ||
        audience == current.requestAudience ||
        repository == null) {
      return;
    }
    await _update(() async {
      await repository.setRequestAudience(audience);
      return ChatPrivacySettings(
        requestAudience: audience,
        blockedAccounts: current.blockedAccounts,
      );
    });
  }

  Future<void> _unblock(BlockedChatAccount blocked) async {
    final current = _settings;
    final repository = _repository;
    if (current == null || repository == null) return;
    await _update(() async {
      await repository.block(blocked.id, false);
      return ChatPrivacySettings(
        requestAudience: current.requestAudience,
        blockedAccounts: current.blockedAccounts
            .where((account) => account.id != blocked.id)
            .toList(),
      );
    });
  }

  Future<void> _update(Future<ChatPrivacySettings> Function() action) async {
    if (_busy || !_sameAccount) return;
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final settings = await action();
      if (_sameAccount) setState(() => _settings = settings);
    } catch (error) {
      if (_sameAccount) {
        setState(() {
          _error = error is AppFailure
              ? error.message
              : 'No pudimos actualizar tu privacidad. Inténtalo nuevamente.';
        });
      }
    } finally {
      if (_sameAccount) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final available = _repository != null && _sameAccount;
      final settings = available ? _settings : null;
      return ProfilePage(
        title: 'Privacidad y bloqueos',
        fallback: '/settings',
        busy: available && _busy,
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ProfilePageFrame(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.lg,
                  children: [
                    if (!available)
                      const Text(
                        'Los ajustes de privacidad de chat no están disponibles.',
                      )
                    else if (settings != null) ...[
                      _audienceOptions(settings.requestAudience),
                      _blockList(settings.blockedAccounts),
                    ],
                    if (_error case final error? when available) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          error,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      if (settings == null)
                        OutlinedButton(
                          onPressed: _busy ? null : _load,
                          child: const Text('Reintentar'),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _audienceOptions(
    ChatRequestAudience selection,
  ) => RadioGroup<ChatRequestAudience>(
    groupValue: selection,
    onChanged: _changeAudience,
    child: ProfileMenuSection(
      title: 'Solicitudes de chat',
      children: [
        const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Elige quién puede iniciar una conversación contigo. '
            'Las conversaciones aceptadas y las solicitudes pendientes se conservan.',
          ),
        ),
        for (final audience in ChatRequestAudience.values)
          RadioListTile<ChatRequestAudience>(
            value: audience,
            enabled: !_busy,
            minTileHeight: 56,
            title: Text(audience.label),
          ),
      ],
    ),
  );

  Widget _blockList(
    List<BlockedChatAccount> blockedAccounts,
  ) => ProfileMenuSection(
    title: 'Cuentas bloqueadas',
    children: [
      if (blockedAccounts.isEmpty)
        const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text('Tu lista de cuentas bloqueadas está vacía.'),
        ),
      for (final blocked in blockedAccounts)
        Padding(
          key: ValueKey('blocked-chat-account-${blocked.id}'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(blocked.fullName ?? 'Cuenta no disponible'),
              if (blocked.username case final username?)
                Text(
                  '@$username',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              Tooltip(
                message:
                    'Desbloquear a ${blocked.fullName ?? blocked.username ?? 'esta cuenta'}',
                child: TextButton(
                  onPressed: _busy ? null : () => _unblock(blocked),
                  child: const Text('Desbloquear'),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
