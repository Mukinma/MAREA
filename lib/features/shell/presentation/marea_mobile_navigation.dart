import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/shared/widgets/marea_panel.dart';

enum MobileDestination {
  home('Inicio', '/home', Icons.home_outlined, Icons.home_rounded),
  discover(
    'Descubrir',
    '/discover',
    Icons.search_outlined,
    Icons.search_rounded,
  ),
  map('Mapa', '/map', Icons.map_outlined, Icons.map_rounded),
  profile(
    'Perfil',
    '/profile',
    Icons.person_outline_rounded,
    Icons.person_rounded,
  );

  const MobileDestination(this.label, this.path, this.icon, this.activeIcon);
  final String label, path;
  final IconData icon, activeIcon;

  static MobileDestination? forLocation(String location) {
    final path = Uri.parse(location).path;
    if (path == '/explore' || path == '/missions') return discover;
    for (final destination in values) {
      if (path == destination.path) return destination;
    }
    return null;
  }
}

/// Route-controlled selection with a local, continuously draggable preview.
class MareaMobileNavigation extends StatefulWidget {
  const MareaMobileNavigation({
    required this.selectedDestination,
    required this.location,
    required this.onSelected,
    this.navigationChanges,
    super.key,
  });

  final MobileDestination? selectedDestination;
  // A route can change without changing its highlighted destination.
  final String location;
  final ValueChanged<MobileDestination> onSelected;
  // Includes root pages pushed above the shell, whose shell location stays put.
  final Listenable? navigationChanges;

  @override
  State<MareaMobileNavigation> createState() => _MareaMobileNavigationState();
}

