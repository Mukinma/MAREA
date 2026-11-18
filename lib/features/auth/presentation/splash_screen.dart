import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/auth/presentation/access_layout.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.canvas,
    body: SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 16),
              child: AccessBrand(width: 152),
            ),
          ),
          Center(
            child: MediaQuery.disableAnimationsOf(context)
                ? Semantics(
                    label: 'Cargando Marea',
                    child: const Icon(
                      Icons.hourglass_empty_rounded,
                      color: AppColors.aquaDark,
                    ),
                  )
                : const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Cargando Marea',
                      color: AppColors.aquaDark,
                      strokeWidth: 2.5,
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}
