import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:marea/features/tours/capture/panorama_import.dart';

import '../../support/panorama_fixture.dart';

Matcher rejects(String message) => throwsA(
  isA<StateError>().having(
    (error) => error.message,
    'message',
    contains(message),
  ),
);

void main() {
  test(
    'accepts original full-sphere JPEG with real XMP namespace unchanged',
    () {
      final bytes = panoramaJpegFixture();
      final original = [...bytes];
      final info = validatePanoramaImport(bytes);
      expect((info.width, info.height), (256, 128));
      expect(bytes, original);
    },
  );

  test('accepts namespace-qualified XMP elements as well as attributes', () {
    final info = validatePanoramaImport(panoramaJpegFixture(useElements: true));
    expect((info.width, info.height), (256, 128));
  });

  test('size guard runs before format or image decoding', () {
    expect(
      () => validatePanoramaImport(Uint8List(panoramaImportMaxBytes + 1)),
      rejects('32 MB'),
    );
  });

  test('PNG and unreadable JPEG are rejected before upload', () {
    final png = Uint8List.fromList(
      img.encodePng(img.Image(width: 256, height: 128)),
    );
    expect(() => validatePanoramaImport(png), rejects('JPEG original'));
    final truncated = panoramaJpegFixture();
    expect(
      () => validatePanoramaImport(
        Uint8List.sublistView(truncated, 0, truncated.length - 2),
      ),
      rejects('JPEG completo'),
    );
  });

  test('horizontal phone panorama explains missing spherical coverage', () {
    expect(
      () =>
          validatePanoramaImport(panoramaJpegFixture(width: 384, height: 128)),
      rejects('panorámica horizontal del celular'),
    );
  });

  test('2:1 shape and GPano text outside APP1 are not projection evidence', () {
    final plain = panoramaJpegFixture(includeXmp: false);
    expect(
      () => validatePanoramaImport(plain),
      rejects('no incluye los datos'),
    );
    final trailing = Uint8List.fromList([
      ...plain,
      ...utf8.encode(
        '<GPano:ProjectionType>equirectangular</GPano:ProjectionType>',
      ),
    ]);
    expect(
      () => validatePanoramaImport(trailing),
      rejects('no incluye los datos'),
    );
  });

  test('malformed metadata and spoofed namespace are rejected', () {
    expect(
      () => validatePanoramaImport(panoramaJpegFixture(rawXmp: '<broken>')),
      rejects('GPano'),
    );
    expect(
      () => validatePanoramaImport(
        panoramaJpegFixture(namespace: 'https://example.invalid/fake-gpano'),
      ),
      rejects('GPano'),
    );
  });

  test('cylindrical projection cannot be treated as a complete sphere', () {
    expect(
      () => validatePanoramaImport(
        panoramaJpegFixture(metadata: {'ProjectionType': 'cylindrical'}),
      ),
      rejects('equirectangular'),
    );
  });

  test('cropped area and nonzero crop offsets require complete export', () {
    for (final metadata in [
      {'FullPanoWidthPixels': '512', 'FullPanoHeightPixels': '256'},
      {'CroppedAreaImageWidthPixels': '255'},
      {'CroppedAreaLeftPixels': '1'},
      {'CroppedAreaTopPixels': '-1'},
    ]) {
      expect(
        () => validatePanoramaImport(panoramaJpegFixture(metadata: metadata)),
        rejects('sin recortar'),
      );
    }
  });

  test('metadata dimensions must equal the original JPEG frame', () {
    expect(
      () => validatePanoramaImport(
        panoramaJpegFixture(
          metadata: {
            'FullPanoWidthPixels': '512',
            'FullPanoHeightPixels': '256',
            'CroppedAreaImageWidthPixels': '512',
            'CroppedAreaImageHeightPixels': '256',
          },
        ),
      ),
      rejects('dimensiones'),
    );
    expect(
      () => validatePanoramaImport(
        panoramaJpegFixture(metadata: {'FullPanoWidthPixels': '256.0'}),
      ),
      rejects('GPano'),
    );
  });

  test('image dimensions are bounded from header before allocating pixels', () {
    for (final (width, height) in [(62, 31), (25000, 12500), (20000, 10000)]) {
      final bytes = panoramaJpegFixture();
      final frame = _frameOffset(bytes);
      ByteData.sublistView(bytes)
        ..setUint16(frame + 5, height, Endian.big)
        ..setUint16(frame + 7, width, Endian.big);
      expect(() => validatePanoramaImport(bytes), rejects('dimensiones'));
    }
  });

  test('EXIF orientation must be normalized in both TIFF byte orders', () {
    for (final endian in [Endian.little, Endian.big]) {
      expect(
        validatePanoramaImport(
          panoramaJpegFixture(orientation: 1, endian: endian),
        ).width,
        256,
      );
      expect(
        () => validatePanoramaImport(
          panoramaJpegFixture(orientation: 6, endian: endian),
        ),
        rejects('orientación EXIF'),
      );
    }
  });
}

int _frameOffset(Uint8List bytes) {
  var offset = 2;
  while (offset + 4 < bytes.length) {
    final marker = bytes[offset + 1];
    if ({0xc0, 0xc1, 0xc2}.contains(marker)) return offset;
    final length = (bytes[offset + 2] << 8) | bytes[offset + 3];
    offset += length + 2;
  }
  throw StateError('Test JPEG has no frame header.');
}
