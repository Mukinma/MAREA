import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/shared/widgets/marea_logo.dart';
import 'package:marea/shared/widgets/creative_artwork.dart';
import 'package:marea/shared/widgets/marea_surface.dart';
import 'package:marea/shared/widgets/primary_button.dart';
import 'package:marea/features/legal/legal_screens.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.paper,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, bounds) {
          final wide = bounds.maxWidth >= 1024;
          final actions = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tu comunidad\ncreativa.',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: wide ? 58 : 38,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                key: const Key('welcome-register'),
                label: 'Crear cuenta',
                onPressed: () => context.go('/register'),
              ),
              const SizedBox(height: 16),
              MareaSurface(
                radius: 16,
                child: OutlinedButton(
                  key: const Key('welcome-login'),
                  onPressed: () => context.go('/login'),
                  child: const Text('Iniciar sesión'),
                ),
              ),
            ],
          );
          return SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 48 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MareaLogo(),
                    SizedBox(height: wide ? 64 : 36),
                    MareaSurface(
                      floating: true,
                      radius: 36,
                      padding: EdgeInsets.all(wide ? 48 : 24),
                      child: wide
                          ? Row(
                              children: [
                                Expanded(flex: 4, child: actions),
                                const SizedBox(width: 64),
                                const Expanded(
                                  flex: 5,
                                  child: CreativeArtwork(),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const CreativeArtwork(),
                                const SizedBox(height: 32),
                                actions,
                              ],
                            ),
                    ),
                    const SizedBox(height: 28),
                    const LegalLinks(),
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
