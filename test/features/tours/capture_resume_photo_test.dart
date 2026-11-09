import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:marea/features/tours/capture/capture_resume_photo.dart';
import 'package:marea/features/tours/data/tour_local_store.dart';

class PhotoStore extends TourLocalStore {
  final paths = <String>[];
  final requests = <Completer<Uint8List>>[];

  @override
  Future<Uint8List> readBytes(String path) {
    paths.add(path);
    final request = Completer<Uint8List>();
    requests.add(request);
    return request.future;
  }
}

Uint8List png(int red) {
  final image = img.Image(width: 2, height: 2);
  img.fill(image, color: img.ColorRgb8(red, 50, 100));
  return Uint8List.fromList(img.encodePng(image));
}

Widget host(PhotoStore store, {String path = 'first.jpg', int sensor = 0}) =>
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text('Sensor $sensor'),
            CaptureResumePhoto(
              key: const ValueKey('resume-photo'),
              store: store,
              path: path,
            ),
          ],
        ),
      ),
    );

Widget alignmentHost(
  PhotoStore store, {
  String path = 'first.jpg',
  int sensor = 0,
  bool busy = false,
  VoidCallback? onAlign,
}) => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(textScaler: TextScaler.linear(2)),
    child: Scaffold(
      appBar: AppBar(title: const Text('Retomar')),
      body: Column(
        children: [
          Text('Sensor $sensor'),
          Expanded(
            child: CaptureResumePhoto(
              store: store,
              path: path,
              livePreview: const ColoredBox(
                key: ValueKey('live-camera'),
                color: Colors.blue,
              ),
              aspectRatio: 9 / 16,
              counterLabel: '1 de 35 tomas',
              busy: busy,
              onAlign: onAlign,
            ),
          ),
        ],
      ),
    ),
  ),
);

Uint8List portraitJpeg() {
  final image = img.Image(width: 720, height: 1280);
  img.fill(image, color: img.ColorRgb8(40, 70, 130));
  return Uint8List.fromList(img.encodeJpg(image, quality: 70));
}

MemoryImage displayedPhoto(WidgetTester tester) {
  final provider = tester.widget<Image>(find.byType(Image)).image;
  return (provider is ResizeImage ? provider.imageProvider : provider)
      as MemoryImage;
}

