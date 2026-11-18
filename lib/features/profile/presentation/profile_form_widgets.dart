import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_radius.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/shared/widgets/marea_surface.dart';

class ProfileFlatStyle extends StatelessWidget {
  const ProfileFlatStyle({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MareaFlatSurfaces.of(context)) return child;
    final theme = Theme.of(context);
    return MareaFlatSurfaces(
      child: Theme(
        data: theme.copyWith(
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            filled: true,
            fillColor: AppColors.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          dialogTheme: theme.dialogTheme.copyWith(
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          bottomSheetTheme: theme.bottomSheetTheme.copyWith(
            elevation: 0,
            modalElevation: 0,
          ),
          floatingActionButtonTheme: theme.floatingActionButtonTheme.copyWith(
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            disabledElevation: 0,
          ),
        ),
        child: child,
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.title,
    required this.body,
    this.fallback = '/profile',
    this.onBack,
    this.action,
    this.busy = false,
    super.key,
  });

  final String title, fallback;
  final Widget body;
  final VoidCallback? onBack;
  final Widget? action;
  final bool busy;

  @override
  Widget build(BuildContext context) => ProfileFlatStyle(
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.profileCanvas,
        body: SafeArea(
          child: Column(
            children: [
              ProfilePageFrame(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    ProfileBackButton(
                      fallback: fallback,
                      onPressed: onBack,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.brandNavy,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Semantics(
                        header: true,
                        namesRoute: switch (defaultTargetPlatform) {
                          TargetPlatform.iOS || TargetPlatform.macOS => null,
                          _ => true,
                        },
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.brandNavy,
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (busy) const LinearProgressIndicator(minHeight: 3),
              Expanded(child: body),
              if (action case final action?)
                Material(
                  color: AppColors.profileCanvas,
                  child: ProfilePageFrame(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: action,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ProfilePageFrame extends StatelessWidget {
  const ProfilePageFrame({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({required this.children, this.title, super.key});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (title case final title?) ...[
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      MareaSurface(
        color: AppColors.surface,
        radius: AppRadius.large,
        shadows: const [],
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.border),
              children[i],
            ],
          ],
        ),
      ),
    ],
  );
}

class ProfileMenuRow extends StatelessWidget {
  const ProfileMenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
    this.chevron = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive, chevron;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.brandNavy;
    final text = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      minVerticalPadding: 8,
      minTileHeight: 56,
      leading: ExcludeSemantics(child: Icon(icon, color: color, size: 23)),
      title: Text(title, style: text.titleMedium?.copyWith(color: color)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
      trailing: chevron && onTap != null
          ? const ExcludeSemantics(
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

class ProfileSheetContent extends StatelessWidget {
  const ProfileSheetContent({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ...children,
        ],
      ),
    ),
  );
}

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
  const ProfileBackButton({
    this.fallback = '/profile',
    this.onPressed,
    this.style,
    super.key,
  });
  final String fallback;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  @override
  Widget build(BuildContext context) => BackButton(
    style: style,
    onPressed:
        onPressed ??
        () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(fallback);
          }
        },
  );
}
