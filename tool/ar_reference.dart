// Pure Dart export; shares exact pixel data with test/manual/business_ar_probe.
// dart run tool/ar_reference.dart
import 'dart:io';

import '../test/support/business_ar_reference.dart';

Future<void> main() async {
  final directory = Directory('outputs/ar-local');
  await directory.create(recursive: true);
  await File(
    '${directory.path}/reference.png',
  ).writeAsBytes(businessARReferencePng());
  await File('${directory.path}/print.html').writeAsString('''<!doctype html>
<meta charset="utf-8"><title>MAREA · referencia QA local</title>
<style>@page{size:A4;margin:5mm}body{font-family:Arial}img{width:20cm;height:15cm}
@media print{button{display:none}}</style>
<h1>MAREA · laboratorio RA local</h1>
<p>Imprime al 100%, sin ajustar a página. La imagen completa debe medir 20 × 15 cm.
Comprueba el ancho con una regla. Esta lámina no acredita reconocimiento físico.</p>
<img src="reference.png" alt="Referencia LAB RA 01 de QA">
<p>Recorta por el borde exacto de la imagen. Mantén la lámina plana y sin reflejos.</p>
<button onclick="window.print()">Imprimir</button>
''');
  stdout.writeln('Referencia: ${directory.absolute.path}\\reference.png');
  stdout.writeln(
    'Imprimir: ${directory.absolute.path}\\print.html (20 × 15 cm)',
  );
}
