import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';

class MareaRefreshIndicator extends StatelessWidget {
  const MareaRefreshIndicator({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  final RefreshCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const MareaRefreshScrollBehavior(),
      child: RefreshIndicator.adaptive(
        color: AppColors.aquaDark,
        backgroundColor: AppColors.surface,
        displacement: 48,
        onRefresh: onRefresh,
        child: child,
      ),
    );
  }
}

class MareaRefreshScrollBehavior extends MaterialScrollBehavior {
  const MareaRefreshScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
