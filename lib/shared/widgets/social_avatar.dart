import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';

class SocialAvatar extends StatelessWidget {
  const SocialAvatar({required this.initials, super.key, this.size = 96});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.mist,
        border: Border.all(color: AppColors.aqua, width: 3),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.brandNavy,
          fontSize: size * .28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
