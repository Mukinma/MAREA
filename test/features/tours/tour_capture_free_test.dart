import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/tours/capture/capture_plan.dart';
import 'package:marea/features/tours/capture/capture_cube_guide.dart';
import 'package:marea/features/tours/capture/capture_resume_photo.dart';
import 'package:marea/features/tours/capture/tour_capture_screen.dart';
import 'package:marea/features/tours/data/tour_local_store.dart';
import 'package:marea/features/tours/data/tour_repository.dart';
import 'package:marea/features/tours/data/tus_uploader.dart';
import 'package:marea/features/tours/models/tour_models.dart';

import '../../support/fakes.dart';
import '../../support/panorama_fixture.dart';

Map<String, dynamic> cloneFreeSession(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

class FreeMemoryStore extends TourLocalStore {
  Map<String, dynamic>? saved;
  final files = <String, Uint8List>{};
  final readPaths = <String>[];
  final writes = <Map<String, dynamic>>[];
  final history = <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> read(String account, String key) async {
    expect(account, sampleProfile.id);
    if (key.startsWith('capture-archive-') || key == 'capture-history-scene') {
      return history[key] == null ? null : cloneFreeSession(history[key]!);
    }
    expect(key, 'capture-scene');
    return saved == null ? null : cloneFreeSession(saved!);
  }

  @override
  Future<void> write(
    String account,
    String key,
    Map<String, dynamic> data,
  ) async {
    expect(account, sampleProfile.id);
    if (key.startsWith('capture-archive-') || key == 'capture-history-scene') {
      history[key] = cloneFreeSession(data);
      return;
    }
    expect(key, 'capture-scene');
    saved = cloneFreeSession(data);
    writes.add(cloneFreeSession(data));
  }

  @override
  Future<String> saveBytes(String account, String id, Uint8List bytes) async {
    expect(account, sampleProfile.id);
    final path = '/memory/$id.jpg';
    files[path] = Uint8List.fromList(bytes);
    return path;
  }

  @override
  Future<Uint8List> readBytes(String path) async {
    readPaths.add(path);
    return Uint8List.fromList(files[path]!);
  }
}

class FreeRepository implements TourRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'La captura local no debe llamar al repositorio remoto.',
  );
}

class FreeUploader implements TourTusUploader {
  final uploads = <({Uint8List bytes, String bucket, String path})>[];
  int progressReports = 0, disposals = 0;

  @override
  Future<void> upload({
    required Uint8List bytes,
    required String bucket,
    required String path,
    Map<String, dynamic>? checkpoint,
    required Future<void> Function(Map<String, dynamic>) save,
    required bool Function() isCurrent,
    void Function(double)? progress,
  }) async {
    expect(isCurrent(), isTrue);
    expect(checkpoint, isNull);
    uploads.add((bytes: Uint8List.fromList(bytes), bucket: bucket, path: path));
    final url = 'memory:upload-${uploads.length}';
    await save({'url': url, 'offset': 0});
    progress?.call(.5);
    progressReports++;
    expect(isCurrent(), isTrue);
    await save({'url': url, 'offset': bytes.length});
    progress?.call(1);
    progressReports++;
  }

  @override
  void dispose() => disposals++;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('La prueba de subida no utiliza HTTP.');
}

class FreeSubmitRepository extends FreeRepository {
  final transfers = FreeUploader();
  final begins = <({String tour, String scene, String mode})>[];
  final submissions = <Map<String, dynamic>>[];

  @override
  Future<String> beginCapture(String tour, String scene, String mode) async {
    begins.add((tour: tour, scene: scene, mode: mode));
    return 'free-capture';
  }

  @override
  TourTusUploader uploader() => transfers;

  @override
  Future<TourJob> submitCapture(
    String capture,
    Map<String, dynamic> manifest,
  ) async {
    expect(capture, 'free-capture');
    submissions.add(cloneFreeSession(manifest));
    return TourJob({'id': 'free-job', 'state': 'cancelled'});
  }
}

