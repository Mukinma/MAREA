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
        color: AppColors.brandNavy,
        border: Border.all(color: Colors.white, width: 5),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * .28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