void main() {
  testWidgets(
    'pending photo reserves height and sensor rebuilds share one read',
    (tester) async {
      final store = PhotoStore();
      await tester.pumpWidget(host(store));
      for (var sensor = 1; sensor <= 10; sensor++) {
        await tester.pumpWidget(host(store, sensor: sensor));
        expect(tester.getSize(find.byType(CaptureResumePhoto)).height, 160);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(Image), findsNothing);
      }
      expect(store.paths, ['first.jpg']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('loaded guide remains mounted through sensor rebuilds', (
    tester,
  ) async {
    final store = PhotoStore(), first = png(10);
    await tester.pumpWidget(host(store));
    store.requests.single.complete(first);
    await tester.pumpAndSettle();
    final imageElement = tester.element(find.byType(Image));
    for (var sensor = 1; sensor <= 20; sensor++) {
      await tester.pumpWidget(host(store, sensor: sensor));
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.element(find.byType(Image)), same(imageElement));
      expect(tester.getSize(find.byType(CaptureResumePhoto)).height, 160);
      expect(displayedPhoto(tester).bytes, same(first));
    }
    expect(store.paths, ['first.jpg']);
    expect(tester.takeException(), isNull);
  });

  for (final change in ['path', 'store']) {
    testWidgets(
      'changing $change reloads without displaying the previous photo',
      (tester) async {
        final firstStore = PhotoStore(), first = png(10), second = png(200);
        await tester.pumpWidget(host(firstStore));
        firstStore.requests.single.complete(first);
        await tester.pumpAndSettle();
        expect(displayedPhoto(tester).bytes, same(first));

        final nextStore = change == 'store' ? PhotoStore() : firstStore;
        final nextPath = change == 'path' ? 'second.jpg' : 'first.jpg';
        await tester.pumpWidget(host(nextStore, path: nextPath));
        expect(find.byType(Image), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(tester.getSize(find.byType(CaptureResumePhoto)).height, 160);
        expect(nextStore.paths.last, nextPath);
        expect(firstStore.paths.length, change == 'path' ? 2 : 1);
        if (change == 'store') expect(nextStore.paths.length, 1);

        nextStore.requests.last.complete(second);
        await tester.pumpAndSettle();
        expect(displayedPhoto(tester).bytes, same(second));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'a late read from the old path cannot replace the current guide',
    (tester) async {
      final store = PhotoStore(), second = png(200);
      await tester.pumpWidget(host(store));
      await tester.pumpWidget(host(store, path: 'second.jpg'));
      store.requests.first.complete(png(10));
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      store.requests.last.complete(second);
      await tester.pumpAndSettle();
      expect(displayedPhoto(tester).bytes, same(second));
      expect(store.paths, ['first.jpg', 'second.jpg']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'an error keeps the reserved space and retry performs one new read',
    (tester) async {
      final store = PhotoStore(), recovered = png(100);
      await tester.pumpWidget(host(store));
      store.requests.single.completeError(StateError('Photo unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('No pudimos abrir la foto guía.'), findsOneWidget);
      expect(tester.getSize(find.byType(CaptureResumePhoto)).height, 160);
      await tester.pumpWidget(host(store, sensor: 1));
      expect(store.paths, ['first.jpg']);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(store.paths, ['first.jpg', 'first.jpg']);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(tester.getSize(find.byType(CaptureResumePhoto)).height, 160);
      store.requests.last.complete(recovered);
      await tester.pumpAndSettle();
      expect(displayedPhoto(tester).bytes, same(recovered));
      expect(find.text('Reintentar'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  group('live alignment overlay', () {
    late Uint8List portrait;
    setUpAll(() => portrait = portraitJpeg());

    testWidgets(
      'guide and live camera share the portrait frame with a reachable alignment action',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = PhotoStore();
        var aligned = 0;
        await tester.pumpWidget(alignmentHost(store, onAlign: () => aligned++));
        expect(find.byKey(const ValueKey('live-camera')), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        store.requests.single.complete(portrait);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('live-camera')), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        expect(
          find.ancestor(
            of: find.byType(Image),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Opacity &&
                  widget.opacity > .3 &&
                  widget.opacity < .6,
            ),
          ),
          findsOneWidget,
        );
        final aspect = tester.widget<AspectRatio>(find.byType(AspectRatio));
        expect(aspect.aspectRatio, 9 / 16);
        expect(find.text('1 de 35 tomas'), findsOneWidget);
        expect(
          find.text('Continuar con este encuadre').hitTestable(),
          findsOneWidget,
        );
        final guideElement = tester.element(find.byType(Image));
        for (var sensor = 1; sensor <= 10; sensor++) {
          await tester.pumpWidget(
            alignmentHost(store, sensor: sensor, onAlign: () => aligned++),
          );
          expect(tester.element(find.byType(Image)), same(guideElement));
          expect(find.byType(CircularProgressIndicator), findsNothing);
        }
        expect(store.paths, ['first.jpg']);
        await tester.tap(find.text('Continuar con este encuadre'));
        expect(aligned, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'loading, errors and busy state prevent alignment until retry succeeds',
      (tester) async {
        final store = PhotoStore();
        var aligned = 0;
        await tester.pumpWidget(alignmentHost(store, onAlign: () => aligned++));
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        store.requests.single.completeError(StateError('Missing guide'));
        await tester.pumpAndSettle();
        expect(find.text('Reintentar'), findsOneWidget);
        expect(find.text('Continuar con este encuadre'), findsNothing);
        expect(aligned, 0);
        await tester.tap(find.text('Reintentar'));
        await tester.pump();
        expect(store.paths, ['first.jpg', 'first.jpg']);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        store.requests.last.complete(portrait);
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          alignmentHost(store, busy: true, onAlign: () => aligned++),
        );
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        await tester.pumpWidget(alignmentHost(store, onAlign: () => aligned++));
        await tester.tap(find.text('Continuar con este encuadre'));
        expect(aligned, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a new reference removes the old overlay while keeping the live preview',
      (tester) async {
        final store = PhotoStore();
        await tester.pumpWidget(alignmentHost(store, onAlign: () {}));
        store.requests.single.complete(portrait);
        await tester.pumpAndSettle();
        expect(find.byType(Image), findsOneWidget);
        await tester.pumpWidget(
          alignmentHost(store, path: 'another.jpg', onAlign: () {}),
        );
        expect(find.byKey(const ValueKey('live-camera')), findsOneWidget);
        expect(find.byType(Image), findsNothing);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        store.requests.last.complete(png(200));
        await tester.pumpAndSettle();
        expect(find.byType(Image), findsOneWidget);
        expect(store.paths, ['first.jpg', 'another.jpg']);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
