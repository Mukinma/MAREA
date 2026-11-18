import 'package:marea/features/notifications/presentation/notification_settings.dart';
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
import 'package:marea/core/localization/app_locale_controller.dart';
import 'package:marea/core/localization/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => Scaffold(
        appBar: AppBar(
          leading: const ProfileBackButton(),
          title: Text(l10n.settings),
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
                              title: l10n.account,
                              children: [
                                ListTile(
                                  leading: const _SettingsIcon(
                                    Icons.mail_outline_rounded,
                                  ),
                                  title: Text(controller.email ?? l10n.noEmail),
                                ),
                                ListTile(
                                  leading: const _SettingsIcon(
                                    Icons.alternate_email_rounded,
                                  ),
                                  title: Text(l10n.changeEmail),
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
                                  title: Text(l10n.changePassword),
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
                              title: l10n.profile,
                              children: [
                                ListTile(
                                  leading: const _SettingsIcon(
                                    Icons.edit_outlined,
                                  ),
                                  title: Text(l10n.editProfile),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () => context.push('/profile/edit'),
                                ),
                                ListTile(
                                  leading: const _SettingsIcon(
                                    Icons.tune_rounded,
                                  ),
                                  title: Text(l10n.interests),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () =>
                                      context.push('/profile/preferences'),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _SettingsCard(
                              title: l10n.preferences,
                              children: [
                                ListTile(
                                  leading: const _SettingsIcon(
                                    Icons.language_rounded,
                                  ),
                                  title: Text(l10n.language),
                                  subtitle: Text(
                                    _languageName(
                                      AppLocaleController.of(context).locale,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () => _showLanguagePicker(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (controller.push != null) ...[
                              _SettingsCard(
                                title: l10n.notifications,
                                children: [
                                  NotificationSettings(
                                    controller: controller.push!,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                            SessionFeedback(controller: controller),
                            _SettingsCard(
                              title: l10n.session,
                              children: [
                                ListTile(
                                  leading: const _SettingsIcon(
                                    Icons.logout_rounded,
                                  ),
                                  title: Text(l10n.signOut),
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
                                  title: Text(
                                    l10n.deleteAccount,
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(l10n.permanentAction),
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

  Future<void> _showLanguagePicker(BuildContext context) async {
    final localeController = AppLocaleController.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                localeController.locale.languageCode == 'es'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(AppLocalizations.of(context).spanish),
              onTap: () {
                localeController.setLocale(const Locale('es', 'MX'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                localeController.locale.languageCode == 'en'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(AppLocalizations.of(context).english),
              onTap: () {
                localeController.setLocale(const Locale('en', 'US'));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  String _languageName(Locale locale) =>
      locale.languageCode == 'en' ? 'English' : 'Español';
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
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.deleteQuestion),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.deleteWarning),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.typeDelete,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key(')delete-confirmation'),
              controller: _confirmation,
              autofocus: true,
              autocorrect: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: l10n.deleteConfirmation),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('confirm-delete-account'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: _confirmation.text == l10n.deleteConfirmation
              ? () => Navigator.of(context).pop(true)
              : null,
          child: Text(l10n.deletePermanently),
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
