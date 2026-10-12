import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/tours/models/tour_models.dart';
import 'package:marea/features/tours/presentation/tour_ar_screen.dart';
import 'tour_editor_recovery_test.dart';

class ARRepo extends EditorialRepo {
  ARRepo() {
    data['document'] = {
      'zones': [
        {
          'id': 'z',
          'name': 'Mural',
          'scenes': [
            {
              'id': 's',
              'name': 'Mural',
              'points': [
                for (final id in ['one', 'two'])
                  {
                    'id': id,
                    'name': 'Parada $id',
                    'description': 'Lectura sin cámara',
                    'ar': {
                      'reference_path': 'ref-$id',
                      'width_cm': 20,
                      'reference_version': 'v-$id',
                      'tested_version': 'v-$id',
                    },
                  },
              ],
            },
          ],
        },
      ],
      'ar_order': ['one', 'two'],
    };
  }
  TourProgress? saved;
  @override
  Future<TourProgress> progress(
    String t,
    String v, {
    TourProgress? save,
  }) async {
    if (save != null) saved = save;
    return saved ?? TourProgress(revisionId: v);
  }

  @override
  Future<String> assetUrl(String p) async => 'https://example.invalid/$p';
}

class ARFiles extends MemoryDrafts {
  @override
  Future<String> saveBytes(String a, String id, Uint8List b) async =>
      'local.jpg';
}

void main() {
  testWidgets(
    'camera-free list completes a stop and advances with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = ARRepo(), controller = await session(repo);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2),
            ),
            child: TourARScreen(
              controller: controller,
              tourId: 'tour',
              localStore: ARFiles(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Leer detalle de la parada'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Leer detalle de la parada'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continuar recorrido'));
      await tester.tap(find.text('Continuar recorrido'));
      await tester.pumpAndSettle();
      expect(repo.saved?.visited, {'one'});
      await tester.scrollUntilVisible(
        find.text('Parada two'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Parada two'), findsWidgets);
      expect(tester.takeException(), isNull);
      controller.dispose();
    },
  );

  const channel = MethodChannel('marea/tour_ar');
  setUp(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => true),
  );
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  testWidgets('changing stop cancels a held reference download', (
    tester,
  ) async {
    final repo = ARRepo(),
        controller = await session(repo),
        download = Completer<Uint8List>();
    await tester.pumpWidget(
      MaterialApp(
        home: TourARScreen(
          controller: controller,
          tourId: 'tour',
          localStore: ARFiles(),
          referenceLoader: (_) => download.future,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escanear esta imagen'));
    await tester.pump();
    await tester.ensureVisible(find.text('Parada two'));
    await tester.tap(find.text('Parada two'));
    await tester.pump();
    download.complete(Uint8List.fromList([1, 2, 3]));
    await tester.pumpAndSettle();
    expect(find.byType(AndroidView), findsNothing);
    expect(find.text('Parada two'), findsWidgets);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
  testWidgets('backgrounding cancels download before a camera view exists', (
    tester,
  ) async {
    final repo = ARRepo(),
        controller = await session(repo),
        download = Completer<Uint8List>();
    await tester.pumpWidget(
      MaterialApp(
        home: TourARScreen(
          controller: controller,
          tourId: 'tour',
          localStore: ARFiles(),
          referenceLoader: (_) => download.future,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escanear esta imagen'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    download.complete(Uint8List.fromList([1]));
    await tester.pumpAndSettle();
    expect(find.byType(AndroidView), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byType(AndroidView), findsNothing);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
