import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';

class MareaLogo extends StatelessWidget {
  const MareaLogo({super.key, this.compact = false, this.showTagline = false});

  final bool compact;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 32.0 : 48.0;
    return Semantics(
      label: 'MAREA. Conecta. Crea. Crece.',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size(markSize, markSize * .6),
            painter: _MareaMark(),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MAREA',
                style: TextStyle(
                  color: AppColors.brandNavy,
                  fontSize: compact ? 19 : 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: compact ? 2.2 : 3.2,
                ),
              ),
              if (showTagline)
                const Text(
                  'Conecta. Crea. Crece.',
                  style: TextStyle(
                    color: AppColors.aquaDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MareaMark extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.aqua
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * .34
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * .1, size.height * .72)
      ..cubicTo(
        size.width * .25,
        size.height * .1,
        size.width * .38,
        size.height * .1,
        size.width * .5,
        size.height * .65,
      )
      ..cubicTo(
        size.width * .63,
        size.height * .1,
        size.width * .76,
        size.height * .1,
        size.width * .9,
        size.height * .72,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
