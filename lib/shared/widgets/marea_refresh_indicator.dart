import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';

class MareaRefreshIndicator extends StatefulWidget {
  const MareaRefreshIndicator({
    required this.onRefresh,
    required this.child,
    super.key,
  });
  final RefreshCallback onRefresh;
  final Widget child;
  @override
  State<MareaRefreshIndicator> createState() => _MareaRefreshIndicatorState();
}

class _MareaRefreshIndicatorState extends State<MareaRefreshIndicator> {
  RefreshIndicatorStatus? _status;
  @override
  Widget build(BuildContext context) => ScrollConfiguration(
    behavior: const MareaRefreshScrollBehavior(),
    child: Stack(
      children: [
        RefreshIndicator.noSpinner(
          onRefresh: widget.onRefresh,
          onStatusChange: (status) {
            if (mounted) setState(() => _status = status);
          },
          child: widget.child,
        ),
        if (_status != null &&
            _status != RefreshIndicatorStatus.done &&
            _status != RefreshIndicatorStatus.canceled)
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: Semantics(
              label: 'Actualizando contenido',
              liveRegion: true,
              child: const LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.aquaDark,
                backgroundColor: AppColors.mist,
              ),
            ),
          ),
      ],
    ),
  );
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
