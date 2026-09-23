import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/shared/widgets/auth_layout.dart';
import 'package:marea/shared/widgets/primary_button.dart';

class CheckEmailScreen extends StatelessWidget {
  const CheckEmailScreen({super.key, this.email});
  final String? email;

  @override
  Widget build(BuildContext context) {
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
            'Revisa tu correo',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            email == null
                ? 'Te enviamos un enlace para confirmar tu cuenta.'
                : 'Te enviamos un enlace a $email para confirmar tu cuenta.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Después de confirmar, vuelve a MAREA e inicia sesión.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Ir a iniciar sesión',
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
