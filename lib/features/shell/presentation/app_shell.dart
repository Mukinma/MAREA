import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/features/shell/presentation/marea_mobile_navigation.dart';
import 'package:marea/shared/widgets/marea_panel.dart';
import 'package:marea/features/showcase/presentation/create_screen.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/presentation/notifications_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/shell/presentation/marea_create_action.dart';
import 'package:marea/shared/widgets/marea_logo.dart';
import 'package:marea/shared/widgets/marea_refresh_indicator.dart';
import 'package:marea/shared/widgets/marea_surface.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.location,
    required this.child,
    this.onRefresh,
    this.controller,
    this.returnToMissions = false,
    super.key,
  });
  final AppSessionController? controller;
  final String location;
  final Widget child;
  final RefreshCallback? onRefresh;
  final bool returnToMissions;
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
    _Destination('Mapa', '/map', Icons.map_outlined, Icons.map_rounded),
    _Destination(
      'Perfil',
      '/profile',
      Icons.person_outline_rounded,
      Icons.person_rounded,
    ),
  ];
  void _navigate(BuildContext context, String path) {
    if (returnToMissions && path == '/missions' && context.canPop()) {
      context.pop();
    } else if (location != path) {
      context.go(path);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final desktop = bounds.maxWidth >= 600;
      final profileLayout =
          location == '/profile' || location.startsWith('/people/');
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

      const brandWidth = 44.0;
      final navigationWidth = _destinations.fold(
        12.0,
        (width, destination) =>
            width + 59 + measure(AppLocalizations.tr(destination.label)),
      );
      final toolbarPadding = bounds.maxWidth >= 1024 ? 80 : 64;
      final compact =
          !desktop ||
          bounds.maxWidth < 1024 ||
          largeText ||
          bounds.maxWidth <
              brandWidth +
                  108 +
                  navigationWidth +
                  72 +
                  measure(AppLocalizations.tr('Crear')) +
                  toolbarPadding +
                  32;
      // Bound the nested Navigator's BlockSemantics to the content region.
      // Its active route must not hide the sibling header or dock.
      final content = Semantics(
        container: true,
        explicitChildNodes: true,
        child: onRefresh == null
            ? child
            : MareaRefreshIndicator(onRefresh: onRefresh!, child: child),
      );
      final navigation = MareaSurface(
        key: const Key('top-navigation'),
        floating: true,
        radius: 22,
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final destination in _destinations)
              _NavigationItem(
                destination: destination,
                selected: location.startsWith(destination.path),
                showLabel: !compact,
                onTap: () => _navigate(context, destination.path),
              ),
          ],
        ),
      );
      final create = MareaCreateAction(
        selected: location.startsWith('/create'),
        expanded: desktop && !compact,
        stacked: !desktop,
        onTap: () async {
          if (controller == null) {
            context.go('/create');
            return;
          }
          await showCreateMenu(context, controller!);
        },
      );
      if (desktop) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    bounds.maxWidth >= 1024 ? 24 : 16,
                    12,
                    bounds.maxWidth >= 1024 ? 24 : 16,
                    12,
                  ),
                  child: MareaSurface(
                    radius: 24,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const MareaLogo(compact: true, isotypeOnly: true),
                        const Spacer(),
                        navigation,
                        const Spacer(),
                        ..._utilities(context),
                        const SizedBox(width: 8),
                        if (controller == null ||
                            canOpenCreateMenu(controller!))
                          create,
                      ],
                    ),
                  ),
                ),
                Expanded(child: content),
              ],
            ),
          ),
        );
      }
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: AppColors.profileCanvas,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          extendBody: !profileLayout,
          backgroundColor: profileLayout ? AppColors.profileCanvas : null,
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                if (location != '/map' && !profileLayout)
                  ColoredBox(
                    color: location == '/missions'
                        ? AppColors.profileCanvas
                        : AppColors.surface,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        MediaQuery.paddingOf(context).top,
                        16,
                        0,
                      ),
                      child: SizedBox(
                        height: 56,
                        child: location == '/home' || location == '/missions'
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Center(child: MareaLogo(compact: true)),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: _notificationButton(context),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: _messageButton(context),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  const MareaLogo(compact: true),
                                  const Spacer(),
                                  ..._utilities(context),
                                ],
                              ),
                      ),
                    ),
                  ),
                Expanded(child: content),
              ],
            ),
          ),
          bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
              ? null
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: MareaPanelAwareDock(
                    child: SafeArea(
                      top: false,
                      minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: MareaMobileNavigation(
                              location: location,
                              selectedDestination:
                                  MobileDestination.forLocation(location),
                              navigationChanges: GoRouter.maybeOf(
                                context,
                              )?.routerDelegate,
                              onSelected: (destination) =>
                                  _navigate(context, destination.path),
                            ),
                          ),
                          if (controller != null &&
                              canOpenCreateMenu(controller!)) ...[
                            const SizedBox(width: 8),
                            create,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      );
    },
  );

  Widget _notificationButton(BuildContext context) {
    final notifications = controller?.notifications;
    if (notifications == null) {
      return const SizedBox(width: 48);
    }
    return ListenableBuilder(
      listenable: notifications,
      builder: (context, _) => IconButton(
        tooltip: AppLocalizations.tr('Notificaciones'),
        onPressed: () => openNotifications(context, controller!),
        icon: Badge(
          isLabelVisible: notifications.unread > 0,
          backgroundColor: AppColors.aqua,
          smallSize: 7,
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.brandNavy,
          ),
        ),
      ),
    );
  }

  Widget _messageButton(BuildContext context) {
    if (controller?.chatRepository == null) {
      return const SizedBox(width: 48);
    }
    return IconButton(
      tooltip: AppLocalizations.tr('Mensajes'),
      onPressed: () => context.push('/messages'),
      icon: const Icon(
        Icons.chat_bubble_outline_rounded,
        color: AppColors.brandNavy,
      ),
    );
  }

  List<Widget> _utilities(BuildContext context) => [
    IconButton(
      tooltip: AppLocalizations.tr('Guardados'),
      onPressed: () => context.go('/explore?section=saved'),
      icon: Icon(
        Icons.bookmark_border_rounded,
        semanticLabel: AppLocalizations.tr('Guardados'),
        color: AppColors.textSecondary,
      ),
    ),
    if (controller?.chatRepository != null)
      IconButton(
        tooltip: AppLocalizations.tr('Mensajes'),
        onPressed: () => context.push('/messages'),
        icon: Icon(
          Icons.chat_bubble_outline_rounded,
          semanticLabel: AppLocalizations.tr('Mensajes'),
          color: AppColors.textSecondary,
        ),
      ),
    if (controller?.notifications != null)
      ListenableBuilder(
        listenable: controller!.notifications!,
        builder: (context, _) => Semantics(
          value: controller!.notifications!.unread > 0
              ? AppLocalizations.trTemplate('{count} sin leer', {
                  'count': '${controller!.notifications!.unread}',
                })
              : AppLocalizations.tr('Sin pendientes'),
          child: IconButton(
            tooltip: AppLocalizations.tr('Notificaciones'),
            onPressed: () => openNotifications(context, controller!),
            icon: Badge(
              isLabelVisible: controller!.notifications!.unread > 0,
              backgroundColor: AppColors.aqua,
              smallSize: 7,
              child: Icon(
                Icons.notifications_none_rounded,
                semanticLabel: AppLocalizations.tr('Notificaciones'),
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
  ];
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
  Widget build(BuildContext context) {
    final label = AppLocalizations.tr(destination.label);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: label,
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
                        label,
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
}

class _Destination {
  const _Destination(this.label, this.path, this.icon, this.selectedIcon);
  final String label, path;
  final IconData icon, selectedIcon;
}
