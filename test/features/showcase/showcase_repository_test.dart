import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marea/features/showcase/data/showcase_repository.dart';
import 'package:marea/features/showcase/models/showcase.dart';

void main() {
  Map<String, dynamic> row() => {
    'id': 'fiche',
    'owner_id': 'owner',
    'kind': 'service',
    'title': 'Diseño local',
    'body': 'Descripción',
    'category': 'arte',
    'status': 'published',
    'available': true,
    'hidden': false,
    'price': 150,
    'created_at': '2026-09-27T00:00:00Z',
    'showcase_images': [
      {'position': 1, 'path': 'second'},
      {'position': 0, 'path': 'first'},
    ],
  };
  SupabaseShowcaseRepository repository(
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = SupabaseClient(
      'https://example.invalid',
      'key',
      httpClient: MockClient((request) async {
        final response = await handler(request);
        return http.Response(
          response.body,
          response.statusCode,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    return SupabaseShowcaseRepository(client);
  }

  test(
    'discovery filters visibility before pagination and orders images',
    () async {
      final repo = repository((request) async {
        expect(request.url.path, '/rest/v1/showcase_items');
        expect(request.url.queryParameters['status'], 'eq.published');
        expect(request.url.queryParameters['available'], 'eq.true');
        expect(request.url.queryParameters['hidden'], 'eq.false');
        expect(request.url.queryParameters['owner_id'], 'eq.owner');
        expect(request.url.queryParameters['kind'], 'eq.service');
        expect(request.url.queryParameters['category'], 'eq.arte');
        expect(request.url.queryParameters['title'], 'ilike.%Diseño%');
        expect(request.url.queryParameters['offset'], '30');
        expect(request.url.queryParameters['limit'], '30');
        return http.Response(jsonEncode([row()]), 200);
      });
      final items = await repo.items(
        ownerId: 'owner',
        kind: ShowcaseKind.service,
        category: 'arte',
        query: ' Diseño ',
        offset: 30,
      );
      expect(items.single.imagePaths, ['first', 'second']);
      expect(items.single.price, 150);
    },
  );
  test(
    'save sends a single atomic RPC with explicit editable fields',
    () async {
      final repo = repository((request) async {
        expect(request.url.path, '/rest/v1/rpc/save_showcase');
        final payload = jsonDecode(request.body) as Map;
        expect(payload['item_id'], isNull);
        expect(payload['item_input'], {
          'kind': 'service',
          'title': 'Servicio local',
          'body': 'Descripción',
          'category': 'arte',
          'status': 'published',
          'available': true,
          'price': null,
          'project_url': null,
          'image_paths': [],
        });
        return http.Response('"new-id"', 200);
      });
      expect(
        await repo.save(
          const ShowcaseInput(
            kind: ShowcaseKind.service,
            title: ' Servicio local ',
            body: ' Descripción ',
            category: 'arte',
            status: ShowcaseStatus.published,
          ),
        ),
        'new-id',
      );
    },
  );
  test('edit removes replaced photos only after a persisted save', () async {
    final paths = <String>[];
    final repo = repository((request) async {
      paths.add(request.url.path);
      if (request.url.path == '/rest/v1/showcase_items') {
        return http.Response(jsonEncode(row()), 200);
      }
      if (request.url.path == '/rest/v1/rpc/save_showcase') {
        return http.Response('"fiche"', 200);
      }
      return http.Response('[{"name":"first"}]', 200);
    });
    await repo.save(
      const ShowcaseInput(
        kind: ShowcaseKind.service,
        title: 'Servicio local',
        body: 'Descripción',
        category: 'arte',
        status: ShowcaseStatus.published,
        imagePaths: ['second'],
      ),
      id: 'fiche',
    );
    expect(paths, [
      '/rest/v1/showcase_items',
      '/rest/v1/rpc/save_showcase',
      '/storage/v1/object/showcase-media',
    ]);
  });
  test(
    'failed atomic save never deletes previously referenced media',
    () async {
      final paths = <String>[];
      final repo = repository((request) async {
        paths.add(request.url.path);
        return request.url.path == '/rest/v1/showcase_items'
            ? http.Response(jsonEncode(row()), 200)
            : http.Response(
                '{"message":"showcase_owner_required","code":"P0001"}',
                400,
              );
      });
      await expectLater(
        repo.save(
          const ShowcaseInput(
            kind: ShowcaseKind.service,
            title: 'Servicio local',
            body: 'Descripción',
            category: 'arte',
          ),
          id: 'fiche',
        ),
        throwsA(isA<Exception>()),
      );
      expect(paths, ['/rest/v1/showcase_items', '/rest/v1/rpc/save_showcase']);
    },
  );
}
