import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_depth.dart';

/// Tactile chrome that retains Material ink, keyboard focus and semantics.
class MareaSurface extends StatelessWidget {
  const MareaSurface({
    required this.child,
    this.color = AppColors.paper,
    this.radius = 24,
    this.padding = EdgeInsets.zero,
    this.inset = false,
    this.floating = false,
    this.clipBehavior = Clip.none,
    super.key,
  });
  final Widget child;
  final Color color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool inset, floating;
  final Clip clipBehavior;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: inset
          ? null
          : floating
          ? AppDepth.floating
          : AppDepth.raised,
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: clipBehavior,
      child: CustomPaint(
        foregroundPainter: inset ? _InsetRelief(radius) : null,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class MareaCard extends StatelessWidget {
  const MareaCard({
    required this.child,
    this.color = AppColors.surface,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.clipBehavior = Clip.none,
    super.key,
  });
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry margin;
  final Clip clipBehavior;
  @override
  Widget build(BuildContext context) => Padding(
    padding: margin,
    child: MareaSurface(
      color: color ?? AppColors.surface,
      clipBehavior: clipBehavior,
      child: child,
    ),
  );
}

class _InsetRelief extends CustomPainter {
  const _InsetRelief(this.radius);
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(bounds, Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(shape);
    for (final (offset, color) in [
      (const Offset(3, 3), const Color(0x260B255E)),
      (const Offset(-3, -3), const Color(0xE6FFFFFF)),
    ]) {
      final ring = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(bounds.inflate(20))
        ..addRRect(shape.shift(offset));
      canvas.drawPath(
        ring,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InsetRelief oldDelegate) => oldDelegate.radius != radius;
}
