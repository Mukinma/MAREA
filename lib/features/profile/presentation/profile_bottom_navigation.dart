import 'package:marea/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';

/// Profile-only presentation of the existing application destinations.
class ProfileBottomNavigation extends StatelessWidget {
  const ProfileBottomNavigation({
    required this.onNavigate,
    required this.onCreate,
    super.key,
  });
  final ValueChanged<String> onNavigate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Material(
    key: const Key('profile-bottom-navigation'),
    color: Colors.white,
    child: SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE1EEF4))),
        ),
        child: Row(
          children: [
            _item('Inicio', Icons.home_outlined, '/home'),
            _item('Explorar', Icons.explore_outlined, '/explore'),
            Expanded(
              child: Center(
                heightFactor: 1,
                child: IconButton.filled(
                  tooltip: AppLocalizations.tr('Crear'),
                  onPressed: onCreate,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF08BFC1),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 27),
                ),
              ),
            ),
            _item('Mensajes', Icons.chat_bubble_outline_rounded, '/messages'),
            _item(
              'Perfil',
              Icons.person_outline_rounded,
              '/profile',
              selected: true,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _item(
    String label,
    IconData icon,
    String path, {
    bool selected = false,
  }) {
    final localizedLabel = AppLocalizations.tr(label);
    return Expanded(
    child: Tooltip(
      message: localizedLabel,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: selected,
        label: localizedLabel,
        onTap: () => onNavigate(path),
        excludeSemantics: true,
        child: InkWell(
          onTap: () => onNavigate(path),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: const Color(0xFF07345C)),
                const SizedBox(height: 3),
                Text(
                  localizedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: const Color(0xFF607C98),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? const Color(0xFF08BFC1)
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}
