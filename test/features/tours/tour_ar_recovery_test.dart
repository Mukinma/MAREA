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

class ReportARRepo extends ARRepo {
  ReportARRepo() {
    data = clone(data);
    for (final point in TourRecord(data).document.points) {
      point.ar!['tested_version'] = null;
    }
  }
  int reports = 0;
  void Function(Map<String, dynamic>)? mutateResponse;

  @override
  Future<TourRecord> reportAR(
    String tour,
    String point,
    String version,
    String platform,
    int seconds,
  ) async {
    reports++;
    expect(tour, 'tour');
    expect(point, 'one');
    expect(version, 'v-one');
    expect(platform, 'android');
    expect(seconds, greaterThanOrEqualTo(3));
    final result = clone(data);
    TourRecord(result).document.point(point)!.ar!['tested_version'] = version;
    mutateResponse?.call(result);
    return TourRecord(result);
  }
}

Future<void> prepareRecognitionReport(
  WidgetTester tester,
  ReportARRepo repo,
) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  final controller = await session(repo);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: TourARScreen(
        controller: controller,
        tourId: 'tour',
        preview: true,
        localStore: ARFiles(),
        referenceLoader: (_) async => Uint8List.fromList([1, 2, 3]),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Escanear esta imagen'));
  await tester.pumpAndSettle();
  expect(
    find.byType(AndroidView),
    findsOneWidget,
    reason: tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .join(' | '),
  );
  expect(
    tester
        .widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Guardar prueba de reconocimiento'),
        )
        .onPressed,
    isNull,
  );
  expect(repo.reports, 0);
  tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'marea/tour_ar/events',
    const StandardMethodCodec().encodeSuccessEnvelope({
      'id': 'one',
      'state': 'tracking',
      'sessionId':
          (tester.widget<AndroidView>(find.byType(AndroidView)).creationParams
              as Map)['sessionId'],
    }),
    (_) {},
  );
  await tester.pump();
  await tester.pump();
  // The existing preview measures real elapsed time with DateTime.now(). Only
  // this automated test supplies a platform event; the app retains native AR.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 3100)),
  );
  await tester.pump(const Duration(seconds: 3));
  expect(
    tester
        .widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Guardar prueba de reconocimiento'),
        )
        .onPressed,
    isNotNull,
  );
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
    await tester.ensureVisible(find.text('Lista de paradas'));
    await tester.tap(find.text('Lista de paradas'));
    await tester.pumpAndSettle();
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

  group('recognition report confirmation', () {
    const events = MethodChannel('marea/tour_ar/events');
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(events, (_) async => null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            SystemChannels.platform_views,
            (call) async => call.method == 'create' ? 1 : null,
          );
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(events, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, null);
    });

    testWidgets('confirms matching tested reference and releases camera', (
      tester,
    ) async {
      final repo = ReportARRepo();
      await prepareRecognitionReport(tester, repo);
      await tester.ensureVisible(find.text('Guardar prueba de reconocimiento'));
      await tester.tap(find.text('Guardar prueba de reconocimiento'));
      await tester.pumpAndSettle();
      expect(repo.reports, 1);
      expect(
        find.text('Prueba guardada para esta referencia.'),
        findsOneWidget,
      );
      expect(find.byType(AndroidView), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'camera has one main action and menu requires fresh recognition',
      (tester) async {
        final repo = ReportARRepo();
        await prepareRecognitionReport(tester, repo);
        final previous =
            (tester.widget<AndroidView>(find.byType(AndroidView)).creationParams
                as Map)['sessionId'];
        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.text('Volver a la lista'), findsNothing);
        expect(find.text('Saltar parada'), findsNothing);

        await tester.tap(find.byTooltip('Más opciones'));
        await tester.pumpAndSettle();
        expect(find.byType(AndroidView), findsNothing);
        await tester.tap(find.text('Volver a la lista'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Escanear esta imagen'));
        await tester.pumpAndSettle();
        final current =
            (tester.widget<AndroidView>(find.byType(AndroidView)).creationParams
                as Map)['sessionId'];
        expect(current, isNot(previous));
        tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'marea/tour_ar/events',
          const StandardMethodCodec().encodeSuccessEnvelope({
            'id': 'one',
            'state': 'tracking',
            'sessionId': previous,
          }),
          (_) {},
        );
        await tester.pump();
        await tester.pump();
        expect(find.text('Imagen reconocida'), findsNothing);
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(
                  FilledButton,
                  'Guardar prueba de reconocimiento',
                ),
              )
              .onPressed,
          isNull,
        );
        expect(repo.reports, 0);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('rejects missing confirmation or a different reference result', (
      tester,
    ) async {
      final repo = ReportARRepo();
      await prepareRecognitionReport(tester, repo);
      final mutations = <void Function(Map<String, dynamic>)>[
        (result) =>
            TourRecord(result).document.point('one')!.ar!['tested_version'] =
                null,
        (result) => result['id'] = 'another-tour',
        (result) => result['owner_id'] = 'another-owner',
        (result) => TourRecord(result).document.point('one')!.data['id'] =
            'another-point',
        (result) =>
            TourRecord(result).document.point('one')!.ar!['reference_version'] =
                'another-version',
        (result) =>
            TourRecord(result).document.point('one')!.ar!['reference_path'] =
                'another-reference.jpg',
        (result) =>
            TourRecord(result).document.point('one')!.ar!['width_cm'] = 30,
      ];
      for (final mutate in mutations) {
        repo.mutateResponse = mutate;
        await tester.ensureVisible(
          find.text('Guardar prueba de reconocimiento'),
        );
        await tester.tap(find.text('Guardar prueba de reconocimiento'));
        await tester.pump();
        await tester.pump();
        expect(
          find.text('Prueba guardada para esta referencia.'),
          findsNothing,
        );
        expect(
          find.textContaining('No pudimos confirmar que la prueba se guardó'),
          findsOneWidget,
        );
        expect(find.byType(AndroidView), findsOneWidget);
        expect(find.text('Parada one'), findsWidgets);
        expect(tester.takeException(), isNull);
      }
      expect(repo.reports, mutations.length);
      // A rejected response must not replace the currently selected reference;
      // the same scan can still receive an exact confirmation on retry.
      repo.mutateResponse = null;
      await tester.ensureVisible(find.text('Guardar prueba de reconocimiento'));
      await tester.tap(find.text('Guardar prueba de reconocimiento'));
      await tester.pumpAndSettle();
      expect(repo.reports, mutations.length + 1);
      expect(
        find.text('Prueba guardada para esta referencia.'),
        findsOneWidget,
      );
      expect(find.byType(AndroidView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
