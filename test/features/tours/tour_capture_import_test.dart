import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/tours/capture/capture_plan.dart';
import 'package:marea/features/tours/capture/tour_capture_screen.dart';
import 'package:marea/features/tours/data/tour_local_store.dart';
import 'package:marea/features/tours/data/tour_repository.dart';
import 'package:marea/features/tours/models/tour_models.dart';
import '../../support/fakes.dart';
import '../../support/panorama_fixture.dart';

Map<String, dynamic> copySession(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

class ImportGallery extends ImagePickerPlatform {
  XFile? result;
  final sources = <ImageSource>[];

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    sources.add(source);
    return result;
  }
}

class ImportMemoryStore extends TourLocalStore {
  Map<String, dynamic>? saved;
  final files = <String, Uint8List>{};
  final history = <String, Map<String, dynamic>>{};
  int writes = 0, byteWrites = 0;
  bool failWrites = false;

  @override
  Future<Map<String, dynamic>?> read(String account, String key) async {
    expect(account, sampleProfile.id);
    if (key != 'capture-scene') return history[key];
    return saved == null ? null : copySession(saved!);
  }

  @override
  Future<void> write(
    String account,
    String key,
    Map<String, dynamic> data,
  ) async {
    expect(account, sampleProfile.id);
    if (key != 'capture-scene') {
      history[key] = copySession(data);
      return;
    }
    writes++;
    if (failWrites) throw StateError('No pudimos guardar el archivo local.');
    saved = copySession(data);
  }

  @override
  Future<String> saveBytes(String account, String id, Uint8List bytes) async {
    expect(account, sampleProfile.id);
    byteWrites++;
    final path = '/memory/$id.jpg';
    files[path] = Uint8List.fromList(bytes);
    return path;
  }

  @override
  Future<Uint8List> readBytes(String path) async {
    final bytes = files[path];
    if (bytes == null) throw StateError('Archivo no disponible');
    return Uint8List.fromList(bytes);
  }
}

class ImportRepository implements TourRepository {
  int begins = 0, submissions = 0;
  @override
  Future<bool> supportsHorizontalPanoramas() async => false;

  @override
  Future<String> beginCapture(String tour, String scene, String mode) async {
    begins++;
    throw StateError('La importación local no debe crear una captura remota.');
  }

  @override
  Future<TourJob> submitCapture(
    String capture,
    Map<String, dynamic> manifest,
  ) async {
    submissions++;
    throw StateError('La importación local no debe enviar trabajos remotos.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void preserveExistingPhoto(ImportMemoryStore store) {
  final plan = CapturePlan.create(hfov: 40, vfov: 60);
  store.saved = {
    'mode': 'photos',
    'camera_name': 'rear-camera',
    'plan': plan.toJson(),
    'frames': [
      {
        'id': 'accepted-photo',
        'local_path': '/memory/accepted-photo.jpg',
        'width': 128,
        'height': 256,
        'yaw': 0.0,
        'pitch': 0.0,
        'roll': 0.0,
        'hfov': 40.0,
        'vfov': 60.0,
        'target_id': plan.targets.first.id,
      },
    ],
  };
  store.files['/memory/accepted-photo.jpg'] = panoramaJpegFixture(
    includeXmp: false,
  );
}

Future<ImportRepository> mountCapture(
  WidgetTester tester,
  ImportMemoryStore store,
) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repo = ImportRepository();
  final controller = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: FakeProfileRepository(),
    tourRepository: repo,
  );
  await controller.initialize();
  addTearDown(controller.dispose);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: TourCaptureScreen(
        controller: controller,
        tourId: 'tour',
        sceneId: 'scene',
        localStore: store,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> waitForImport(WidgetTester tester, bool Function() done) async {
  for (var frame = 0; frame < 150; frame++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (done()) {
      await tester.pumpAndSettle();
      return;
    }
  }
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .join(' | ');
  fail('La importación no terminó. Pantalla: $texts');
}

Future<void> importFromMenu(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Más opciones de captura'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Importar desde galería'));
  await tester.pump();
}

