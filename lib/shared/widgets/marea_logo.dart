import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';

class MareaLogo extends StatelessWidget {
  const MareaLogo({
    super.key,
    this.compact = false,
    this.showTagline = false,
    this.isotypeOnly = false,
  });
  final bool compact, showTagline, isotypeOnly;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'MAREA. Conecta. Crea. Crece.',
    image: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          isotypeOnly
              ? 'assets/brand/MAREA.png'
              : 'assets/brand/MAREA_LOGOTIPO.png',
          width: isotypeOnly
              ? 44
              : compact
              ? 132
              : 190,
          height: isotypeOnly
              ? 44
              : compact
              ? 52
              : 76,
          fit: BoxFit.contain,
        ),
        if (showTagline)
          const Text(
            'Conecta. Crea. Crece.',
            style: TextStyle(
              color: AppColors.aquaDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    ),
  );
}