class _MareaMobileNavigationState extends State<MareaMobileNavigation>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _snapDuration = Duration(milliseconds: 225);
  late final AnimationController _snap;
  double? _position;
  MobileDestination? _preview;
  double _from = 0, _to = 0;
  Size? _geometry;
  double _cellWidth = 0;
  int _generation = 0;
  int? _pointer;
  double? _downX;
  double _downPosition = 0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _position = widget.selectedDestination?.index.toDouble();
    _preview = widget.selectedDestination;
    _snap = AnimationController(vsync: this, duration: _snapDuration)
      ..addListener(() {
        setState(() {
          final t = Curves.easeOutCubic.transform(_snap.value);
          _position = _from + (_to - _from) * t;
        });
      });
    WidgetsBinding.instance.addObserver(this);
    mareaOpenPanels.addListener(_panelsChanged);
    widget.navigationChanges?.addListener(_navigationChanged);
  }

  void _interrupt() {
    _generation++;
    _snap.stop(canceled: true);
    _pointer = null;
    _downX = null;
    _dragging = false;
  }

  // Also used during layout/update: those callers already schedule a build.
  void _restoreRoute() {
    _interrupt();
    _position = widget.selectedDestination?.index.toDouble();
    _preview = widget.selectedDestination;
  }

  void _navigationChanged() => setState(_restoreRoute);

  void _panelsChanged() {
    if (mareaOpenPanels.value > 0) setState(_restoreRoute);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Root Navigator pushes (stories/dialogs) do not notify GoRouter.
    if (ModalRoute.isCurrentOf(context) == false) _restoreRoute();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) setState(_restoreRoute);
  }

  @override
  void didUpdateWidget(MareaMobileNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationChanges != widget.navigationChanges) {
      oldWidget.navigationChanges?.removeListener(_navigationChanged);
      widget.navigationChanges?.addListener(_navigationChanged);
    }
    if (oldWidget.location != widget.location ||
        oldWidget.selectedDestination != widget.selectedDestination) {
      _restoreRoute();
    }
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    mareaOpenPanels.removeListener(_panelsChanged);
    widget.navigationChanges?.removeListener(_navigationChanged);
    _snap.dispose();
    super.dispose();
  }

  Future<void> _settle(
    MobileDestination destination, {
    required bool confirm,
  }) async {
    _interrupt();
    final generation = _generation;
    _from = _position ?? destination.index.toDouble();
    _to = destination.index.toDouble();
    setState(() {
      _position = _from;
      _preview = destination;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _position = _to);
    } else {
      try {
        await _snap.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted || generation != _generation || mareaOpenPanels.value > 0) {
      return;
    }
    if (confirm && ModalRoute.isCurrentOf(context) != false) {
      widget.onSelected(destination);
    }
  }

  void _tap(MobileDestination destination) {
    if (mareaOpenPanels.value > 0) return;
    _settle(destination, confirm: widget.location != destination.path);
  }

  void _down(PointerDownEvent event) {
    // The first pointer owns the interaction until it ends.
    if (_pointer != null || mareaOpenPanels.value > 0) return;
    _interrupt();
    _pointer = event.pointer;
    final position = _position;
    if (position == null) return;
    final center = (position + .5) * _cellWidth;
    if ((event.localPosition.dx - center).abs() <= (_cellWidth - 4) / 2) {
      _downX = event.localPosition.dx;
      _downPosition = position;
    }
  }

  void _dragStart(DragStartDetails details) {
    if (_downX == null) return;
    _dragging = true;
    _dragUpdate(details.localPosition.dx);
  }

  void _dragUpdate(double x) {
    if (!_dragging || _downX == null) return;
    final next = (_downPosition + (x - _downX!) / _cellWidth).clamp(0.0, 3.0);
    final preview = MobileDestination.values[next.round()];
    if (_preview != preview) HapticFeedback.selectionClick();
    setState(() {
      _position = next;
      _preview = preview;
    });
  }

  void _dragEnd(DragEndDetails details) {
    if (!_dragging) {
      _returnToRoute();
      return;
    }
    final destination = MobileDestination.values[_position!.round()];
    _settle(destination, confirm: destination != widget.selectedDestination);
  }

  void _dragCancel() {
    if (_dragging || _downX != null || _pointer != null) _returnToRoute();
  }

  void _returnToRoute() {
    if (widget.selectedDestination != null) {
      _settle(widget.selectedDestination!, confirm: false);
    } else {
      setState(_restoreRoute);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cellWidth = math.max(0.0, constraints.maxWidth - 12) / 4;
      final scaler = MediaQuery.textScalerOf(context);
      const labelStyle = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.15,
      );
      var labelHeight = 0.0;
      for (final destination in MobileDestination.values) {
        final painter = TextPainter(
          text: TextSpan(
            text: destination.label,
            style: labelStyle.copyWith(
              fontFamily: Theme.of(context).textTheme.labelSmall?.fontFamily,
            ),
          ),
          textDirection: Directionality.of(context),
          textScaler: scaler,
        )..layout(maxWidth: math.max(1, cellWidth - 8));
        labelHeight = math.max(labelHeight, painter.height);
        painter.dispose();
      }
      final height = math.max(76.0, 12 + 16 + 24 + 4 + labelHeight);
      final geometry = Size(constraints.maxWidth, height);
      if (_geometry != null && _geometry != geometry) _restoreRoute();
      _geometry = geometry;
      _cellWidth = cellWidth;
      final reduced = MediaQuery.disableAnimationsOf(context);
      return SizedBox(
        key: const Key('mobile-dock'),
        height: height,
        width: constraints.maxWidth,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Listener(
              onPointerDown: _down,
              onPointerUp: (event) {
                if (!_dragging && event.pointer == _pointer) _pointer = null;
              },
              onPointerCancel: (event) {
                if (event.pointer == _pointer) _dragCancel();
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onHorizontalDragStart: _dragStart,
                onHorizontalDragUpdate: (details) =>
                    _dragUpdate(details.localPosition.dx),
                onHorizontalDragEnd: _dragEnd,
                onHorizontalDragCancel: _dragCancel,
                child: Stack(
                  children: [
                    if (_position != null)
                      Positioned(
                        left: (_position! * cellWidth) + 2,
                        top: 0,
                        bottom: 0,
                        width: math.max(0, cellWidth - 4),
                        child: IgnorePointer(
                          child: DecoratedBox(
                            key: const Key('mobile-selection-indicator'),
                            decoration: BoxDecoration(
                              color: AppColors.navigationAqua,
                              borderRadius: BorderRadius.circular(height / 2),
                            ),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        for (final destination in MobileDestination.values)
                          Expanded(
                            child: Semantics(
                              key: ValueKey('mobile-tab-${destination.name}'),
                              label: destination.label,
                              button: true,
                              selected:
                                  widget.selectedDestination == destination,
                              excludeSemantics: true,
                              onTap: () => _tap(destination),
                              child: Tooltip(
                                message: destination.label,
                                child: TextButton(
                                  onPressed: () => _tap(destination),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 8,
                                    ),
                                    minimumSize: const Size(48, 48),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: const StadiumBorder(),
                                    // The moving indicator supplies the selected surface.
                                    backgroundColor: Colors.transparent,
                                  ),
                                  child: AnimatedDefaultTextStyle(
                                    duration: reduced
                                        ? Duration.zero
                                        : const Duration(milliseconds: 100),
                                    style: labelStyle.copyWith(
                                      fontFamily: Theme.of(
                                        context,
                                      ).textTheme.labelSmall?.fontFamily,
                                      color: _preview == destination
                                          ? AppColors.brandNavy
                                          : AppColors.textSecondary,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          TweenAnimationBuilder<Color?>(
                                            tween: ColorTween(
                                              end: _preview == destination
                                                  ? AppColors.brandNavy
                                                  : AppColors.textSecondary,
                                            ),
                                            duration: reduced
                                                ? Duration.zero
                                                : const Duration(
                                                    milliseconds: 100,
                                                  ),
                                            builder: (_, color, _) => Icon(
                                              _preview == destination
                                                  ? destination.activeIcon
                                                  : destination.icon,
                                              size: 24,
                                              color: color,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            height: labelHeight,
                                            child: Center(
                                              child: Text(
                                                destination.label,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
