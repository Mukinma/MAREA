import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/shared/widgets/marea_logo.dart';
import 'package:marea/shared/widgets/marea_refresh_indicator.dart';

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

  static const _destinations = <_Destination>[
    _Destination('Inicio', '/home', Icons.home_outlined, Icons.home_rounded),
    _Destination(
      'Explorar',
      '/explore',
      Icons.search_rounded,
      Icons.search_rounded,
    ),
    _Destination('Crear', '/create', Icons.add_rounded, Icons.add_rounded),
    _Destination(
      'Misiones',
      '/missions',
      Icons.emoji_events_outlined,
      Icons.emoji_events_rounded,
    ),
    _Destination(
      'Perfil',
      '/profile',
      Icons.person_outline_rounded,
      Icons.person_rounded,
    ),
  ];

  int get _selectedIndex {
    final index = _destinations.indexWhere(
      (item) => location.startsWith(item.path),
    );
    return index < 0 ? 0 : index;
  }

  void _navigate(BuildContext context, int index) =>
      context.go(_destinations[index].path);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = onRefresh == null
            ? child
            : MareaRefreshIndicator(onRefresh: onRefresh!, child: child);
        if (constraints.maxWidth >= 600) {
          final extended = constraints.maxWidth >= 1024;
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: extended,
                    minWidth: 80,
                    minExtendedWidth: 232,
                    groupAlignment: -0.65,
                    useIndicator: true,
                    indicatorShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    selectedLabelTextStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandNavy,
                    ),
                    unselectedLabelTextStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    selectedIconTheme: const IconThemeData(
                      size: 24,
                      color: AppColors.brandNavy,
                    ),
                    unselectedIconTheme: const IconThemeData(
                      size: 24,
                      color: AppColors.textSecondary,
                    ),
                    backgroundColor: AppColors.surface,
                    selectedIndex: _selectedIndex,
                    indicatorColor: AppColors.mist,
                    leading: Padding(
                      padding: EdgeInsets.fromLTRB(
                        14,
                        24,
                        16,
                        extended ? 36 : 24,
                      ),
                      child: extended
                          ? const MareaLogo()
                          : const _CompactMark(),
                    ),
                    onDestinationSelected: (index) => _navigate(context, index),
                    destinations: [
                      for (final destination in _destinations)
                        NavigationRailDestination(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          icon: destination.path == '/create'
                              ? const _CreateButton()
                              : Icon(destination.icon),
                          selectedIcon: destination.path == '/create'
                              ? const _CreateButton()
                              : Icon(destination.selectedIcon),
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1, color: AppColors.softBorder),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.navSurface,
                border: Border(top: BorderSide(color: AppColors.softBorder)),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                selectedItemColor: AppColors.brandNavy,
                unselectedItemColor: AppColors.textMuted,
                elevation: 0,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
                onTap: (index) => _navigate(context, index),
                items: [
                  for (var index = 0; index < _destinations.length; index++)
                    BottomNavigationBarItem(
                      icon: index == 2
                          ? const _CreateButton(key: Key('create-destination'))
                          : Icon(_destinations[index].icon),
                      activeIcon: index == 2
                          ? const _CreateButton(key: Key('create-destination'))
                          : Icon(_destinations[index].selectedIcon),
                      label: index == 2 ? 'Crear' : _destinations[index].label,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.only(top: 2),
      decoration: const BoxDecoration(
        color: AppColors.aqua,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.add_rounded,
        color: AppColors.inkOnAqua,
        size: 28,
      ),
    );
  }
}

class _CompactMark extends StatelessWidget {
  const _CompactMark();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.mist,
      child: Text(
        'M',
        style: TextStyle(
          color: AppColors.brandNavy,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.path, this.icon, this.selectedIcon);
  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
}
