import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/shared/widgets/marea_logo.dart';

class ConfigurationScreen extends StatelessWidget {
  const ConfigurationScreen({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  children: [
                    const MareaLogo(showTagline: true),
                    const SizedBox(height: AppSpacing.xxl),
                    const Icon(
                      Icons.settings_suggest_outlined,
                      size: 64,
                      color: AppColors.aquaDark,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'Falta conectar Supabase',
                      style: TextStyle(
                        color: AppColors.brandNavy,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Inicia la app con --dart-define=SUPABASE_URL=... y --dart-define=SUPABASE_ANON_KEY=...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
