import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marea/features/ar_markers/data/supabase_marker_repository.dart';
import 'package:marea/features/ar_markers/models/ar_marker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_marker_repository_test.dart' show markerJpeg, markerValues;

const owner = '11111111-1111-4111-8111-111111111111';
const markerId = '22222222-2222-4222-8222-222222222222';
const version = '33333333-3333-4333-8333-333333333333';
const nextVersion = '44444444-4444-4444-8444-444444444444';

Map<String, dynamic> cloudRow() => {
  ...markerValues(),
  'id': markerId,
  'owner_id': owner,
  'reference_version': version,
  'tested_version': null,
  'reference_path': '$owner/$markerId/$version.jpg',
  'active': false,
  'review_status': 'pending',
};
http.Response response(Object? value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json'},
);
SupabaseClient client(Future<http.Response> Function(http.Request) handler) =>
    SupabaseClient(
      'https://markers.example.invalid',
      'test-anon-key',
      httpClient: MockClient((request) async {
        final result = await handler(request);
        return http.Response.bytes(
          result.bodyBytes,
          result.statusCode,
          headers: result.headers,
          request: request,
        );
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

void main() {
  test(
    'cloud text edits use owner and reference-version predicates without sending protected fields',
    () async {
      final requests = <http.Request>[];
      final api = client((request) async {
        requests.add(request);
        if (request.method == 'GET') return response(cloudRow());
        final payload = jsonDecode(request.body) as Map;
        for (final protected in [
          'active',
          'review_status',
          'tested_version',
          'reference_version',
          'owner_id',
          'storage',
        ]) {
          expect(payload.containsKey(protected), isFalse);
        }
        expect(request.url.queryParameters['owner_id'], 'eq.$owner');
        expect(request.url.queryParameters['reference_version'], 'eq.$version');
        expect(payload['description'], 'Texto nuevo');
        return response({...cloudRow(), 'description': 'Texto nuevo'});
      });
      addTearDown(api.dispose);
      final repository = SupabaseMarkerRepository(
        api,
        currentOwner: () => owner,
      );
      final marker = await repository.save(owner, {
        'id': markerId,
        'description': 'Texto nuevo',
        'active': true,
        'review_status': 'approved',
        'tested_version': version,
      });
      expect(marker.description, 'Texto nuevo');
      expect(marker.active, isFalse);
      expect(marker.isTested, isFalse);
      expect(marker.isLocal, isFalse);
      expect(requests.map((r) => r.method), ['GET', 'PATCH']);
    },
  );

  test(
    'new cloud image uses a private immutable object then inserts a pending record',
    () async {
      String? uploadedPath;
      final api = client((request) async {
        if (request.url.path.startsWith('/storage/v1/object/')) {
          expect(request.method, 'POST');
          expect(
            request.url.path.contains('/ar-marker-images/$owner/'),
            isTrue,
          );
          expect(request.headers['x-upsert'], 'false');
          // Supabase uploads a multipart body; validate the file part, not the
          // generated boundary and cache-control fields.
          expect(
            request.headers['content-type'],
            startsWith('multipart/form-data'),
          );
          final bytes = request.bodyBytes;
          final jpeg = markerJpeg();
          var found = false;
          for (var i = 0; i <= bytes.length - jpeg.length; i++) {
            if (bytes[i] != 255 || bytes[i + 1] != 216) continue;
            found = true;
            for (var j = 0; j < jpeg.length; j++) {
              if (bytes[i + j] != jpeg[j]) {
                found = false;
                break;
              }
            }
            if (found) break;
          }
          expect(found, isTrue);
          uploadedPath = request.url.path.split('/ar-marker-images/').last;
          return response({'Key': 'ar-marker-images/$uploadedPath'});
        }
        expect(request.method, 'POST');
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['owner_id'], owner);
        expect(payload['reference_path'], uploadedPath);
        expect(payload.containsKey('tested_version'), isFalse);
        expect(payload.containsKey('active'), isFalse);
        return response({
          ...payload,
          'reference_version': version,
          'active': false,
          'review_status': 'pending',
        });
      });
      addTearDown(api.dispose);
      final repository = SupabaseMarkerRepository(
        api,
        currentOwner: () => owner,
      );
      final marker = await repository.save(
        owner,
        markerValues(),
        imageBytes: markerJpeg(),
      );
      expect(marker.active, isFalse);
      expect(marker.isTested, isFalse);
      expect(marker.referencePath, uploadedPath);
    },
  );

  test(
    'native recognition calls the guarded RPC and never sends activation',
    () async {
      var calls = 0;
      final api = client((request) async {
        calls++;
        expect(request.url.path, '/rest/v1/rpc/ar_markers_confirm_recognition');
        expect(jsonDecode(request.body), {
          'p_id': markerId,
          'p_reference_version': version,
          'p_platform': 'android',
          'p_seconds': 3,
        });
        return response({...cloudRow(), 'tested_version': version});
      });
      addTearDown(api.dispose);
      final repository = SupabaseMarkerRepository(
        api,
        currentOwner: () => owner,
      );
      await expectLater(
        repository.confirmRecognition(owner, markerId, version, 'web', 3),
        throwsStateError,
      );
      expect(calls, 0);
      final tested = await repository.confirmRecognition(
        owner,
        markerId,
        version,
        'android',
        3,
      );
      expect(tested.isTested, isTrue);
      expect(tested.active, isFalse);
      expect(calls, 1);
    },
  );

  test(
    'image replacement during download cannot return an obsolete reference',
    () async {
      var reads = 0;
      final api = client((request) async {
        if (request.url.path.startsWith('/storage/')) {
          return http.Response.bytes(markerJpeg(), 200);
        }
        reads++;
        return response({
          ...cloudRow(),
          if (reads > 1) 'reference_version': nextVersion,
        });
      });
      addTearDown(api.dispose);
      final repository = SupabaseMarkerRepository(
        api,
        currentOwner: () => owner,
      );
      await expectLater(
        repository.loadImage(owner, ArMarker(cloudRow())),
        throwsStateError,
      );
      expect(reads, 2);
    },
  );

  test(
    'account mismatch prevents network writes and public lookup stays filtered',
    () async {
      var requests = 0;
      final api = client((request) async {
        requests++;
        expect(request.method, 'GET');
        expect(request.url.queryParameters['active'], 'eq.true');
        expect(request.url.queryParameters['review_status'], 'eq.approved');
        return response([]);
      });
      addTearDown(api.dispose);
      final repository = SupabaseMarkerRepository(
        api,
        currentOwner: () => 'another-owner',
      );
      await expectLater(
        repository.save(owner, markerValues(), imageBytes: markerJpeg()),
        throwsStateError,
      );
      expect(requests, 0);
      expect(
        await repository.nearbyPublic(latitude: 19.5, longitude: -99.2),
        isEmpty,
      );
      expect(requests, 1);
    },
  );
}
