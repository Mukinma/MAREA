import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../models/ar_marker.dart';

abstract interface class MarkerRepository {
  Future<List<ArMarker>> listOwned(String ownerId);
  Future<List<ArMarker>> nearbyPublic({double? latitude, double? longitude});
  Future<ArMarker?> get(String ownerId, String id);
  Future<ArMarker> save(
    String ownerId,
    Map<String, dynamic> values, {
    Uint8List? imageBytes,
  });
  Future<void> delete(String ownerId, String id);
  Future<Uint8List> loadImage(String ownerId, ArMarker marker);
  Future<ArMarker> confirmRecognition(
    String ownerId,
    String id,
    String referenceVersion,
    String platform,
    int seconds,
  );
}

const markerImageMaxBytes = 8 * 1024 * 1024;
final markerUuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

void validateMarkerId(String id) {
  final match = markerUuidPattern.firstMatch(id);
  if (match == null || match.end != id.length) {
    throw ArgumentError('Identificador de marcador inválido.');
  }
}

Map<String, dynamic> markerEditableValues(Map<String, dynamic> values) {
  final name = (values['name'] as String? ?? '').trim();
  final description = (values['description'] as String? ?? '').trim();
  if (name.isEmpty || name.length > 120) {
    throw StateError('Escribe un nombre de 1 a 120 caracteres.');
  }
  if (description.length > 4000) {
    throw StateError('La descripción admite hasta 4000 caracteres.');
  }
  final width = values['width_cm'];
  if (width is! num || !width.isFinite || width < 1 || width > 1000) {
    throw StateError('Escribe un ancho entre 1 y 1000 centímetros.');
  }
  final rawUrl = values['menu_url'];
  final menuUrl = rawUrl is String ? rawUrl.trim() : null;
  if (menuUrl != null && menuUrl.isNotEmpty) {
    final uri = Uri.tryParse(menuUrl);
    if (menuUrl.length > 2048 ||
        uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw StateError('El enlace debe ser una dirección http o https válida.');
    }
  }
  final latitude = values['latitude'], longitude = values['longitude'];
  bool coordinate(dynamic value, double low, double high) =>
      value is num && value.isFinite && value >= low && value <= high;
  if ((latitude == null) != (longitude == null) ||
      (latitude != null &&
          (!coordinate(latitude, -90, 90) ||
              !coordinate(longitude, -180, 180)))) {
    throw StateError('Selecciona una ubicación válida.');
  }
  final accuracy = values['location_accuracy'];
  if (accuracy != null &&
      (accuracy is! num || !accuracy.isFinite || accuracy < 0)) {
    throw StateError('La precisión de ubicación no es válida.');
  }
  final exact = values['location_exact'] == true;
  if (exact && latitude == null) {
    throw StateError('La ubicación exacta necesita coordenadas.');
  }
  return {
    'name': name,
    'description': description,
    'menu_url': menuUrl == null || menuUrl.isEmpty ? null : menuUrl,
    'width_cm': width.toDouble(),
    'latitude': (latitude as num?)?.toDouble(),
    'longitude': (longitude as num?)?.toDouble(),
    'location_exact': exact,
    'location_accuracy': (accuracy as num?)?.toDouble(),
  };
}

void validateMarkerRecognition(String platform, int seconds) {
  if (!{'android', 'ios'}.contains(platform) || seconds < 3 || seconds > 3600) {
    throw StateError(
      'Reconoce la imagen con la cámara durante al menos 3 segundos.',
    );
  }
}

void validateMarkerImage(Uint8List bytes) {
  if (bytes.isEmpty ||
      bytes.length > markerImageMaxBytes ||
      bytes.length < 4 ||
      bytes[0] != 0xff ||
      bytes[1] != 0xd8) {
    throw StateError('Elige una imagen JPEG de hasta 8 MB.');
  }
  try {
    final decoder = img.JpegDecoder();
    final info = decoder.startDecode(bytes);
    if (info == null ||
        info.width < 32 ||
        info.height < 32 ||
        info.width > 4096 ||
        info.height > 4096 ||
        info.width * info.height > 16000000) {
      throw StateError(
        'La imagen debe medir entre 32 y 4096 píxeles por lado y hasta 16 megapíxeles.',
      );
    }
    final image = decoder.decodeFrame(0);
    if (image == null || (image.exif.imageIfd.orientation ?? 1) != 1) {
      throw StateError('Guarda la imagen JPEG con orientación normalizada.');
    }
  } on StateError {
    rethrow;
  } catch (_) {
    throw StateError('No pudimos leer la imagen JPEG completa.');
  }
}
