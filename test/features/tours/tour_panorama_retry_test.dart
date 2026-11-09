import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/tours/data/tour_repository.dart';
import 'package:marea/features/tours/models/tour_models.dart';
import 'package:marea/features/tours/presentation/tour_panorama.dart';

class PanoramaUrls implements TourRepository {
  int calls = 0;
  final pending = Completer<String>();

  @override
  Future<String> assetUrl(String path) {
    calls++;
    return calls == 1
        ? Future<String>.error(StateError('Sin conexión'))
        : pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'a failed panorama URL can retry without returning a Future from setState',
    (tester) async {
      final urls = PanoramaUrls();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TourPanorama(
              repository: urls,
              scene: TourScene({'id': 'scene', 'preview_path': 'preview.jpg'}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(urls.calls, 1);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(urls.calls, 2);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
