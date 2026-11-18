import 'package:marea/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_depth.dart';
import 'package:marea/features/showcase/presentation/create_screen.dart';
import 'package:marea/shared/widgets/marea_panel.dart';

/// Reserves space for Crear on pages that use their own scaffold and back bar.
class MareaCreationPage extends StatelessWidget {
  const MareaCreationPage({
    required this.controller,
    required this.child,
    super.key,
  });

  final AppSessionController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    child: child,
    builder: (context, child) {
      final mobile = MediaQuery.sizeOf(context).width < 600;
      final showCreate =
          canOpenCreateMenu(controller) &&
          (!mobile || MediaQuery.viewInsetsOf(context).bottom == 0);
      return Column(
        children: [
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: showCreate,
              child: child!,
            ),
          ),
          if (showCreate)
            Material(
              color: AppColors.profileCanvas,
              child: MareaPanelAwareDock(
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: MareaCreateAction(
                      selected: false,
                      expanded: !mobile,
                      stacked: mobile,
                      onTap: () => showCreateMenu(context, controller),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class MareaCreateAction extends StatefulWidget {
  const MareaCreateAction({
    required this.onTap,
    required this.selected,
    required this.expanded,
    required this.stacked,
    this.enabled = true,
    super.key,
  });
  final Future<void> Function() onTap;
  final bool selected, expanded, stacked, enabled;
  @override
  State<MareaCreateAction> createState() => _MareaCreateActionState();
}

class _MareaCreateActionState extends State<MareaCreateAction> {
  bool _open = false;
  Future<void> _tap() async {
    if (_open || !widget.enabled) return;
    setState(() => _open = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) setState(() => _open = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.stacked ? 22 : 28);
    return Semantics(
      label: AppLocalizations.tr('Crear'),
      button: true,
      enabled: widget.enabled,
      selected: widget.selected,
      excludeSemantics: true,
      onTap: widget.enabled ? _tap : null,
      child: Tooltip(
        message: AppLocalizations.tr('Crear'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: AppDepth.action,
          ),
          child: Material(
            key: const Key('create-destination'),
            color: widget.enabled
                ? AppColors.actionBlue
                : AppColors.textSecondary,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: widget.enabled ? _tap : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.stacked ? 6 : (widget.expanded ? 20 : 16),
                  vertical: widget.stacked ? 8 : 16,
                ),
                child: Flex(
                  direction: widget.stacked ? Axis.vertical : Axis.horizontal,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedRotation(
                      turns: _open ? 0.125 : 0,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    if (widget.stacked)
                      SizedBox(
                        width: 48,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppLocalizations.tr('Crear'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    if (widget.expanded) ...[
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.tr('Crear'),
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
}
