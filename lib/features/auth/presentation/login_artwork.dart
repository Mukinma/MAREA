import 'package:flutter/material.dart';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/features/auth/presentation/access_layout.dart';

class LoginHero extends StatelessWidget {
  const LoginHero({
    super.key,
    required this.topInset,
    required this.gutter,
    required this.onBack,
  });

  final double topInset;
  final double gutter;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tr = AppLocalizations.tr;
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final mascotWidth = (width * .55).clamp(150.0, 220.0);
        final skyTint = Color.alphaBlend(
          AppColors.aqua.withValues(alpha: .17),
          AppColors.mist,
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [skyTint, AppColors.mist, skyTint],
              stops: const [0, .53, 1],
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  topInset + AppSpacing.xxs,
                  gutter,
                  largeText ? mascotWidth * .62 : AppSpacing.huge,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const SizedBox(width: double.infinity, height: 48),
                        const AccessBrand(width: 128),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: IconButton.outlined(
                            tooltip: tr('Atrás'),
                            onPressed: onBack,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 20,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              side: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: width < 360
                          ? AppSpacing.xl
                          : AppSpacing.xl + AppSpacing.xxs,
                    ),
                    Semantics(
                      header: true,
                      child: Text(
                        tr('¡Hola de nuevo!'),
                        style: textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SizedBox(
                      width: largeText ? double.infinity : width * .58 - gutter,
                      child: Text(
                        tr(
                          'Tu ciudad te está esperando. Inicia sesión y explora lo que hay cerca de ti.',
                        ),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned.fill(
                top: null,
                child: _HeroWave(foreground: false),
              ),
              PositionedDirectional(
                end: -mascotWidth * .14,
                bottom: 0,
                width: mascotWidth,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/auth_design/mascota_login.png',
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              const Positioned.fill(
                top: null,
                child: _HeroWave(foreground: true),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroWave extends StatelessWidget {
  const _HeroWave({required this.foreground});

  final bool foreground;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      height: 60,
      child: CustomPaint(painter: _HeroWavePainter(foreground)),
    ),
  );
}

class _HeroWavePainter extends CustomPainter {
  const _HeroWavePainter(this.foreground);

  final bool foreground;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width, size.height);

    final path = Path();
    if (foreground) {
      path
        ..moveTo(0, .72)
        ..cubicTo(.11, .69, .21, .13, .40, .29)
        ..cubicTo(.55, .42, .66, .60, .80, .53)
        ..cubicTo(.88, .50, .95, .47, 1, .39);
    } else {
      path
        ..moveTo(0, .07)
        ..cubicTo(.12, .51, .22, .68, .36, .59)
        ..cubicTo(.58, .49, .71, .12, .87, .35)
        ..cubicTo(.92, .42, .96, .46, 1, .38);
    }
    path
      ..lineTo(1, 1)
      ..lineTo(0, 1)
      ..close();

    final paint = Paint()
      ..color = foreground
          ? AppColors.profileCanvas
          : AppColors.aqua.withValues(alpha: .21);
    canvas
      ..drawPath(path, paint)
      ..restore();
  }

  @override
  bool shouldRepaint(_HeroWavePainter oldDelegate) =>
      foreground != oldDelegate.foreground;
}

class LoginFooter extends StatelessWidget {
  const LoginFooter({
    super.key,
    required this.bottomInset,
    required this.gutter,
    required this.onRegister,
  });

  final double bottomInset;
  final double gutter;
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.tr;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.profileCanvas, AppColors.mist],
          stops: [.3, 1],
        ),
      ),
      child: Column(
        children: [
          ClipRect(
            key: const ValueKey('login-landscape'),
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: .85,
              child: AspectRatio(
                aspectRatio: 3,
                child: Image.asset(
                  'assets/auth_design/login_landscape.png',
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              0,
              gutter,
              bottomInset + AppSpacing.xxs,
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  tr('¿Aún no tienes cuenta?'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: onRegister,
                  child: Text(
                    tr('Crea tu cuenta'),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
