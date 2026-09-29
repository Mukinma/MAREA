import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/shared/widgets/marea_surface.dart';

class ProfileFormSection extends StatelessWidget {
  const ProfileFormSection({
    required this.children,
    this.title,
    this.icon,
    super.key,
  });
  final List<Widget> children;
  final String? title;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => MareaSurface(
    radius: 24,
    color: AppColors.surface,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.actionBlue, size: 20),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          children[i],
        ],
      ],
    ),
  );
}

class ProfileActionBar extends StatelessWidget {
  const ProfileActionBar({required this.child, this.maxWidth = 720, super.key});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.softBorder)),
        boxShadow: [
          BoxShadow(
            color: Color(0x120B255E),
            blurRadius: 18,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    ),
  );
}

class ProfileBackButton extends StatelessWidget {
  const ProfileBackButton({this.fallback = '/profile', super.key});
  final String fallback;
  @override
  Widget build(BuildContext context) => BackButton(
    onPressed: () {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(fallback);
      }
    },
  );
}
