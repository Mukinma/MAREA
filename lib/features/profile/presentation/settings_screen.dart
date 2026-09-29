import 'package:marea/shared/widgets/marea_surface.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_radius.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/shared/widgets/session_feedback.dart';
import 'package:marea/shared/widgets/marea_refresh_indicator.dart';
import 'package:marea/features/legal/legal_screens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.controller, super.key});

  final AppSessionController controller;

  Future<void> _delete(BuildContext context) async {
    final route = DialogRoute<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    final confirmed = await Navigator.of(
      context,
      rootNavigator: true,
    ).push(route);
    await route.completed;
    if (confirmed == true && context.mounted) {
      await controller.deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => Scaffold(
        appBar: AppBar(
          leading: const ProfileBackButton(),
          title: const Text('Configuración'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (controller.isBusy)
                const LinearProgressIndicator(minHeight: 3),
              Expanded(
                child: MareaRefreshIndicator(
                  onRefresh: controller.refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SettingsCard(
                              title: 'Cuenta',
                              children: [
                                ListTile(
                                  leading: const _SettingsIcon(
                                    Icons.mail_outline_rounded,
                                  ),
                                  title: Text(
                                    controller.email ?? 'Sin correo disponible',
                                  ),
                                ),
                                ListTile(
                                  leading: const _SettingsIcon(
                                    Icons.alternate_email_rounded,
                                  ),
                                  title: const Text('Cambiar correo'),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () {
                                    controller.clearFeedback();
                                    context.push('/settings/email');
                                  },
                                ),
                                ListTile(
                                  leading: const _SettingsIcon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  title: const Text('Cambiar contraseña'),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () {
                                    controller.clearFeedback();
                                    context.push('/settings/password');
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _SettingsCard(
                              title: 'Perfil',
                              children: [
                                ListTile(
                                  leading: const _SettingsIcon(
                                    Icons.edit_outlined,
                                  ),
                                  title: const Text('Editar perfil'),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () => context.push('/profile/edit'),
                                ),
                                ListTile(
                                  leading: const _SettingsIcon(
                                    Icons.tune_rounded,
                                  ),
                                  title: const Text('Intereses y objetivos'),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () =>
                                      context.push('/profile/preferences'),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            SessionFeedback(controller: controller),
                            _SettingsCard(
                              title: 'Sesión',
                              children: [
                                ListTile(
                                  leading: const _SettingsIcon(
                                    Icons.logout_rounded,
                                  ),
                                  title: const Text('Cerrar sesión'),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: controller.isBusy
                                      ? null
                                      : () async {
                                          await controller.signOut();
                                        },
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _SettingsCard(
                              title: null,
                              children: [
                                ListTile(
                                  key: const Key('open-delete-dialog'),
                                  leading: const _SettingsIcon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.error,
                                  ),
                                  title: const Text(
                                    'Eliminar cuenta',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Esta acción es permanente.',
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.error,
                                  ),
                                  onTap: controller.isBusy
                                      ? null
                                      : () => _delete(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const LegalLinks(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return MareaSurface(
      color: AppColors.surface,
      radius: AppRadius.large,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ...children,
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Eliminar tu cuenta?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Se eliminarán permanentemente tu acceso, perfil, preferencias e imágenes. Esta acción no se puede deshacer. Si se interrumpe, vuelve aquí para completar la eliminación.',
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Escribe ELIMINAR para confirmar.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('delete-confirmation'),
              controller: _confirmation,
              autofocus: true,
              autocorrect: false,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'ELIMINAR'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirm-delete-account'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: _confirmation.text == 'ELIMINAR'
              ? () => Navigator.of(context).pop(true)
              : null,
          child: const Text('Eliminar definitivamente'),
        ),
      ],
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon(this.icon, {this.color = AppColors.actionBlue});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => MareaSurface(
    radius: 14,
    inset: true,
    color: color == AppColors.error ? AppColors.pink : AppColors.mist,
    child: SizedBox.square(
      dimension: 40,
      child: Icon(icon, color: color, size: 20),
    ),
  );
}
