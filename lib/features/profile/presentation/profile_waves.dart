import 'package:flutter/material.dart';

/// Normalized paths keep the silhouette identical for every palette and size.
class ProfileWaves extends StatelessWidget {
  const ProfileWaves({
    this.colors = defaultColors,
    this.surface = const Color(0xFFF4FBFE),
    super.key,
  });

  static const defaultColors = [0xFF29B6C8, 0xFFA9E9E5];
  final List<int> colors;
  final Color surface;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: ProfileWavesPainter(colors: colors, surface: surface),
      size: Size.infinite,
    ),
  );
}

class ProfileWavesPainter extends CustomPainter {
  const ProfileWavesPainter({required this.colors, required this.surface});
  final List<int> colors;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width, size.height);
    final back = Path()
      ..moveTo(0, .12)
      ..cubicTo(.18, -.16, .27, .78, .55, .64)
      ..cubicTo(.72, .56, .78, .35, 1, .68)
      ..lineTo(1, 1)
      ..lineTo(0, 1)
      ..close();
    final middle = Path()
      ..moveTo(0, .28)
      ..cubicTo(.20, -.02, .34, .90, .61, .72)
      ..cubicTo(.82, .38, .91, .58, 1, .78)
      ..lineTo(1, 1)
      ..lineTo(0, 1)
      ..close();
    final front = Path()
      ..moveTo(0, .40)
      ..cubicTo(.19, .55, .22, .48, .37, .57)
      ..cubicTo(.55, .65, .56, .99, .83, .95)
      ..cubicTo(.92, .94, .96, .97, 1, 1)
      ..lineTo(0, 1)
      ..close();
    canvas.drawPath(back, Paint()..color = Color(colors[0]));
    canvas.drawPath(middle, Paint()..color = Color(colors[1]));
    canvas.drawPath(front, Paint()..color = surface);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ProfileWavesPainter oldDelegate) =>
      oldDelegate.colors[0] != colors[0] ||
      oldDelegate.colors[1] != colors[1] ||
      oldDelegate.surface != surface;
}

const wavePalettes = <String, List<int>>{
  'Turquesa y verde agua': [0xFF29B6C8, 0xFFA9E9E5],
  'Rosa pastel y lila': [0xFFF2B8DC, 0xFFDDB9E8],
  'Rojo oscuro y vino': [0xFFA3000B, 0xFF680016],
  'Azul cielo y azul marino': [0xFF85D3F2, 0xFF163B70],
  'Morado y lavanda': [0xFF8656B8, 0xFFD4BEED],
  'Verde menta y esmeralda': [0xFFA6E9CF, 0xFF159977],
  'Naranja y amarillo': [0xFFFF9238, 0xFFFFD75E],
  'Coral y durazno': [0xFFF98279, 0xFFFFC6A8],
  'Beige y café': [0xFFE5D3B5, 0xFF89634B],
  'Gris y negro': [0xFF9BA3AB, 0xFF20242A],
  'Fucsia y rosa': [0xFFE72A96, 0xFFFFADD5],
  'Azul petróleo y turquesa': [0xFF125C6B, 0xFF36C7CE],
  'Verde oliva y beige': [0xFF7C8749, 0xFFE9DCC0],
  'Azul pastel y blanco': [0xFFAFD9F4, 0xFFFFFFFF],
  'Rosa palo y crema': [0xFFD5A1AC, 0xFFFFF0D8],
  'Morado oscuro y fucsia': [0xFF4B216C, 0xFFE13BA6],
  'Negro y dorado': [0xFF202020, 0xFFD5AE50],
  'Verde bosque y menta': [0xFF215D46, 0xFFABE8CC],
  'Terracota y arena': [0xFFBD7056, 0xFFE9CFA7],
  'Amarillo pastel y naranja': [0xFFFFE89A, 0xFFFFA04C],
};
