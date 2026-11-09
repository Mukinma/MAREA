// Synthetic JPEG pixels and projection declarations for tests only. These
// fixtures exercise file validation; they are not real panoramas or AR reports.
import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

Uint8List panoramaJpegFixture({
  int width = 256,
  int height = 128,
  bool includeXmp = true,
  Map<String, String> metadata = const {},
  String? rawXmp,
  bool useElements = false,
  String namespace = 'http://ns.google.com/photos/1.0/panorama/',
  int? orientation,
  Endian endian = Endian.little,
}) {
  var bytes = Uint8List.fromList(
    img.encodeJpg(img.Image(width: width, height: height)),
  );
  if (includeXmp) {
    final values = {
      'ProjectionType': 'equirectangular',
      'FullPanoWidthPixels': '$width',
      'FullPanoHeightPixels': '$height',
      'CroppedAreaImageWidthPixels': '$width',
      'CroppedAreaImageHeightPixels': '$height',
      'CroppedAreaLeftPixels': '0',
      'CroppedAreaTopPixels': '0',
      ...metadata,
    };
    final attributes = useElements
        ? ''
        : values.entries.map((e) => 'p:${e.key}="${e.value}"').join(' ');
    final elements = !useElements
        ? ''
        : values.entries
              .map((e) => '<p:${e.key}>${e.value}</p:${e.key}>')
              .join();
    final xml =
        rawXmp ??
        '<x:xmpmeta xmlns:x="adobe:ns:meta/">'
            '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'
            '<rdf:Description xmlns:p="$namespace" $attributes>'
            '$elements</rdf:Description></rdf:RDF></x:xmpmeta>';
    bytes = _segment(
      bytes,
      Uint8List.fromList(utf8.encode('http://ns.adobe.com/xap/1.0/\u0000$xml')),
    );
  }
  if (orientation != null) {
    final tiff = Uint8List(26);
    tiff[0] = tiff[1] = endian == Endian.little ? 0x49 : 0x4d;
    ByteData.sublistView(tiff)
      ..setUint16(2, 42, endian)
      ..setUint32(4, 8, endian)
      ..setUint16(8, 1, endian)
      ..setUint16(10, 0x0112, endian)
      ..setUint16(12, 3, endian)
      ..setUint32(14, 1, endian)
      ..setUint16(18, orientation, endian);
    bytes = _segment(
      bytes,
      Uint8List.fromList([...ascii.encode('Exif\u0000\u0000'), ...tiff]),
    );
  }
  return bytes;
}

Uint8List _segment(Uint8List jpeg, Uint8List payload) {
  final length = payload.length + 2;
  if (length > 65535) throw ArgumentError('Test APP1 packet is too large.');
  return Uint8List.fromList([
    ...jpeg.take(2),
    0xff,
    0xe1,
    length >> 8,
    length & 0xff,
    ...payload,
    ...jpeg.skip(2),
  ]);
}