void main() {
  const motion = MethodChannel('marea/tour_motion');
  late ImportGallery gallery;
  late ImagePickerPlatform originalGallery;

  setUp(() {
    originalGallery = ImagePickerPlatform.instance;
    gallery = ImportGallery();
    ImagePickerPlatform.instance = gallery;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(motion, (_) async => null);
  });

  tearDown(() {
    ImagePickerPlatform.instance = originalGallery;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(motion, null);
  });

  testWidgets(
    'Add panorama offers taking photos and gallery without starting either',
    (tester) async {
      final store = ImportMemoryStore();
      final repo = await mountCapture(tester, store);
      await tester.tap(find.text('Añadir panorama'));
      await tester.pumpAndSettle();
      expect(find.text('Tomar fotos'), findsOneWidget);
      expect(find.text('Importar desde galería'), findsOneWidget);
      expect(gallery.sources, isEmpty);
      expect(store.writes, 0);
      expect(repo.begins, 0);
      expect(repo.submissions, 0);
    },
  );

  testWidgets(
    'canceling the gallery keeps accepted photos and the stored session',
    (tester) async {
      final store = ImportMemoryStore();
      preserveExistingPhoto(store);
      final original = copySession(store.saved!);
      final repo = await mountCapture(tester, store);
      await importFromMenu(tester);
      await waitForImport(
        tester,
        () =>
            gallery.sources.length == 1 &&
            tester
                    .widget<FilledButton>(
                      find.widgetWithText(FilledButton, 'Retomar captura'),
                    )
                    .onPressed !=
                null,
      );
      expect(gallery.sources, [ImageSource.gallery]);
      expect(store.saved, original);
      expect(store.writes, 0);
      expect(store.byteWrites, 0);
      expect(find.text('1 fotos guardadas'), findsOneWidget);
      expect(repo.begins, 0);
      expect(repo.submissions, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'horizontal JPEG is accepted with a notice and original photos archived',
    (tester) async {
      final store = ImportMemoryStore();
      preserveExistingPhoto(store);
      final original = copySession(store.saved!);
      gallery.result = XFile.fromData(
        panoramaJpegFixture(includeXmp: false),
        name: 'ordinary-photo.jpg',
        mimeType: 'image/jpeg',
      );
      final repo = await mountCapture(tester, store);
      await importFromMenu(tester);
      await waitForImport(
        tester,
        () => find.text('Usar este panorama').evaluate().isNotEmpty,
      );
      expect(store.saved, original);
      expect(store.writes, 0);
      expect(store.byteWrites, 0);
      await tester.tap(find.text('Usar panorama'));
      await waitForImport(
        tester,
        () => find
            .textContaining('Panorámica horizontal elegida')
            .evaluate()
            .isNotEmpty,
      );
      expect(store.saved!['panorama_kind'], 'horizontal');
      expect(
        (store.saved!['frames'] as List).single.containsKey('hfov'),
        isFalse,
      );
      expect(
        store.history.values
            .where((entry) => entry['session'] != null)
            .single['session'],
        original,
      );
      expect(store.files.containsKey('/memory/accepted-photo.jpg'), isTrue);
      expect(
        find.textContaining('Esta imagen no incluye techo y piso.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Subir panorámica'));
      await tester.pumpAndSettle();
      expect(find.textContaining('aún no está disponible'), findsOneWidget);
      expect(repo.begins, 0);
      expect(repo.submissions, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'replacement requires confirmation and canceling keeps every accepted photo',
    (tester) async {
      final store = ImportMemoryStore();
      preserveExistingPhoto(store);
      final original = copySession(store.saved!);
      gallery.result = XFile.fromData(
        panoramaJpegFixture(),
        name: 'full-360.jpg',
        mimeType: 'image/jpeg',
      );
      final repo = await mountCapture(tester, store);
      await importFromMenu(tester);
      await waitForImport(
        tester,
        () => find.text('Usar este panorama').evaluate().isNotEmpty,
      );
      expect(
        find.textContaining('1 tomas de esta captura quedarán'),
        findsOneWidget,
      );
      expect(store.writes, 0);
      expect(store.byteWrites, 0);
      await tester.tap(find.text('Conservar captura'));
      await tester.pumpAndSettle();
      expect(store.saved, original);
      expect(store.writes, 0);
      expect(store.byteWrites, 0);
      expect(find.text('1 fotos guardadas'), findsOneWidget);
      expect(repo.begins, 0);
      expect(repo.submissions, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed persistence rolls replacement back in memory and on disk',
    (tester) async {
      final store = ImportMemoryStore();
      preserveExistingPhoto(store);
      final original = copySession(store.saved!);
      store.failWrites = true;
      gallery.result = XFile.fromData(
        panoramaJpegFixture(),
        name: 'full-360.jpg',
        mimeType: 'image/jpeg',
      );
      final repo = await mountCapture(tester, store);
      await importFromMenu(tester);
      await waitForImport(
        tester,
        () => find.text('Usar este panorama').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Usar panorama'));
      await waitForImport(
        tester,
        () => find
            .text('No pudimos guardar el archivo local.')
            .evaluate()
            .isNotEmpty,
      );
      expect(store.writes, 1);
      expect(store.byteWrites, 1);
      expect(store.saved, original);
      expect(store.files.containsKey('/memory/accepted-photo.jpg'), isTrue);
      expect(find.text('1 fotos guardadas'), findsOneWidget);
      expect(find.textContaining('Panorama 360° elegido'), findsNothing);
      expect(find.text('Retomar captura'), findsOneWidget);
      expect(repo.begins, 0);
      expect(repo.submissions, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'valid gallery import preserves original bytes and waits for explicit upload',
    (tester) async {
      final store = ImportMemoryStore();
      final bytes = panoramaJpegFixture();
      gallery.result = XFile.fromData(
        bytes,
        name: 'original-360.jpg',
        mimeType: 'image/jpeg',
      );
      final repo = await mountCapture(tester, store);
      await tester.tap(find.text('Añadir panorama'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Importar desde galería'));
      await tester.pump();
      await waitForImport(
        tester,
        () =>
            find.textContaining('Panorama 360° elegido').evaluate().isNotEmpty,
      );
      expect(find.text('Panorama 360° elegido · 256 × 128'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Subir panorámica'), findsOneWidget);
      expect(find.text('Añadir panorama'), findsNothing);
      expect(store.writes, 1);
      expect(store.byteWrites, 1);
      expect(store.saved!['mode'], 'import');
      final frames = store.saved!['frames'] as List;
      expect(frames, hasLength(1));
      expect(frames.single['target_id'], 'import');
      expect(store.files[frames.single['local_path']], orderedEquals(bytes));
      expect(repo.begins, 0);
      expect(repo.submissions, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
