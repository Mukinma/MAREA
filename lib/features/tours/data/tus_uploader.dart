import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Credentials are read for every request. Checkpoints contain no tokens.
class TourTusUploader {
  TourTusUploader({
    required this.endpoint,
    required this.headers,
    http.Client? client,
  }) : _client = client ?? http.Client();
  final Uri endpoint;
  final Map<String, String> Function() headers;
  final http.Client _client;
  Uri _trusted(String value) {
    final u = endpoint.resolve(value);
    if (u.origin != endpoint.origin ||
        !u.path.startsWith('${endpoint.path}/') ||
        u.hasFragment ||
        u.userInfo.isNotEmpty) {
      throw StateError('Dirección de carga inválida');
    }
    return u;
  }

  Map<String, String> get _headers => {...headers(), 'Tus-Resumable': '1.0.0'};
  Future<void> upload({
    required Uint8List bytes,
    required String bucket,
    required String path,
    Map<String, dynamic>? checkpoint,
    required Future<void> Function(Map<String, dynamic>) save,
    required bool Function() isCurrent,
    void Function(double)? progress,
  }) async {
    void check() {
      if (!isCurrent()) {
        throw StateError('La sesión cambió; la carga se ha detenido.');
      }
    }

    check();
    Uri url;
    var offset = 0;
    if (checkpoint?['url'] case final String value) {
      url = _trusted(value);
      final head = await _client.head(url, headers: _headers);
      check();
      if (head.statusCode == 404 || head.statusCode == 410) {
        return upload(
          bytes: bytes,
          bucket: bucket,
          path: path,
          save: save,
          isCurrent: isCurrent,
          progress: progress,
        );
      }
      if (head.statusCode != 200 && head.statusCode != 204) {
        throw StateError('No pudimos retomar la subida (${head.statusCode}).');
      }
      offset = int.parse(head.headers['upload-offset'] ?? '-1');
    } else {
      String metadata(String k, String v) =>
          '$k ${base64.encode(utf8.encode(v))}';
      final created = await _client.post(
        endpoint,
        headers: {
          ..._headers,
          'Upload-Length': '${bytes.length}',
          'Upload-Metadata': [
            metadata('bucketName', bucket),
            metadata('objectName', path),
            metadata('contentType', 'image/jpeg'),
            metadata('cacheControl', '3600'),
          ].join(','),
        },
      );
      check();
      if (created.statusCode != 201 || created.headers['location'] == null) {
        throw StateError(
          'No pudimos iniciar la subida (${created.statusCode}).',
        );
      }
      url = _trusted(created.headers['location']!);
      await save({'url': url.toString(), 'offset': 0});
    }
    if (offset < 0 || offset > bytes.length) {
      throw StateError('El servidor devolvió un avance inválido.');
    }
    while (offset < bytes.length) {
      check();
      final end = (offset + 6 * 1024 * 1024).clamp(0, bytes.length);
      final patched = await _client.patch(
        url,
        headers: {
          ..._headers,
          'Content-Type': 'application/offset+octet-stream',
          'Upload-Offset': '$offset',
        },
        body: Uint8List.sublistView(bytes, offset, end),
      );
      check();
      if (patched.statusCode != 204) {
        throw StateError(
          'Subida interrumpida (${patched.statusCode}). Puedes reintentar.',
        );
      }
      final confirmed = int.tryParse(patched.headers['upload-offset'] ?? '');
      if (confirmed != end) {
        throw StateError('El servidor no confirmó la fotografía completa.');
      }
      offset = confirmed!;
      await save({'url': url.toString(), 'offset': offset});
      progress?.call(offset / bytes.length);
    }
  }

  void dispose() => _client.close();
}
