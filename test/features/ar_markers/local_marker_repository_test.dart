import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:marea/features/ar_markers/data/local_marker_repository.dart';
import 'package:marea/features/ar_markers/data/marker_repository.dart';
import 'package:marea/features/tours/data/tour_local_store.dart';

class MarkerStore extends TourLocalStore {
  final records = <String, Map<String, dynamic>>{};
  String? failKey;
  Completer<void>? pauseRead;
  int writes = 0;
  Map<String, dynamic> copy(Map<String, dynamic> value) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
  @override
  Future<Map<String, dynamic>?> read(String account, String key) async {
    await pauseRead?.future;
    final row = records['$account/$key'];
    return row == null ? null : copy(row);
  }

  @override
  Future<void> write(
    String account,
    String key,
    Map<String, dynamic> data,
  ) async {
    if (key == failKey) throw StateError('Disco no disponible');
    records['$account/$key'] = copy(data);
    writes++;
  }

  @override
  Future<void> removeAccount(String account) =>
      throw StateError('No se debe borrar la cuenta.');
  @override
  Future<String> saveBytes(String account, String id, Uint8List bytes) =>
      throw StateError('Imagen y datos deben ir en un registro atómico.');
}

Uint8List markerJpeg([int red = 80]) {
  final image = img.Image(width: 64, height: 64);
  img.fill(image, color: img.ColorRgb8(red, 60, 120));
  return Uint8List.fromList(img.encodeJpg(image));
}

Map<String, dynamic> markerValues([String name = 'Menú del taller']) => {
  'name': name,
  'description': 'Información pública',
  'width_cm': 20,
  'menu_url': 'https://example.org/menu',
  'latitude': 19.5,
  'longitude': -99.2,
  'location_exact': true,
  'location_accuracy': 5,
};

