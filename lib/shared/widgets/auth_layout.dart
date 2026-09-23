import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/shared/widgets/marea_logo.dart';
import 'package:marea/shared/widgets/creative_artwork.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({required this.child, super.key, this.register = false});

  final Widget child;
  final bool register;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1024) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: _BrandPanel(register: register),
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Material(
                    color: AppColors.surface,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.xxxl),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MareaLogo(compact: true, showTagline: true),
                      const SizedBox(height: 28),
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.aqua,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 24),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.register});

  final bool register;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ColoredBox(
        color: AppColors.paper,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.all(constraints.maxWidth < 540 ? 32 : 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const MareaLogo(showTagline: true),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PERSONAS · IDEAS · POSIBILIDADES',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          register
                              ? 'Aquí caben\ntodas tus ideas.'
                              : 'Las buenas ideas\nencuentran gente.',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontSize: constraints.maxWidth < 540 ? 38 : 46,
                                height: 1.12,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Un lugar para conocer, compartir lo que te mueve y empezar algo juntos.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 30),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxHeight < 800
                                  ? 360
                                  : double.infinity,
                            ),
                            child: const CreativeArtwork(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.aquaDark,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Flexible(
                        child: Text(
                          'Conecta. Crea. Crece.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
