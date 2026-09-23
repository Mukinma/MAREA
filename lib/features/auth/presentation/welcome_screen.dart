import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/shared/widgets/marea_logo.dart';
import 'package:marea/shared/widgets/creative_artwork.dart';
import 'package:marea/shared/widgets/primary_button.dart';
import 'package:marea/features/legal/legal_screens.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, bounds) {
          final wide = bounds.maxWidth >= 1024;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'TU PRÓXIMA IDEA EMPIEZA AQUÍ',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.aquaDark,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Conecta con lo\nque te mueve.',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: wide ? 58 : 38,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Un lugar para tus ideas, tu talento y las personas con las que quieres crear.',
                style: TextStyle(fontSize: 18, height: 1.6),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  key: const Key('welcome-register'),
                  label: 'Crear mi cuenta',
                  onPressed: () => context.go('/register'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: const Key('welcome-login'),
                  onPressed: () => context.go('/login'),
                  child: const Text('Ya tengo cuenta · Iniciar sesión'),
                ),
              ),
            ],
          );
          return SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 48 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MareaLogo(showTagline: true),
                    SizedBox(height: wide ? 80 : 40),
                    if (wide)
                      Row(
                        children: [
                          Expanded(child: content),
                          const SizedBox(width: 80),
                          const Expanded(child: CreativeArtwork()),
                        ],
                      )
                    else ...[
                      content,
                      const SizedBox(height: 36),
                      const CreativeArtwork(),
                    ],
                    SizedBox(height: wide ? 72 : 24),
                    const Center(child: LegalLinks()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
