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
                    minWidth: 88,
                    minExtendedWidth: 260,
                    selectedLabelTextStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandNavy,
                    ),
                    unselectedLabelTextStyle: const TextStyle(
                      fontFamily: 'NunitoSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    selectedIconTheme: const IconThemeData(
                      size: 27,
                      color: AppColors.brandNavy,
                    ),
                    unselectedIconTheme: const IconThemeData(
                      size: 27,
                      color: AppColors.textSecondary,
                    ),
                    backgroundColor: AppColors.surface,
                    selectedIndex: _selectedIndex,
                    useIndicator: true,
                    indicatorColor: AppColors.mint,
                    leading: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        32,
                        16,
                        extended ? 48 : 28,
                      ),
                      child: extended
                          ? const MareaLogo()
                          : const _CompactMark(),
                    ),
                    onDestinationSelected: (index) => _navigate(context, index),
                    destinations: [
                      for (final destination in _destinations)
                        NavigationRailDestination(
                          padding: const EdgeInsets.symmetric(vertical: 9),
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
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            height: 76,
            indicatorColor: AppColors.mint,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) => _navigate(context, index),
            destinations: [
              for (var index = 0; index < _destinations.length; index++)
                NavigationDestination(
                  icon: index == 2
                      ? const _CreateButton(key: Key('create-destination'))
                      : Icon(_destinations[index].icon),
                  selectedIcon: index == 2
                      ? const _CreateButton(key: Key('create-destination'))
                      : Icon(_destinations[index].selectedIcon),
                  label: _destinations[index].label,
                ),
            ],
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
        color: AppColors.actionBlue,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
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
