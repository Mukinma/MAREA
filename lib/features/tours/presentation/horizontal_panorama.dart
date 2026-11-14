import 'dart:math' as math;
import 'package:flutter/material.dart';

const horizontalPanoramaNotice =
    'Panorámica horizontal: desliza de izquierda a derecha. '
    'Esta imagen no incluye techo y piso.';

/// Shows the original image as a strip, with no invented spherical projection,
/// sensor angles, repeated seam, or pixels outside the photographed area.
class HorizontalPanorama extends StatefulWidget {
  const HorizontalPanorama({
    required this.image,
    required this.aspectRatio,
    super.key,
  });

  final ImageProvider image;
  final double aspectRatio;

  @override
  State<HorizontalPanorama> createState() => _HorizontalPanoramaState();
}

class _HorizontalPanoramaState extends State<HorizontalPanorama> {
  final _scroll = ScrollController();
  bool _centered = false;

  @override
  void didUpdateWidget(HorizontalPanorama oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) _centered = false;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!_centered) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _centered || !_scroll.hasClients) return;
          _scroll.jumpTo(_scroll.position.maxScrollExtent / 2);
          _centered = true;
        });
      }
      final height = constraints.maxHeight;
      final width = math.max(constraints.maxWidth, height * widget.aspectRatio);
      return ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              key: const ValueKey('horizontal-panorama-scroll'),
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                height: height,
                child: Image(
                  image: widget.image,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const Center(
                    child: Text('No pudimos abrir la panorámica.'),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: .92),
                  padding: const EdgeInsets.all(10),
                  child: const Text(horizontalPanoramaNotice),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
