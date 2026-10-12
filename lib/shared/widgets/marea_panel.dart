import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';

/// Counts sheets through their exit animation, including nested sheets.
final mareaOpenPanels = ValueNotifier<int>(0);

Future<T?> showMareaBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  bool showDragHandle = true,
  Color? backgroundColor,
  Color? barrierColor,
  BoxConstraints? constraints,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final localizations = MaterialLocalizations.of(context);
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  var released = false;
  void release() {
    if (released) return;
    released = true;
    mareaOpenPanels.value--;
  }

  final route = _MareaBottomSheetRoute<T>(
    onDisposed: release,
    builder: builder,
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: navigator.context,
    ),
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    showDragHandle: showDragHandle,
    constraints: constraints,
    backgroundColor: backgroundColor ?? AppColors.surface,
    modalBarrierColor:
        barrierColor ?? AppColors.brandNavy.withValues(alpha: .3),
    barrierLabel: localizations.scrimLabel,
    barrierOnTapHint: localizations.scrimOnTapHint(
      localizations.bottomSheetLabel,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: reducedMotion
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 220),
            reverseDuration: Duration(milliseconds: 180),
          ),
  );
  mareaOpenPanels.value++;
  try {
    final result = await navigator.push(route);
    await route.completed;
    return result;
  } finally {
    release();
  }
}

// Navigator disposal may not complete push's result future. Release in dispose
// as well as after a normal pop, keeping sheets counted through exit animation.
class _MareaBottomSheetRoute<T> extends ModalBottomSheetRoute<T> {
  _MareaBottomSheetRoute({
    required this.onDisposed,
    required super.builder,
    required super.isScrollControlled,
    super.capturedThemes,
    super.useSafeArea,
    super.showDragHandle,
    super.constraints,
    super.backgroundColor,
    super.modalBarrierColor,
    super.barrierLabel,
    super.barrierOnTapHint,
    super.shape,
    super.clipBehavior,
    super.sheetAnimationStyle,
  });
  final VoidCallback onDisposed;
  @override
  void dispose() {
    onDisposed();
    super.dispose();
  }
}

/// Hides the dock while preserving its layout and the feed's scroll position.
class MareaPanelAwareDock extends StatelessWidget {
  const MareaPanelAwareDock({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: mareaOpenPanels,
    builder: (context, count, child) => IgnorePointer(
      ignoring: count > 0,
      child: ExcludeSemantics(
        excluding: count > 0,
        child: AnimatedOpacity(
          opacity: count > 0 ? 0 : 1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          child: child,
        ),
      ),
    ),
    child: child,
  );
}