void main() {
  test(
    'an explicit local alert opt-in saves with a precise location in one operation',
    () async {
      final repo = LocalMarkerRepository(localStore: MarkerStore());
      var marker = await repo.save('owner', {
        ...markerValues(),
        'latitude': null,
        'longitude': null,
        'location_exact': false,
        'location_accuracy': null,
      }, imageBytes: markerJpeg());
      marker = await repo.confirmRecognition(
        'owner',
        marker.id,
        marker.referenceVersion,
        'android',
        3,
      );
      marker = await repo.save('owner', {
        'id': marker.id,
        'latitude': 19.5,
        'longitude': -99.2,
        'location_exact': true,
        'location_accuracy': 5,
        'active': true,
      });
      expect(marker.active, isTrue);
      expect(marker.isTested, isTrue);
      // Moving an already active marker never silently carries over its opt-in.
      marker = await repo.save('owner', {'id': marker.id, 'latitude': 19.6});
      expect(marker.active, isFalse);
      await expectLater(
        repo.save('owner', {
          'id': marker.id,
          'location_accuracy': 35,
          'active': true,
        }),
        throwsStateError,
      );
      final stored = (await repo.get('owner', marker.id))!;
      expect(stored.active, isFalse);
      expect(stored.locationAccuracy, 5);
    },
  );

  test(
    'metadata and original JPEG persist atomically across repository instances and accounts',
    () async {
      final store = MarkerStore();
      final first = LocalMarkerRepository(localStore: store);
      final bytes = markerJpeg();
      final saved = await first.save(
        'owner-a',
        markerValues(),
        imageBytes: bytes,
      );
      expect(saved.isLocal, isTrue);
      expect(saved.active, isFalse);
      expect(saved.isTested, isFalse);
      expect(saved.data.containsKey('image_base64'), isFalse);
      final reopened = LocalMarkerRepository(localStore: store);
      expect((await reopened.listOwned('owner-a')).single.id, saved.id);
      expect(await reopened.loadImage('owner-a', saved), bytes);
      expect(await reopened.listOwned('owner-b'), isEmpty);
      expect(await reopened.get('owner-b', saved.id), isNull);
      expect(() => reopened.loadImage('owner-b', saved), throwsStateError);
      final row = store.records['owner-a/ar-marker-${saved.id}']!;
      expect(row['name'], saved.name);
      expect(base64Decode(row['image_base64'] as String), bytes);
    },
  );

  test(
    'text keeps recognition while width and image changes invalidate it',
    () async {
      final repo = LocalMarkerRepository(localStore: MarkerStore());
      var marker = await repo.save(
        'owner',
        markerValues(),
        imageBytes: markerJpeg(),
      );
      marker = await repo.confirmRecognition(
        'owner',
        marker.id,
        marker.referenceVersion,
        'android',
        3,
      );
      marker = await repo.save('owner', {'id': marker.id, 'active': true});
      expect(marker.active, isTrue);
      final version = marker.referenceVersion;
      marker = await repo.save('owner', {
        'id': marker.id,
        'description': 'Texto corregido',
      });
      expect(marker.referenceVersion, version);
      expect(marker.isTested, isTrue);
      expect(marker.active, isTrue);
      marker = await repo.save('owner', {'id': marker.id, 'width_cm': 21});
      expect(marker.referenceVersion, isNot(version));
      expect(marker.isTested, isFalse);
      expect(marker.active, isFalse);
      final measuredVersion = marker.referenceVersion;
      marker = await repo.save('owner', {
        'id': marker.id,
      }, imageBytes: markerJpeg(120));
      expect(marker.referenceVersion, isNot(measuredVersion));
      expect(marker.isTested, isFalse);
    },
  );

  test('stale recognition cannot validate a replacement image', () async {
    final repo = LocalMarkerRepository(localStore: MarkerStore());
    final old = await repo.save(
      'owner',
      markerValues(),
      imageBytes: markerJpeg(),
    );
    final replacing = repo.save('owner', {
      'id': old.id,
    }, imageBytes: markerJpeg(100));
    final confirming = repo.confirmRecognition(
      'owner',
      old.id,
      old.referenceVersion,
      'ios',
      3,
    );
    await expectLater(confirming, throwsStateError);
    final current = await replacing;
    expect((await repo.get('owner', current.id))!.isTested, isFalse);
    await expectLater(repo.loadImage('owner', old), throwsStateError);
  });

  test(
    'delete scrubs image and metadata without deleting other markers or accounts',
    () async {
      final store = MarkerStore(),
          repo = LocalMarkerRepository(localStore: MarkerStore());
      final actual = LocalMarkerRepository(localStore: store);
      final deleted = await actual.save(
        'owner',
        markerValues(),
        imageBytes: markerJpeg(),
      );
      final retained = await actual.save(
        'owner',
        markerValues('Otro'),
        imageBytes: markerJpeg(),
      );
      await actual.delete('owner', deleted.id);
      expect(await actual.get('owner', deleted.id), isNull);
      expect((await actual.listOwned('owner')).single.id, retained.id);
      expect(store.records['owner/ar-marker-${deleted.id}'], {
        'id': deleted.id,
        'owner_id': 'owner',
        'deleted': true,
        'image_base64': null,
      });
      await expectLater(actual.loadImage('owner', deleted), throwsStateError);
      expect(await repo.listOwned('other'), isEmpty);
    },
  );

  test(
    'simultaneous writes through separate instances keep both index entries',
    () async {
      final store = MarkerStore();
      final first = LocalMarkerRepository(localStore: store),
          second = LocalMarkerRepository(localStore: store);
      final saved = await Future.wait([
        first.save('owner', markerValues('Uno'), imageBytes: markerJpeg()),
        second.save('owner', markerValues('Dos'), imageBytes: markerJpeg()),
      ]);
      expect(
        (await first.listOwned('owner')).map((m) => m.id).toSet(),
        saved.map((m) => m.id).toSet(),
      );
    },
  );

  test(
    'failed record write preserves the old metadata and JPEG together',
    () async {
      final store = MarkerStore(), bytes = markerJpeg();
      final repo = LocalMarkerRepository(localStore: store);
      final old = await repo.save('owner', markerValues(), imageBytes: bytes);
      store.failKey = 'ar-marker-${old.id}';
      await expectLater(
        repo.save('owner', {
          'id': old.id,
          'name': 'Cambio',
        }, imageBytes: markerJpeg(140)),
        throwsStateError,
      );
      final current = (await repo.get('owner', old.id))!;
      expect(current.name, old.name);
      expect(current.referenceVersion, old.referenceVersion);
      expect(await repo.loadImage('owner', current), bytes);
    },
  );

  test(
    'changing accounts while a read is pending prevents a later write',
    () async {
      final store = MarkerStore()..pauseRead = Completer<void>();
      var account = 'owner';
      final repo = LocalMarkerRepository(
        localStore: store,
        currentOwner: () => account,
      );
      final saving = repo.save(
        'owner',
        markerValues(),
        imageBytes: markerJpeg(),
      );
      final failure = expectLater(saving, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      account = 'other';
      store.pauseRead!.complete();
      await failure;
      expect(store.writes, 0);
    },
  );

  test(
    'recognition and local alerts require real current reference and exact location',
    () async {
      final repo = LocalMarkerRepository(localStore: MarkerStore());
      final marker = await repo.save(
        'owner',
        markerValues()..['location_exact'] = false,
        imageBytes: markerJpeg(),
      );
      for (final platform in ['web', 'android']) {
        await expectLater(
          repo.confirmRecognition(
            'owner',
            marker.id,
            marker.referenceVersion,
            platform,
            2,
          ),
          throwsStateError,
        );
      }
      await expectLater(
        repo.confirmRecognition(
          'owner',
          marker.id,
          marker.referenceVersion,
          'web',
          4,
        ),
        throwsStateError,
      );
      final tested = await repo.confirmRecognition(
        'owner',
        marker.id,
        marker.referenceVersion,
        'android',
        3,
      );
      await expectLater(
        repo.save('owner', {'id': tested.id, 'active': true}),
        throwsStateError,
      );
      expect(
        await repo.nearbyPublic(latitude: 19.5, longitude: -99.2),
        isEmpty,
      );
    },
  );

  test(
    'bad dimensions, links, coordinates and oversized images never persist',
    () async {
      final store = MarkerStore(),
          repo = LocalMarkerRepository(localStore: MarkerStore());
      final actual = LocalMarkerRepository(localStore: store);
      for (final patch in [
        {'name': ''},
        {'width_cm': .5},
        {'width_cm': double.nan},
        {'menu_url': 'javascript:alert(1)'},
        {'latitude': double.infinity},
        {'latitude': 91},
        {'longitude': null},
        {'location_accuracy': double.nan},
      ]) {
        await expectLater(
          actual.save('owner', {
            ...markerValues(),
            ...patch,
          }, imageBytes: markerJpeg()),
          throwsStateError,
        );
      }
      await expectLater(
        actual.save(
          'owner',
          markerValues(),
          imageBytes: Uint8List(markerImageMaxBytes + 1),
        ),
        throwsStateError,
      );
      await expectLater(
        actual.save(
          'owner',
          markerValues(),
          imageBytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]),
        ),
        throwsStateError,
      );
      expect(store.writes, 0);
      expect(await repo.listOwned('unrelated'), isEmpty);
    },
  );
}
