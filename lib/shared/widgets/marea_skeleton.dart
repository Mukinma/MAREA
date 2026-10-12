import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';

enum SkeletonKind { list, post, profile, detail, form, image }

/// A single accessible loading state, with decorative placeholders beneath it.
class MareaSkeleton extends StatefulWidget {
  const MareaSkeleton({
    this.kind = SkeletonKind.list,
    this.compact = false,
    super.key,
  });
  final SkeletonKind kind;
  final bool compact;
  @override
  State<MareaSkeleton> createState() => _MareaSkeletonState();
}

class _MareaSkeletonState extends State<MareaSkeleton>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _animation.stop();
    } else if (!_animation.isAnimating) {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  Widget _block(double width, double height, {double radius = 10}) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.border,
      borderRadius: BorderRadius.circular(radius),
    ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando contenido',
    container: true,
    liveRegion: true,
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, bounds) {
          final width = math.min(
            bounds.hasBoundedWidth ? bounds.maxWidth : 340.0,
            680.0,
          );
          final short =
              widget.compact ||
              width < 90 ||
              (bounds.hasBoundedHeight && bounds.maxHeight < 80);
          Widget content;
          if (short || widget.kind == SkeletonKind.image) {
            content = _block(
              width,
              bounds.hasBoundedHeight ? bounds.maxHeight : 16,
            );
          } else {
            final available = bounds.hasBoundedHeight
                ? bounds.maxHeight
                : 360.0;
            final big = widget.kind != SkeletonKind.list && available >= 250;
            final rows = big ? 2 : ((available - 24) / 66).floor().clamp(1, 4);
            content = SizedBox(
              width: width,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (big) ...[
                      if (widget.kind == SkeletonKind.profile)
                        _block(64, 64, radius: 32)
                      else
                        _block(
                          double.infinity,
                          widget.kind == SkeletonKind.form ? 40 : 96,
                          radius: 18,
                        ),
                      const SizedBox(height: 16),
                    ],
                    for (var i = 0; i < rows; i++) ...[
                      Row(
                        children: [
                          if (widget.kind == SkeletonKind.list ||
                              widget.kind == SkeletonKind.post) ...[
                            _block(40, 40, radius: 20),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _block(double.infinity, 14),
                                const SizedBox(height: 8),
                                FractionallySizedBox(
                                  widthFactor: .65,
                                  child: _block(double.infinity, 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (i < rows - 1) const SizedBox(height: 26),
                    ],
                  ],
                ),
              ),
            );
          }
          return RepaintBoundary(
            child: AnimatedBuilder(
              animation: _animation,
              child: content,
              builder: (context, child) => ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment(-3 + _animation.value * 6, 0),
                  end: Alignment(-1 + _animation.value * 6, 0),
                  colors: [AppColors.border, AppColors.paper, AppColors.border],
                ).createShader(rect),
                child: child,
              ),
            ),
          );
        },
      ),
    ),
  );
}
