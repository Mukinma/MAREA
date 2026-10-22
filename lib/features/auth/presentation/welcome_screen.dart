import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/legal/legal_screens.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({this.controller, super.key});

  final AppSessionController? controller;

  Widget _brand() => Semantics(
    label: 'MAREA. Conecta. Crea. Explora.',
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/brand/MAREA.png', width: 58, height: 58),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/brand/MAREA_LOGOTIPO.png',
                width: 190,
                height: 45,
                fit: BoxFit.contain,
              ),
              const Text(
                'Conecta. Crea. Explora.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _hero(double width, {bool wide = false}) => SizedBox(
    width: width,
    height: width * (wide ? 1.28 : 1.32),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/onboarding/bienvenida.webp',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          excludeFromSemantics: true,
        ),
        Positioned(top: wide ? 44 : 58, left: 24, right: 24, child: _brand()),
      ],
    ),
  );

  Widget _googleIcon() => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Future<void> _signInWithGoogle(BuildContext context) async {
    final controller = this.controller;
    if (controller == null) return;
    final redirectTo = Uri.base.origin;
    await controller.signInWithGoogle(redirectTo: redirectTo);
    if (!context.mounted || controller.failure == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(controller.failure!.message)));
  }

  Widget _actions(BuildContext context, {required bool wide}) => Padding(
    padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'Tu ciudad\ntambién '),
              TextSpan(
                text: 'crea.',
                style: TextStyle(color: Color(0xFF00BDCF)),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: wide
                ? 56
                : MediaQuery.sizeOf(context).width < 390
                ? 38
                : 42,
            height: 1.02,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF070D45),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Conecta con artistas, emprendedores\ny negocios que hacen la ciudad más viva.',
          style: TextStyle(
            fontSize: 16,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 26),
        FilledButton(
          key: const Key('welcome-register'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF005CB8),
            shape: const StadiumBorder(),
            minimumSize: const Size(48, 52),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          onPressed: () => context.go('/register'),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Crear cuenta',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              SizedBox(width: 16),
              Icon(Icons.arrow_forward, size: 24),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          key: const Key('welcome-login'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.actionBlue,
            side: const BorderSide(color: Color(0xFF006AFF)),
            shape: const StadiumBorder(),
            minimumSize: const Size(48, 52),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          onPressed: () => context.go('/login'),
          child: const Text(
            'Iniciar sesión',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        if (kIsWeb && controller != null) ...[
          AnimatedBuilder(
            animation: controller!,
            builder: (context, _) => OutlinedButton.icon(
              key: const Key('welcome-google'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF172B4D),
                side: const BorderSide(color: Color(0xFFD0D9E6)),
                backgroundColor: Colors.white,
                shape: const StadiumBorder(),
                minimumSize: const Size(48, 52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onPressed: controller!.isBusy
                  ? null
                  : () => _signInWithGoogle(context),
              icon: _googleIcon(),
              label: Text(
                controller!.isBusy ? 'Conectando...' : 'Continuar con Google',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        const LegalLinks(compact: true),
        const SizedBox(height: 16),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FCFF),
    body: LayoutBuilder(
      builder: (context, bounds) {
        final wide = bounds.maxWidth >= 1024;
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: wide
                  ? SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: LayoutBuilder(
                                  builder: (_, b) =>
                                      _hero(b.maxWidth, wide: true),
                                ),
                              ),
                            ),
                            Expanded(child: _actions(context, wide: true)),
                          ],
                        ),
                      ),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: LayoutBuilder(
                        builder: (_, b) => Stack(
                          children: [
                            _hero(b.maxWidth),
                            Padding(
                              padding: EdgeInsets.only(
                                top: b.maxWidth * 1.32 - 70,
                              ),
                              child: _actions(context, wide: false),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    ),
  );
}
