import 'dart:convert';
import 'dart:typed_data';

import 'package:xml/xml.dart';

const panoramaImportMaxBytes = 32 * 1024 * 1024;
const _gpanoNamespace = 'http://ns.google.com/photos/1.0/panorama/';
const _xmpIdentifier = 'http://ns.adobe.com/xap/1.0/\u0000';
const _exifIdentifier = 'Exif\u0000\u0000';

class PanoramaImportInfo {
  const PanoramaImportInfo({required this.width, required this.height});

  final int width, height;
}

/// Checks the original JPEG container and declared full-sphere XMP metadata.
/// Does not rewrite bytes or claim optical coverage. The worker still decodes
/// and validates the complete image before producing a usable panorama.
PanoramaImportInfo validatePanoramaImport(Uint8List bytes) {
  if (bytes.length > panoramaImportMaxBytes) {
    throw StateError(
      'La foto supera 32 MB. Exporta el panorama 360° como JPEG de menor tamaño.',
    );
  }
  if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
    throw StateError(
      'Elige el archivo JPEG original de la foto panorámica 360°.',
    );
  }

  int? width, height;
  Uint8List? xmp;
  var offset = 2, scanFound = false, endFound = false;
  while (offset < bytes.length) {
    if (bytes[offset++] != 0xff) _invalidJpeg();
    while (offset < bytes.length && bytes[offset] == 0xff) {
      offset++;
    }
    if (offset >= bytes.length) _invalidJpeg();
    final marker = bytes[offset++];
    if (marker == 0xd9) {
      endFound = true;
      break;
    }
    if (marker == 0 || marker == 0xd8) _invalidJpeg();
    if (marker == 0x01 || (marker >= 0xd0 && marker <= 0xd7)) continue;
    if (offset + 2 > bytes.length) _invalidJpeg();
    final length = (bytes[offset] << 8) | bytes[offset + 1];
    if (length < 2 || offset + length > bytes.length) _invalidJpeg();
    final data = Uint8List.sublistView(bytes, offset + 2, offset + length);
    offset += length;

    if ({0xc0, 0xc1, 0xc2}.contains(marker)) {
      if (data.length < 6) _invalidJpeg();
      final components = data[5];
      if (components < 1 ||
          components > 4 ||
          data.length != 6 + components * 3) {
        _invalidJpeg();
      }
      final frameHeight = (data[1] << 8) | data[2];
      final frameWidth = (data[3] << 8) | data[4];
      if (width != null && (width != frameWidth || height != frameHeight)) {
        _invalidJpeg();
      }
      width = frameWidth;
      height = frameHeight;
      if (width < 64 ||
          height < 64 ||
          width > 24000 ||
          height > 24000 ||
          width * height > 120000000) {
        throw StateError(
          'Las dimensiones de la foto no son compatibles. Usa un JPEG de '
          '64 a 24000 píxeles por lado y hasta 120 megapíxeles.',
        );
      }
    }
    if (marker == 0xe1) {
      if (_startsWith(data, _xmpIdentifier)) {
        if (xmp != null) _invalidMetadata();
        xmp = Uint8List.sublistView(data, _xmpIdentifier.length);
      } else if (_startsWith(data, _exifIdentifier)) {
        _checkOrientation(Uint8List.sublistView(data, _exifIdentifier.length));
      }
    }
    if (marker == 0xda) {
      if (data.isEmpty || data[0] == 0 || data.length != 4 + data[0] * 2) {
        _invalidJpeg();
      }
      scanFound = true;
      // Entropy-coded data uses FF00 stuffing and standalone restart markers.
      // Find the next actual marker without decoding or allocating pixel data.
      while (offset < bytes.length) {
        if (bytes[offset] != 0xff) {
          offset++;
          continue;
        }
        var next = offset + 1;
        while (next < bytes.length && bytes[next] == 0xff) {
          next++;
        }
        if (next >= bytes.length) _invalidJpeg();
        if (bytes[next] == 0 || (bytes[next] >= 0xd0 && bytes[next] <= 0xd7)) {
          offset = next + 1;
        } else {
          break;
        }
      }
    }
  }
  if (!scanFound || !endFound || width == null || height == null) {
    _invalidJpeg();
  }
  if (width != height * 2) {
    throw StateError(
      'Esta foto no cubre una esfera 360°. Una panorámica horizontal del celular '
      'no incluye techo y piso; usa una foto 360° completa o la captura guiada.',
    );
  }
  if (xmp == null || xmp.isEmpty) {
    throw StateError(
      'Este JPEG no incluye los datos de una foto 360° (GPano). Usa el archivo '
      'original exportado por una cámara o aplicación 360°.',
    );
  }

  final XmlDocument document;
  try {
    document = XmlDocument.parse(utf8.decode(xmp));
  } on FormatException {
    _invalidMetadata();
  }

  String value(String name) {
    final values = <String>{};
    for (final element in document.descendantElements) {
      for (final attribute in element.attributes) {
        if (attribute.namespaceUri == _gpanoNamespace &&
            attribute.localName == name) {
          values.add(attribute.value);
        }
      }
      if (element.namespaceUri == _gpanoNamespace &&
          element.localName == name) {
        if (element.childElements.isNotEmpty) _invalidMetadata();
        values.add(element.innerText);
      }
    }
    if (values.length != 1 || values.single.isEmpty) _invalidMetadata();
    return values.single;
  }

  int dimension(String name) {
    final number = int.tryParse(value(name).trim());
    if (number == null) _invalidMetadata();
    return number;
  }

  if (value('ProjectionType') != 'equirectangular') {
    throw StateError(
      'La foto no está exportada como panorama 360° equirectangular.',
    );
  }
  final fullWidth = dimension('FullPanoWidthPixels');
  final fullHeight = dimension('FullPanoHeightPixels');
  final croppedWidth = dimension('CroppedAreaImageWidthPixels');
  final croppedHeight = dimension('CroppedAreaImageHeightPixels');
  final left = dimension('CroppedAreaLeftPixels');
  final top = dimension('CroppedAreaTopPixels');
  if (left != 0 ||
      top != 0 ||
      croppedWidth != fullWidth ||
      croppedHeight != fullHeight) {
    throw StateError(
      'La foto contiene sólo una parte del panorama. Exporta la esfera 360° '
      'completa, sin recortar.',
    );
  }
  if (fullWidth != width ||
      fullHeight != height ||
      fullWidth != fullHeight * 2) {
    throw StateError(
      'Las dimensiones de la foto no coinciden con sus datos 360°. Exporta '
      'nuevamente el JPEG original conservando sus metadatos.',
    );
  }
  return PanoramaImportInfo(width: width, height: height);
}

