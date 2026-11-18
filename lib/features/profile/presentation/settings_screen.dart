import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_radius.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/features/notifications/presentation/notification_settings.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
import 'package:marea/shared/widgets/marea_refresh_indicator.dart';
import 'package:marea/shared/widgets/marea_surface.dart';
import 'package:marea/shared/widgets/session_feedback.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.controller, super.key});

  final AppSessionController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showSessionFeedback = false;
  String? _refreshError;

  void _open(String path) {
    setState(() {
      _showSessionFeedback = false;
      _refreshError = null;
    });
    widget.controller.clearFeedback();
    context.push(path);
  }

  Future<void> _refresh() async {
    final controller = widget.controller;
    await controller.refresh();
    if (!mounted || controller.isBusy) return;
    setState(() {
      _showSessionFeedback = false;
      _refreshError =
          controller.failure?.message ??
          (controller.legalError == null
              ? null
              : 'No pudimos actualizar los documentos de MAREA.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ProfilePage(
        title: 'Configuración',
        fallback: controller.needsLegalAcceptance
            ? '/legal/accept'
            : '/profile',
        busy: controller.isBusy,
        body: MareaRefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ProfilePageFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.xl,
                children: [
                  if (_refreshError case final error?)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ProfileMenuSection(
                    title: 'Cuenta',
                    children: [
                      ProfileMenuRow(
                        icon: Icons.person_outline_rounded,
                        title: 'Mis datos personales',
                        subtitle: 'Correo y contraseña',
                        onTap: () => _open('/settings/personal'),
                      ),
                      if (!controller.needsLegalAcceptance) ...[
                        ProfileMenuRow(
                          icon: Icons.shield_outlined,
                          title: 'Privacidad y bloqueos',
                          subtitle: 'Solicitudes de chat y cuentas bloqueadas',
                          onTap: () => _open('/settings/privacy'),
                        ),
                        ProfileMenuRow(
                          icon: Icons.lock_outline_rounded,
                          title: 'Seguridad y sesiones',
                          subtitle:
                              'Verificación en dos pasos y otros dispositivos',
                          onTap: () => _open('/settings/security'),
                        ),
                      ],
                    ],
                  ),
                  if (!controller.needsLegalAcceptance) ...[
                    ProfileMenuSection(
                      title: 'Perfil',
                      children: [
                        ProfileMenuRow(
                          icon: Icons.edit_outlined,
                          title: 'Editar perfil',
                          subtitle: 'Foto, portada y datos públicos',
                          onTap: () => _open('/profile/edit'),
                        ),
                      ],
                    ),
                    ProfileMenuSection(
                      title: 'Preferencias',
                      children: [
                        if (controller.push != null)
                          ProfileMenuRow(
                            icon: Icons.notifications_outlined,
                            title: 'Notificaciones',
                            subtitle: 'Elige qué avisos llegan al teléfono',
                            onTap: () => _open('/settings/notifications'),
                          ),
                        ProfileMenuRow(
                          icon: Icons.location_on_outlined,
                          title: 'Ubicación y avisos cercanos',
                          subtitle: 'Permisos y alertas por proximidad',
                          onTap: () => _open('/nearby-alerts'),
                        ),
                        ProfileMenuRow(
                          icon: Icons.tune_rounded,
                          title: 'Objetivos',
                          subtitle: 'Qué buscas en MAREA',
                          onTap: () => _open('/profile/preferences'),
                        ),
                      ],
                    ),
                  ],
                  ProfileMenuSection(
                    title: 'Información',
                    children: [
                      if (!controller.needsLegalAcceptance)
                        ProfileMenuRow(
                          icon: Icons.help_outline_rounded,
                          title: 'Ayuda y reportes',
                          subtitle:
                              'Contacta a soporte y consulta tus reportes',
                          onTap: () => _open('/settings/support'),
                        ),
                      ProfileMenuRow(
                        icon: Icons.description_outlined,
                        title: 'Términos y condiciones',
                        onTap: () => _open('/terms'),
                      ),
                      ProfileMenuRow(
                        icon: Icons.shield_outlined,
                        title: 'Aviso de privacidad',
                        onTap: () => _open('/privacy'),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfileMenuSection(
                        children: [
                          ProfileMenuRow(
                            icon: Icons.logout_rounded,
                            title: 'Cerrar sesión',
                            destructive: true,
                            chevron: false,
                            onTap: controller.isBusy
                                ? null
                                : () {
                                    setState(() => _showSessionFeedback = true);
                                    controller.signOut();
                                  },
                          ),
                        ],
                      ),
                      if (_showSessionFeedback)
                        SessionFeedback(controller: controller),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({required this.controller, super.key});

  final AppSessionController controller;

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  bool _confirmingDelete = false;
  bool _showDeleteFeedback = false;

  void _open(String path) {
    setState(() => _showDeleteFeedback = false);
    widget.controller.clearFeedback();
    context.push(path);
  }

  Future<void> _delete() async {
    final controller = widget.controller;
    if (_confirmingDelete || controller.isBusy) return;
    setState(() => _confirmingDelete = true);
    try {
      final route = DialogRoute<bool>(
        context: context,
        builder: (_) => const _DeleteAccountDialog(),
      );
      final confirmed = await Navigator.of(
        context,
        rootNavigator: true,
      ).push(route);
      await route.completed;
      if (confirmed == true && mounted && !controller.isBusy) {
        setState(() => _showDeleteFeedback = true);
        await controller.deleteAccount();
      }
    } finally {
      if (mounted) setState(() => _confirmingDelete = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ProfilePage(
        title: 'Mis datos personales',
        fallback: '/settings',
        busy: controller.isBusy,
        body: SingleChildScrollView(
          child: ProfilePageFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.xl,
              children: [
                const _PersonalDataIntro(),
                if (!controller.needsLegalAcceptance)
                  ProfileMenuSection(
                    title: 'Información de cuenta',
                    children: [
                      ProfileMenuRow(
                        icon: Icons.mail_outline_rounded,
                        title: 'Correo electrónico',
                        subtitle: controller.email ?? 'Sin correo disponible',
                        onTap: controller.isBusy
                            ? null
                            : () => _open('/settings/email'),
                      ),
                      ProfileMenuRow(
                        icon: Icons.lock_outline_rounded,
                        title: 'Cambiar contraseña',
                        onTap: controller.isBusy
                            ? null
                            : () => _open('/settings/password'),
                      ),
                    ],
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileMenuSection(
                      title: 'Gestión de cuenta',
                      children: [
                        ProfileMenuRow(
                          key: const Key('open-delete-dialog'),
                          icon: Icons.delete_outline_rounded,
                          title: 'Eliminar cuenta',
                          subtitle: 'Esta acción es permanente',
                          destructive: true,
                          onTap: _confirmingDelete || controller.isBusy
                              ? null
                              : _delete,
                        ),
                      ],
                    ),
                    if (_showDeleteFeedback)
                      SessionFeedback(controller: controller),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalDataIntro extends StatelessWidget {
  const _PersonalDataIntro();

  @override
  Widget build(BuildContext context) => MareaSurface(
    color: AppColors.mist,
    radius: AppRadius.large,
    shadows: const [],
    padding: const EdgeInsets.all(AppSpacing.md),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 285 ||
            MediaQuery.textScalerOf(context).scale(16) > 21;
        final mascot = Image.asset(
          'assets/profile/mareadin-phone.png',
          width: compact ? 64 : 96,
          height: compact ? 64 : 96,
          excludeFromSemantics: true,
        );
        final description = Text(
          'Aquí puedes administrar el correo y la contraseña que usas para entrar a MAREA. Tu correo es privado.',
          style: Theme.of(context).textTheme.bodyMedium,
        );
        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [mascot, description],
              )
            : Row(
                spacing: AppSpacing.md,
                children: [
                  mascot,
                  Expanded(child: description),
                ],
              );
      },
    ),
  );
}

class AccountNotificationsScreen extends StatelessWidget {
  const AccountNotificationsScreen({required this.controller, super.key});

  final AppSessionController controller;

  @override
  Widget build(BuildContext context) => ProfilePage(
    title: 'Notificaciones',
    fallback: '/settings',
    body: SingleChildScrollView(
      child: ProfilePageFrame(
        child: switch (controller.push) {
          final push? => NotificationSettings(controller: push),
          null => const ProfileFormSection(
            children: [Text('Las notificaciones no están disponibles.')],
          ),
        },
      ),
    ),
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    scrollable: true,
    constraints: const BoxConstraints(maxWidth: 440),
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    title: const Text('¿Eliminar tu cuenta?'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        const Text(
          'Se eliminarán permanentemente tu acceso, perfil, preferencias e imágenes. Si la eliminación se interrumpe, vuelve aquí para completarla.',
        ),
        TextField(
          key: const Key('delete-confirmation'),
          controller: _confirmation,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Escribe ELIMINAR'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const Key('confirm-delete-account'),
        style: FilledButton.styleFrom(backgroundColor: AppColors.error),
        onPressed: _confirmation.text == 'ELIMINAR'
            ? () => Navigator.pop(context, true)
            : null,
        child: const Text(
          'Eliminar definitivamente',
          textAlign: TextAlign.center,
        ),
      ),
    ],
  );
}
