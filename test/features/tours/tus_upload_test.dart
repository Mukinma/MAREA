import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marea/features/tours/data/tus_uploader.dart';

void main() {
  test(
    'reanuda en offset confirmado y no repite los bytes recibidos',
    () async {
      final calls = <http.Request>[];
      final uploader = TourTusUploader(
        endpoint: Uri.parse(
          'https://test.supabase.co/storage/v1/upload/resumable',
        ),
        headers: () => {'Authorization': 'Bearer token'},
        client: MockClient((r) async {
          calls.add(r);
          if (r.method == 'HEAD') {
            return http.Response('', 200, headers: {'upload-offset': '3'});
          }
          expect(r.headers['upload-offset'], '3');
          expect(r.bodyBytes, [4, 5, 6]);
          return http.Response('', 204, headers: {'upload-offset': '6'});
        }),
      );
      Map<String, dynamic>? saved;
      await uploader.upload(
        bytes: Uint8List.fromList([1, 2, 3, 4, 5, 6]),
        bucket: 'tour-inputs',
        path: 'owner/capture/frame.jpg',
        checkpoint: {
          'url': 'https://test.supabase.co/storage/v1/upload/resumable/id',
        },
        save: (v) async {
          saved = v;
        },
        isCurrent: () => true,
      );
      expect(calls.map((c) => c.method), ['HEAD', 'PATCH']);
      expect(saved!['offset'], 6);
    },
  );
  test('rechaza una URL de carga ajena antes de enviar credenciales', () async {
    var calls = 0;
    final uploader = TourTusUploader(
      endpoint: Uri.parse(
        'https://test.supabase.co/storage/v1/upload/resumable',
      ),
      headers: () => {},
      client: MockClient((r) async {
        calls++;
        return http.Response('', 200);
      }),
    );
    await expectLater(
      uploader.upload(
        bytes: Uint8List(1),
        bucket: 'tour-inputs',
        path: 'x.jpg',
        checkpoint: {'url': 'https://evil.example/upload'},
        save: (v) async {},
        isCurrent: () => true,
      ),
      throwsStateError,
    );
    expect(calls, 0);
  });
  test(
    'persiste URL antes del primer PATCH y respeta cambio de cuenta',
    () async {
      var active = true;
      var patches = 0;
      final uploader = TourTusUploader(
        endpoint: Uri.parse(
          'https://test.supabase.co/storage/v1/upload/resumable',
        ),
        headers: () => {},
        client: MockClient((r) async {
          if (r.method == 'POST') {
            expect(
              utf8.decode(
                base64.decode(
                  r.headers['upload-metadata']!.split(',').first.split(' ')[1],
                ),
              ),
              'tour-inputs',
            );
            return http.Response(
              '',
              201,
              headers: {'location': '/storage/v1/upload/resumable/new'},
            );
          }
          patches++;
          return http.Response('', 204);
        }),
      );
      await expectLater(
        uploader.upload(
          bytes: Uint8List(1),
          bucket: 'tour-inputs',
          path: 'x.jpg',
          save: (v) async {
            active = false;
          },
          isCurrent: () => active,
        ),
        throwsStateError,
      );
      expect(patches, 0);
    },
  );
}