class FreeCamera extends CameraController {
  FreeCamera() : super(device, ResolutionPreset.high, enableAudio: false);

  static const device = CameraDescription(
    name: 'rear-camera',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 90,
    lensType: CameraLensType.wide,
  );

  int pictures = 0, disposals = 0;

  @override
  Future<void> initialize() async {
    value = value.copyWith(
      isInitialized: true,
      previewSize: const Size(1280, 720),
    );
  }

  @override
  Future<XFile> takePicture() async {
    pictures++;
    return XFile.fromData(
      panoramaJpegFixture(includeXmp: false),
      name: 'camera-$pictures.jpg',
      mimeType: 'image/jpeg',
    );
  }

  @override
  Widget buildPreview() =>
      const ColoredBox(key: Key('free-camera-preview'), color: Colors.blueGrey);

  @override
  Future<void> lockCaptureOrientation([DeviceOrientation? orientation]) async {}

  @override
  Future<void> setZoomLevel(double zoom) async {}

  @override
  Future<void> setFocusMode(FocusMode mode) async {}

  @override
  Future<void> setExposureMode(ExposureMode mode) async {}

  @override
  Future<void> dispose() async {
    disposals++;
    // The fake never starts a native camera or its initialization future.
    await super.dispose();
  }
}

class FallibleFreeCamera extends FreeCamera {
  bool failNext = false;
  @override
  Future<XFile> takePicture() {
    if (failNext) throw CameraException('capture_failed', 'Camera unavailable');
    return super.takePicture();
  }
}

class ArchiveFailingStore extends FreeMemoryStore {
  String? failingKey;
  @override
  Future<void> write(
    String account,
    String key,
    Map<String, dynamic> data,
  ) async {
    if (key == failingKey) throw StateError('No se pudo guardar la captura.');
    await super.write(account, key, data);
  }
}

void seedLegacyPhoto(FreeMemoryStore store) {
  final plan = CapturePlan.create(hfov: 40, vfov: 60);
  expect(plan.targets, hasLength(35));
  store.saved = {
    'mode': 'photos',
    'camera_name': FreeCamera.device.name,
    'plan': plan.toJson(),
    'frames': [
      {
        'id': 'legacy-photo',
        'local_path': '/memory/legacy-photo.jpg',
        'width': 256,
        'height': 128,
        'yaw': 0.0,
        'pitch': 0.0,
        'roll': 0.0,
        'hfov': 40.0,
        'vfov': 60.0,
        'target_id': plan.targets.first.id,
      },
    ],
  };
  store.files['/memory/legacy-photo.jpg'] = panoramaJpegFixture(
    includeXmp: false,
  );
}

Future<void> waitForFreeCapture(
  WidgetTester tester,
  bool Function() done,
) async {
  for (var frame = 0; frame < 200; frame++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (done()) return;
  }
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .join(' | ');
  fail('La cámara no terminó la operación. Pantalla: $texts');
}

