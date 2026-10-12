import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/tours/data/tour_progress_store.dart';
import 'package:marea/features/tours/models/tour_models.dart';

void main() {
  test(
    'local persistence failure never starts network synchronization',
    () async {
      var calls = 0;
      final store = TourProgressStore(
        account: 'a',
        tourId: 't',
        revisionId: 'v',
        read: (_, _) async => null,
        write: (_, _, _) async => throw StateError('disk full'),
        sync: (p) async {
          calls++;
          return p!;
        },
      );
      await expectLater(
        store.save(TourProgress(revisionId: 'v')),
        throwsA(isA<TourProgressPersistenceException>()),
      );
      expect(calls, 0);
    },
  );
  test(
    'offline change survives a new store and sync retries by revision',
    () async {
      final disk = <String, Map<String, dynamic>>{};
      var online = false;
      final writes = <Map<String, dynamic>>[];
      TourProgressStore create(String account, String revision) =>
          TourProgressStore(
            account: account,
            tourId: 'tour',
            revisionId: revision,
            read: (a, k) async => disk['$a/$k'],
            write: (a, k, v) async {
              disk['$a/$k'] = v;
            },
            sync: (save) async {
              if (!online) throw StateError('offline');
              if (save != null) writes.add(save.toJson());
              return save ?? TourProgress(revisionId: revision);
            },
          );
      final p = TourProgress(revisionId: 'v1')..visit('point');
      await expectLater(create('a', 'v1').save(p), throwsStateError);
      final restored = await create('a', 'v1').load();
      expect(restored.visited, {'point'});
      online = true;
      expect((await create('a', 'v1').load()).visited, {'point'});
      expect(writes.single['visited'], ['point']);
      expect((await create('b', 'v1').load()).visited, isEmpty);
      expect((await create('a', 'v2').load()).visited, isEmpty);
    },
  );
  test('snapshots are captured before queued saves run', () async {
    final writes = <Map<String, dynamic>>[];
    final store = TourProgressStore(
      account: 'a',
      tourId: 't',
      revisionId: 'v',
      read: (_, _) async => null,
      write: (_, _, v) async => writes.add(v),
      sync: (save) async => save!,
    );
    final p = TourProgress(revisionId: 'v')..visit('one');
    final first = store.save(p);
    p.visit('two');
    final second = store.save(p);
    await Future.wait([first, second]);
    expect((writes.first['progress'] as Map)['visited'], ['one']);
    expect((writes.last['progress'] as Map)['visited'], ['one', 'two']);
    await expectLater(
      store.save(TourProgress(revisionId: 'old')),
      throwsStateError,
    );
  });
}
