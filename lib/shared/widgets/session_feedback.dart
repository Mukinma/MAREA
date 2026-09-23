import 'package:flutter/material.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';

class SessionFeedback extends StatelessWidget {
  const SessionFeedback({required this.controller, super.key});
  final AppSessionController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) {
      final error = controller.failure?.message;
      final message = error ?? controller.successMessage;
      if (message == null) return const SizedBox.shrink();
      return Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            message,
            style: TextStyle(
              color: error == null ? AppColors.success : AppColors.error,
            ),
          ),
        ),
      );
    },
  );
}