Future<void> mountFreeCapture(
  WidgetTester tester,
  FreeMemoryStore store,
  FreeCamera camera, {
  TourRepository? repository,
  bool allowCaptureUploads = true,
}) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controller = AppSessionController(
    authRepository: FakeAuthRepository(),
    profileRepository: FakeProfileRepository(),
    tourRepository: repository ?? FreeRepository(),
    allowCaptureUploads: allowCaptureUploads,
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
        listCameras: () async => [FreeCamera.device],
        cameraFactory: (description) {
          expect(description, FreeCamera.device);
          return camera;
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> startFreeCapture(WidgetTester tester) async {
  await tester.tap(find.text('Añadir panorama'));
  await tester.pumpAndSettle();
  expect(find.text('Tomar fotos'), findsOneWidget);
  await tester.tap(find.text('Tomar fotos'));
  await waitForFreeCapture(tester, () => manualShutterEnabled(tester));
}

bool manualShutterEnabled(WidgetTester tester) {
  final shutter = find.widgetWithText(FilledButton, 'Tomar foto');
  return shutter.evaluate().length == 1 &&
      tester.widget<FilledButton>(shutter).onPressed != null;
}

void expectSavedJpeg(FreeMemoryStore store, Map<String, dynamic> frame) {
  final bytes = store.files[frame['local_path']];
  expect(bytes, isNotNull);
  final decoded = image.decodeJpg(bytes!);
  expect(decoded, isNotNull);
  expect(frame['width'], decoded!.width);
  expect(frame['height'], decoded.height);
}

void main() {
  const motion = MethodChannel('marea/tour_motion');
  const events = MethodChannel('marea/tour_motion/events');
  const codec = StandardMethodCodec();
  late List<String> motionCalls;
  late Set<String> failures;
  late bool listening;

  setUp(() {
    motionCalls = [];
    failures = {};
    listening = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(motion, (call) async {
          motionCalls.add(call.method);
          if (failures.contains(call.method)) {
            throw PlatformException(code: 'unavailable');
          }
          return call.method == 'cameraInfo'
              ? {'hfov': 40.0, 'vfov': 60.0}
              : null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(events, (call) async {
          if (call.method == 'listen') listening = true;
          if (call.method == 'cancel') listening = false;
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(motion, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(events, null);
  });

  for (final key in ['capture-history-scene', 'capture-scene']) {
    testWidgets(
      'archive failure at $key preserves the selected capture and originals',
      (tester) async {
        final store = ArchiveFailingStore();
        seedLegacyPhoto(store);
        final original = cloneFreeSession(store.saved!);
        final bytes = Uint8List.fromList(
          store.files['/memory/legacy-photo.jpg']!,
        );
        await mountFreeCapture(
          tester,
          store,
          FreeCamera(),
          allowCaptureUploads: false,
        );
        store.failingKey = key;
        await tester.tap(find.byTooltip('Más opciones de captura'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Empezar otra captura'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Empezar otra'));
        await tester.pumpAndSettle();
        expect(store.saved, original);
        expect(find.text('1 fotos guardadas'), findsOneWidget);
        expect(store.files['/memory/legacy-photo.jpg'], bytes);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'starting another capture keeps and restores the previous session and JPEG',
    (tester) async {
      final store = FreeMemoryStore();
      seedLegacyPhoto(store);
      final old = cloneFreeSession(store.saved!);
      final bytes = Uint8List.fromList(
        store.files['/memory/legacy-photo.jpg']!,
      );
      await mountFreeCapture(
        tester,
        store,
        FreeCamera(),
        allowCaptureUploads: false,
      );
      await tester.tap(find.byTooltip('Más opciones de captura'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Empezar otra captura'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Empezar otra'));
      await tester.pumpAndSettle();
      expect(store.saved, isEmpty);
      expect(store.files['/memory/legacy-photo.jpg'], bytes);
      expect(find.text('Añadir panorama'), findsOneWidget);
      await tester.tap(find.byTooltip('Más opciones de captura'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Capturas anteriores'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 fotos'));
      await tester.pumpAndSettle();
      expect(store.saved, old);
      expect(find.text('1 fotos guardadas'), findsOneWidget);
      expect(store.files['/memory/legacy-photo.jpg'], bytes);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cube starts at centre, advances only on a saved JPEG and resumes without changing old photos',
    (tester) async {
      final store = FreeMemoryStore();
      seedLegacyPhoto(store);
      final original = cloneFreeSession(store.saved!);
      final camera = FreeCamera();
      await mountFreeCapture(tester, store, camera, allowCaptureUploads: false);
      await tester.tap(find.text('Retomar captura'));
      await waitForFreeCapture(tester, () => manualShutterEnabled(tester));
      expect(find.textContaining('Paso 1 de'), findsOneWidget);
      expect(find.textContaining('Primero toma el frente'), findsWidgets);
      await tester.tap(find.text('Tomar foto'));
      await waitForFreeCapture(
        tester,
        () =>
            (store.saved!['frames'] as List).length == 2 &&
            manualShutterEnabled(tester),
      );
      final guide = CaptureCubeGuide.restore(store.saved!['cube_guide'])!;
      final frames = store.saved!['frames'] as List;
      expect(guide.nextIndex(frames), 1);
      expect(frames.first, (original['frames'] as List).first);
      expect(
        (frames.last as Map)['cube_guide_step'],
        guide.steps.first.target.id,
      );
      expect((frames.last as Map).containsKey('yaw'), isFalse);
      expect(find.textContaining('Paso 2 de'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      final nextCamera = FallibleFreeCamera();
      await mountFreeCapture(
        tester,
        store,
        nextCamera,
        allowCaptureUploads: false,
      );
      await tester.tap(find.text('Retomar captura'));
      await waitForFreeCapture(tester, () => manualShutterEnabled(tester));
      expect(find.textContaining('Paso 2 de'), findsOneWidget);
      nextCamera.failNext = true;
      await tester.tap(find.text('Tomar foto'));
      await waitForFreeCapture(tester, () => manualShutterEnabled(tester));
      expect(store.saved!['frames'], hasLength(2));
      expect(find.textContaining('Paso 2 de'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'local pilot cannot prepare or upload but can resume and save a real camera JPEG',
    (tester) async {
      final store = FreeMemoryStore();
      seedLegacyPhoto(store);
      final original = cloneFreeSession(store.saved!);
      final camera = FreeCamera();
      final repo = FreeSubmitRepository();
      await mountFreeCapture(
        tester,
        store,
        camera,
        repository: repo,
        allowCaptureUploads: false,
      );
      final prepare = find.widgetWithText(
        FilledButton,
        'Preparar panorama (1 fotos)',
      );
      expect(tester.widget<FilledButton>(prepare).onPressed, isNull);
      expect(
        find.textContaining('el envío están desactivados'),
        findsOneWidget,
      );
      await tester.tap(find.text('Retomar captura'));
      await waitForFreeCapture(tester, () => manualShutterEnabled(tester));
      await tester.ensureVisible(find.text('Tomar foto'));
      await tester.tap(find.text('Tomar foto'));
      await waitForFreeCapture(
        tester,
        () => (store.saved!['frames'] as List).length == 2,
      );
      final frames = (store.saved!['frames'] as List)
          .cast<Map<String, dynamic>>();
      expect(frames.first, (original['frames'] as List).first);
      expectSavedJpeg(store, frames.last);
      expect(repo.begins, isEmpty);
      expect(repo.submissions, isEmpty);
      expect(repo.transfers.uploads, isEmpty);
    },
  );

  testWidgets(
    'resuming legacy photos opens the manual camera without alignment or sensors',
    (tester) async {
      final store = FreeMemoryStore();
      seedLegacyPhoto(store);
      final previous = cloneFreeSession(store.saved!);
      final previousJpeg = Uint8List.fromList(
        store.files['/memory/legacy-photo.jpg']!,
      );
      final camera = FreeCamera();
      await mountFreeCapture(tester, store, camera);
      await tester.tap(find.text('Retomar captura'));
      await waitForFreeCapture(tester, () => manualShutterEnabled(tester));
      expect(find.byKey(const Key('free-camera-preview')), findsOneWidget);
      expect(find.byType(CaptureResumePhoto), findsNothing);
      expect(find.text('Pausar captura'), findsNothing);
      expect(store.readPaths, isEmpty);
      expect((store.saved!['frames'] as List), hasLength(1));
      expect(camera.pictures, 1, reason: 'La calibración no guarda una toma.');

      await tester.tap(find.text('Tomar foto'));
      await waitForFreeCapture(
        tester,
        () =>
            (store.saved!['frames'] as List).length == 2 &&
            manualShutterEnabled(tester),
      );
      final frames = (store.saved!['frames'] as List)
          .cast<Map<String, dynamic>>();
      expect(frames.first, (previous['frames'] as List).single);
      expect(store.saved!['plan'], previous['plan']);
      expect(
        store.files['/memory/legacy-photo.jpg'],
        orderedEquals(previousJpeg),
      );
      expectSavedJpeg(store, frames.last);
      expect(frames.last['pose_status'], 'unavailable');
      for (final name in ['yaw', 'sensor_yaw', 'pitch', 'roll', 'target_id']) {
        expect(frames.last.containsKey(name), isFalse, reason: name);
      }
      expect(find.text('2 fotos guardadas'), findsOneWidget);
      expect(camera.pictures, 2);
      await tester.tap(find.byTooltip('Terminar fotos'));
      await waitForFreeCapture(
        tester,
        () => find.text('Retomar captura').evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      expect(find.text('Preparar panorama (1 fotos)'), findsOneWidget);
      expect(find.text('2 fotos guardadas'), findsOneWidget);
      expect(camera.disposals, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final failure in ['cameraInfo', 'start']) {
    testWidgets('$failure failure keeps the manual camera usable', (
      tester,
    ) async {
      failures.add(failure);
      final store = FreeMemoryStore();
      final camera = FreeCamera();
      await mountFreeCapture(tester, store, camera);
      await startFreeCapture(tester);
      expect(motionCalls, contains(failure));
      expect(camera.disposals, 0);
      expect(find.byKey(const Key('free-camera-preview')), findsOneWidget);
      await tester.tap(find.text('Tomar foto'));
      await waitForFreeCapture(
        tester,
        () =>
            (store.saved!['frames'] as List).isNotEmpty &&
            manualShutterEnabled(tester),
      );
      final frame = Map<String, dynamic>.from(
        (store.saved!['frames'] as List).single as Map,
      );
      expectSavedJpeg(store, frame);
      expect(frame['pose_status'], 'unavailable');
      expect(frame.containsKey('yaw'), isFalse);
      expect(frame.containsKey('target_id'), isFalse);
      if (failure == 'cameraInfo') {
        expect(frame.containsKey('hfov'), isFalse);
        expect(frame.containsKey('vfov'), isFalse);
      }
      expect(find.text('1 fotos guardadas'), findsOneWidget);
      expect(camera.disposals, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'a fresh pose outside the guide saves measured angles without completing a target',
    (tester) async {
      final store = FreeMemoryStore();
      final camera = FreeCamera();
      await mountFreeCapture(tester, store, camera);
      await startFreeCapture(tester);
      expect(listening, isTrue);
      final plan = cloneFreeSession(
        store.saved!['plan'] as Map<String, dynamic>,
      );
      tester.binding.channelBuffers.push(
        events.name,
        codec.encodeSuccessEnvelope({'yaw': 13.0, 'pitch': 20.0, 'roll': 7.0}),
        (_) {},
      );
      await tester.pump();
      expect(manualShutterEnabled(tester), isTrue);
      await tester.tap(find.text('Tomar foto'));
      await waitForFreeCapture(
        tester,
        () =>
            (store.saved!['frames'] as List).isNotEmpty &&
            manualShutterEnabled(tester),
      );
      final frame = Map<String, dynamic>.from(
        (store.saved!['frames'] as List).single as Map,
      );
      expectSavedJpeg(store, frame);
      expect(frame['pose_status'], 'ready');
      expect(frame['sensor_yaw'], 13.0);
      expect(frame['yaw'], 13.0);
      expect(frame['pitch'], 20.0);
      expect(frame['roll'], 7.0);
      expect(frame['hfov'], 40.0);
      expect(frame['vfov'], 60.0);
      expect(frame.containsKey('target_id'), isFalse);
      expect(store.saved!['plan'], plan);
      await tester.tap(find.byTooltip('Terminar fotos'));
      await waitForFreeCapture(
        tester,
        () => find.text('Retomar captura').evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      expect(find.text('Preparar panorama (1 fotos)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'preparation uploads only measured photos and persists their checkpoints without a completed guide',
    (tester) async {
      final store = FreeMemoryStore();
      final plan = CapturePlan.create(hfov: 40, vfov: 60).toJson();
      final frames = <Map<String, dynamic>>[
        for (var i = 0; i < 6; i++)
          {
            'id': 'measured-$i',
            'local_path': '/memory/measured-$i.jpg',
            'width': 256,
            'height': 128,
            'yaw': -150.0 + i * 51,
            'pitch': -20.0 + i * 8,
            'roll': -3.0 + i,
            'hfov': 40.0,
            'vfov': 60.0,
            'pose_status': 'ready',
            'pose_session': 'actual-motion-session',
            'sensor_yaw': -148.0 + i * 51,
            'cube_guide_version': 1,
            'cube_guide_step': 'suggestion-$i',
          },
        {
          'id': 'local-without-pose',
          'local_path': '/memory/local-without-pose.jpg',
          'width': 256,
          'height': 128,
          'pose_status': 'unavailable',
          'pose_session': 'actual-motion-session',
        },
      ];
      store.saved = {'mode': 'photos', 'plan': plan, 'frames': frames};
      for (final frame in frames) {
        store.files[frame['local_path'] as String] = panoramaJpegFixture(
          includeXmp: false,
        );
      }
      final previous = cloneFreeSession(store.saved!);
      final camera = FreeCamera();
      final repo = FreeSubmitRepository();
      await mountFreeCapture(tester, store, camera, repository: repo);
      expect(find.text('7 fotos guardadas'), findsOneWidget);
      expect(find.byType(CameraPreview), findsNothing);
      expect(repo.begins, isEmpty);
      expect(repo.transfers.uploads, isEmpty);
      final prepare = find.text('Preparar panorama (6 fotos)');
      await tester.ensureVisible(prepare);
      await tester.tap(prepare);
      await waitForFreeCapture(
        tester,
        () =>
            store.saved!['job_id'] == 'free-job' &&
            repo.transfers.disposals == 1,
      );
      expect(repo.begins, [(tour: 'tour', scene: 'scene', mode: 'photos')]);
      expect(repo.submissions, hasLength(1));
      expect(repo.transfers.uploads, hasLength(6));
      expect(repo.transfers.progressReports, 12);
      expect(camera.pictures, 0);
      expect(store.saved!['capture_id'], 'free-capture');
      expect(store.saved!['plan'], previous['plan']);
      final savedFrames = (store.saved!['frames'] as List)
          .cast<Map<String, dynamic>>();
      expect(savedFrames, hasLength(7));
      expect(savedFrames.last, (previous['frames'] as List).last);
      final manifest = repo.submissions.single;
      expect(manifest['mode'], 'photos');
      final submitted = (manifest['frames'] as List)
          .cast<Map<String, dynamic>>();
      expect(submitted, hasLength(6));
      for (var i = 0; i < submitted.length; i++) {
        final original = frames[i];
        final upload = repo.transfers.uploads[i];
        final remote = '${sampleProfile.id}/free-capture/${original['id']}.jpg';
        expect(upload.bucket, 'tour-inputs');
        expect(upload.path, remote);
        expect(
          upload.bytes,
          orderedEquals(store.files[original['local_path']]!),
        );
        expect(submitted[i], {
          'id': original['id'],
          'path': remote,
          'width': 256,
          'height': 128,
          'yaw': original['yaw'],
          'pitch': original['pitch'],
          'roll': original['roll'],
          'hfov': 40.0,
          'vfov': 60.0,
        });
        expect(savedFrames[i], {
          ...original,
          'path': remote,
          'upload': {
            'url': 'memory:upload-${i + 1}',
            'offset': upload.bytes.length,
          },
        });
        expect(
          store.writes.any((session) {
            final frame = (session['frames'] as List)[i] as Map;
            return frame['upload']?['url'] == 'memory:upload-${i + 1}' &&
                frame['upload']?['offset'] == 0;
          }),
          isTrue,
          reason: 'El checkpoint inicial de la foto $i debe persistirse.',
        );
        expectSavedJpeg(store, savedFrames[i]);
      }
      expect(store.readPaths, [
        for (final frame in frames.take(6)) frame['local_path'],
      ]);
      expectSavedJpeg(store, savedFrames.last);
      expect(find.text('Procesamiento cancelado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
