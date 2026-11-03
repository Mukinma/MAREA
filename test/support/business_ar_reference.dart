// Deterministic QA artwork shared by the manual camera harness and print export.
// This is an image target, not a marker detector or simulated AR recognition.
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as image;

const businessARReferenceWidthCm = 20;
const businessARReferenceVersion = 'local-artwork-v1';

Uint8List businessARReferencePng() {
  final canvas = image.Image(width: 1200, height: 900);
  image.fill(canvas, color: image.ColorRgb8(247, 242, 228));
  final random = Random(174039);
  // Unique shapes at several scales give image tracking asymmetric features.
  // Suitability and optical recognition still require a physical-device test.
  for (var i = 0; i < 1450; i++) {
    final x = random.nextInt(1170), y = random.nextInt(870);
    final size = 4 + random.nextInt(i < 350 ? 65 : 20);
    final shade = 15 + random.nextInt(190);
    final color = image.ColorRgb8(shade, (shade * 1.1).toInt(), 230 - shade);
    if (i.isEven) {
      image.fillCircle(canvas, x: x, y: y, radius: size ~/ 2, color: color);
    } else {
      image.fillRect(
        canvas,
        x1: x,
        y1: y,
        x2: x + size,
        y2: y + size ~/ 2,
        color: color,
      );
    }
  }
  image.fillRect(
    canvas,
    x1: 55,
    y1: 50,
    x2: 690,
    y2: 125,
    color: image.ColorRgb8(250, 248, 238),
  );
  image.drawString(
    canvas,
    'MAREA / LAB RA 01',
    font: image.arial48,
    x: 75,
    y: 61,
    color: image.ColorRgb8(12, 32, 68),
  );
  image.fillRect(
    canvas,
    x1: 480,
    y1: 790,
    x2: 1140,
    y2: 860,
    color: image.ColorRgb8(12, 32, 68),
  );
  image.drawString(
    canvas,
    'SOLO PRUEBAS / 20 cm',
    font: image.arial24,
    x: 510,
    y: 812,
    color: image.ColorRgb8(255, 255, 255),
  );
  return Uint8List.fromList(image.encodePng(canvas));
}

Uint8List businessARLocalTilePng() {
  final canvas = image.Image(width: 256, height: 256);
  image.fill(canvas, color: image.ColorRgb8(231, 242, 242));
  for (var n = 0; n < 256; n += 64) {
    image.drawLine(
      canvas,
      x1: n,
      y1: 0,
      x2: n,
      y2: 255,
      color: image.ColorRgb8(200, 221, 224),
    );
    image.drawLine(
      canvas,
      x1: 0,
      y1: n,
      x2: 255,
      y2: n,
      color: image.ColorRgb8(200, 221, 224),
    );
  }
  image.drawString(
    canvas,
    'MAPA LOCAL QA',
    font: image.arial14,
    x: 60,
    y: 115,
    color: image.ColorRgb8(32, 64, 86),
  );
  return Uint8List.fromList(image.encodePng(canvas));
}