bool _startsWith(Uint8List data, String identifier) {
  if (data.length < identifier.length) return false;
  for (var i = 0; i < identifier.length; i++) {
    if (data[i] != identifier.codeUnitAt(i)) return false;
  }
  return true;
}

void _checkOrientation(Uint8List tiff) {
  if (tiff.length < 8) _invalidJpeg();
  final endian = tiff[0] == 0x49 && tiff[1] == 0x49
      ? Endian.little
      : tiff[0] == 0x4d && tiff[1] == 0x4d
      ? Endian.big
      : null;
  if (endian == null) _invalidJpeg();
  final data = ByteData.sublistView(tiff);
  if (data.getUint16(2, endian) != 42) _invalidJpeg();
  final first = data.getUint32(4, endian);
  if (first < 8 || first + 2 > tiff.length) _invalidJpeg();
  final entries = data.getUint16(first, endian);
  if (first + 2 + entries * 12 + 4 > tiff.length) _invalidJpeg();
  for (var i = 0; i < entries; i++) {
    final offset = first + 2 + i * 12;
    if (data.getUint16(offset, endian) != 0x0112) continue;
    if (data.getUint16(offset + 2, endian) != 3 ||
        data.getUint32(offset + 4, endian) != 1) {
      _invalidJpeg();
    }
    if (data.getUint16(offset + 8, endian) != 1) {
      throw StateError(
        'La foto tiene la orientación EXIF girada. Exporta una foto con '
        'orientación normalizada conservando los datos 360°.',
      );
    }
  }
}

Never _invalidJpeg() => throw StateError(
  'No pudimos leer el JPEG completo. Elige otra vez el archivo panorámico original.',
);

Never _invalidMetadata() => throw StateError(
  'No pudimos validar los datos 360° (GPano) de esta foto. Exporta el JPEG '
  'original de una esfera completa conservando sus metadatos.',
);
