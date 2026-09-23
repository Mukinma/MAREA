import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';

/// A small composition of creative worlds, not a feed or interactive cards.
class CreativeArtwork extends StatelessWidget {
  const CreativeArtwork({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1.65,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final unit = constraints.maxWidth / 480;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _ConnectingLine()),
                ),
                Positioned(
                  left: 8 * unit,
                  top: 28 * unit,
                  child: _WorldTile(
                    label: 'Arte',
                    color: AppColors.lavender,
                    icon: Icons.gesture_rounded,
                    rotation: -.10,
                    unit: unit,
                  ),
                ),
                Positioned(
                  left: 170 * unit,
                  top: 76 * unit,
                  child: _WorldTile(
                    label: 'Digital',
                    color: AppColors.mint,
                    icon: Icons.code_rounded,
                    rotation: .07,
                    unit: unit,
                  ),
                ),
                Positioned(
                  right: 6 * unit,
                  top: 8 * unit,
                  child: _WorldTile(
                    label: 'Música',
                    color: AppColors.peach,
                    icon: Icons.graphic_eq_rounded,
                    rotation: .12,
                    unit: unit,
                  ),
                ),
                Positioned(
                  left: 25 * unit,
                  bottom: 4 * unit,
                  child: Transform.rotate(
                    angle: -.05,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18 * unit,
                        vertical: 10 * unit,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandNavy,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        'Mejor, juntos.',
                        style: TextStyle(
                          fontFamily: 'NunitoSans',
                          color: Colors.white,
                          fontSize: 17 * unit,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WorldTile extends StatelessWidget {
  const _WorldTile({
    required this.label,
    required this.color,
    required this.icon,
    required this.rotation,
    required this.unit,
  });

  final String label;
  final Color color;
  final IconData icon;
  final double rotation;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: 138 * unit,
        height: 172 * unit,
        padding: EdgeInsets.all(18 * unit),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24 * unit),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Icon(icon, size: 58 * unit, color: AppColors.brandNavy),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppColors.brandNavy,
                fontFamily: 'NunitoSans',
                fontSize: 18 * unit,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectingLine extends CustomPainter {
  const _ConnectingLine();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * .56)
      ..cubicTo(
        size.width * .26,
        size.height * 1.2,
        size.width * .8,
        size.height * .9,
        size.width,
        size.height * .28,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.aqua
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Decorative cover: broad, flat ribbons echo MAREA's fluid mark.
class MareaCover extends StatelessWidget {
  const MareaCover({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: ClipRect(
        child: ColoredBox(
          color: AppColors.lavender,
          child: CustomPaint(
            painter: _CoverPainter(),
            child: SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _CoverPainter extends CustomPainter {
  const _CoverPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawOval(
      Rect.fromLTWH(w * .03, -h * .85, w * .54, h * 2.0),
      Paint()..color = AppColors.peach,
    );
    final wave = Path()
      ..moveTo(w * .42, h * 1.25)
      ..cubicTo(w * .56, h * 1.12, w * .57, -h * .22, w * .74, h * .10)
      ..cubicTo(w * .88, h * .40, w * .87, h * 1.35, w * 1.10, h * .3);
    canvas.drawPath(
      wave,
      Paint()
        ..color = AppColors.aqua
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * .38
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(w * .90, h * .24),
      h * .095,
      Paint()..color = AppColors.brandNavy,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
