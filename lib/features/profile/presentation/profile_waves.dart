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
    // The profile reference uses a 390 × 164 viewBox.
    canvas.scale(size.width / 390, size.height / 164);
    final back = Path()
      ..moveTo(0, 9.10629)
      ..cubicTo(58, -15.3661, 92, 13.185, 124, 50.9134)
      ..cubicTo(169, 112.094, 203, 90.6811, 252, 82.5236)
      ..cubicTo(314, 73.3465, 340, 75.3858, 390, 97.8189)
      ..lineTo(390, 159)
      ..lineTo(0, 159)
      ..close();
    final middle = Path()
      ..moveTo(0, 13.2966)
      ..cubicTo(58, 3.24778, 61, 54.4969, 117, 67.5604)
      ..cubicTo(173, 72.5848, 184, 99.7167, 215, 101.726)
      ..cubicTo(263, 111.775, 280, 54.4969, 334, 97.7069)
      ..cubicTo(355, 119.814, 373, 125.844, 390, 129.863)
      ..lineTo(390, 158)
      ..lineTo(0, 158)
      ..close();
    final front = Path()
      ..moveTo(0, 45)
      ..cubicTo(47, 64, 64, 89, 118, 88)
      ..cubicTo(189, 81, 202, 117, 251, 134)
      ..cubicTo(305, 154, 353, 137, 390, 152)
      ..lineTo(390, 164)
      ..lineTo(0, 164)
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
