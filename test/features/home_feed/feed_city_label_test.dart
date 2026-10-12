import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/location/data/location_repository.dart';
import 'package:marea/features/location/models/location_models.dart';
import 'package:marea/features/home_feed/presentation/feed_city_label.dart';

class Cities implements LocationRepository {
  final pending = <String, Completer<LocationCity?>>{};
  @override
  Future<LocationCity?> resolveContentCity({
    required String contentKind,
    required String contentId,
    required PostCoordinates coordinates,
  }) => pending.putIfAbsent(contentId, Completer<LocationCity?>.new).future;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  testWidgets(
    'city lookup is nonblocking and discards a previous content response',
    (tester) async {
      final repo = Cities();
      const point = PostCoordinates(
        latitude: 19.119762,
        longitude: -104.405987,
        precision: PostLocationPrecision.exact,
      );
      Widget label(String id) => MaterialApp(
        home: Scaffold(
          body: FeedCityLabel(
            contentKind: 'mission',
            contentId: id,
            coordinates: point,
            repository: repo,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpWidget(label('old'));
      expect(find.text('Ver ubicación'), findsOneWidget);
      await tester.pumpWidget(label('new'));
      repo.pending['old']!.complete(
        const LocationCity(name: 'Ciudad anterior'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ciudad anterior'), findsNothing);
      repo.pending['new']!.complete(const LocationCity(name: 'Manzanillo'));
      await tester.pumpAndSettle();
      expect(find.text('Manzanillo'), findsOneWidget);
      expect(find.textContaining('104.405'), findsNothing);
    },
  );
}
