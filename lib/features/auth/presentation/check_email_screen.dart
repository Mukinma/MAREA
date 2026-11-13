import 'package:marea/l10n/app_localizations.dart';
import 'package:marea/l10n/app_localizations_es.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/shared/widgets/auth_layout.dart';
import 'package:marea/shared/widgets/primary_button.dart';

import 'package:marea/core/localization/app_localizations.dart' as core_l10n;
class CheckEmailScreen extends StatelessWidget {
  const CheckEmailScreen({super.key, this.email});
  final String? email;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    return AuthLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            size: 68,
            color: AppColors.aquaDark,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            core_l10n.AppLocalizations.tr(l10n.revisaTuCorreo),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            email == null
                ? core_l10n.AppLocalizations.tr(l10n.enlaceConfirmarCuenta)
                : core_l10n.AppLocalizations.tr(
                    l10n.enlaceCorreoConfirmarCuenta(email!),
                  ),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            core_l10n.AppLocalizations.tr(l10n.despuesConfirmarSesion),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: core_l10n.AppLocalizations.tr(l10n.irIniciarSesion),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
