import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_depth.dart';
import 'package:marea/shared/widgets/marea_logo.dart';
import 'package:marea/shared/widgets/marea_refresh_indicator.dart';
import 'package:marea/shared/widgets/marea_surface.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.location,
    required this.child,
    this.onRefresh,
    super.key,
  });
  final String location;
  final Widget child;
  final RefreshCallback? onRefresh;
  static const _destinations = [
    _Destination('Inicio', '/home', Icons.home_outlined, Icons.home_rounded),
    _Destination(
      'Explorar',
      '/explore',
      Icons.search_rounded,
      Icons.search_rounded,
    ),
    _Destination(
      'Misiones',
      '/missions',
      Icons.flag_outlined,
      Icons.flag_rounded,
    ),
    _Destination(
      'Perfil',
      '/profile',
      Icons.person_outline_rounded,
      Icons.person_rounded,
    ),
  ];
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final desktop = bounds.maxWidth >= 600;
      final scaler = MediaQuery.textScalerOf(context);
      final largeText = scaler.scale(14) > 17;
      double measure(String text, {double size = 14, double spacing = 0}) {
        final painter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: size,
              fontWeight: FontWeight.w800,
              letterSpacing: spacing,
            ),
          ),
          textDirection: Directionality.of(context),
          textScaler: scaler,
        )..layout();
        return painter.width;
      }

      final brandWidth = 42 + measure('MAREA', size: 19, spacing: 2.2);
      final navigationWidth = _destinations.fold(
        12.0,
        (width, destination) => width + 59 + measure(destination.label),
      );
      final toolbarPadding = bounds.maxWidth >= 1024 ? 80 : 48;
      final compact =
          !desktop ||
          bounds.maxWidth < 1024 ||
          largeText ||
          bounds.maxWidth <
              brandWidth +
                  navigationWidth +
                  72 +
                  measure('Crear') +
                  toolbarPadding +
                  32;
      final active = _destinations
          .where((d) => location.startsWith(d.path))
          .firstOrNull;
      final label = TextPainter(
        text: TextSpan(
          text: active?.label ?? '',
          style: const TextStyle(
            fontFamily: 'NunitoSans',
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      // Reserve four 48px touch targets, dock padding and the separate action.
      final labelFits = desktop
          ? bounds.maxWidth >=
                brandWidth + 216 + label.width + 56 + toolbarPadding
          : bounds.maxWidth >= 316 + label.width;
      final content = onRefresh == null
          ? child
          : MareaRefreshIndicator(onRefresh: onRefresh!, child: child);
      final navigation = MareaSurface(
        key: Key(desktop ? 'top-navigation' : 'mobile-dock'),
        floating: true,
        radius: desktop ? 22 : 32,
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final destination in _destinations)
              _NavigationItem(
                destination: destination,
                selected: location.startsWith(destination.path),
                showLabel:
                    !compact ||
                    (!largeText &&
                        labelFits &&
                        location.startsWith(destination.path)),
                onTap: () => context.go(destination.path),
              ),
          ],
        ),
      );
      final create = _CreateAction(
        selected: location.startsWith('/create'),
        expanded: desktop && !compact,
        onTap: () => context.go('/create'),
      );
      if (desktop) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    bounds.maxWidth >= 1024 ? 40 : 24,
                    20,
                    bounds.maxWidth >= 1024 ? 40 : 24,
                    12,
                  ),
                  child: Row(
                    children: [
                      const MareaLogo(compact: true),
                      const Spacer(),
                      navigation,
                      const Spacer(),
                      create,
                    ],
                  ),
                ),
                Expanded(child: content),
              ],
            ),
          ),
        );
      }
      return Scaffold(
        body: content,
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: navigation),
              const SizedBox(width: 12),
              create,
            ],
          ),
        ),
      );
    },
  );
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.destination,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });
  final _Destination destination;
  final bool selected, showLabel;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: destination.label,
    excludeSemantics: true,
    onTap: onTap,
    child: Tooltip(
      message: destination.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        decoration: BoxDecoration(
          color: selected ? AppColors.mint : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: showLabel ? 14 : 12,
                vertical: 13,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 23,
                    color: selected
                        ? AppColors.brandNavy
                        : AppColors.textSecondary,
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 8),
                    Text(
                      destination.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: selected
                            ? AppColors.brandNavy
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CreateAction extends StatelessWidget {
  const _CreateAction({
    required this.onTap,
    required this.selected,
    required this.expanded,
  });
  final VoidCallback onTap;
  final bool selected, expanded;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Crear',
    button: true,
    selected: selected,
    excludeSemantics: true,
    onTap: onTap,
    child: Tooltip(
      message: 'Crear',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppDepth.action,
        ),
        child: Material(
          key: const Key('create-destination'),
          color: AppColors.actionBlue,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: expanded ? 20 : 16,
                vertical: 16,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                  if (expanded) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'Crear',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Destination {
  const _Destination(this.label, this.path, this.icon, this.selectedIcon);
  final String label, path;
  final IconData icon, selectedIcon;
}
