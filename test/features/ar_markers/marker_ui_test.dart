import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as image;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/ar_markers/data/marker_repository.dart';
import 'package:marea/features/ar_markers/models/ar_marker.dart';
import 'package:marea/features/ar_markers/presentation/marker_editor_screen.dart';
import 'package:marea/features/ar_markers/presentation/marker_management_screen.dart';

import '../../support/fakes.dart';
import '../../support/panorama_fixture.dart';

const markerId = '11111111-1111-4111-8111-111111111111';

ArMarker marker({String? owner, bool tested = false}) => ArMarker({
  'id': markerId,
  'owner_id': owner ?? sampleProfile.id,
  'name': 'Menú del taller',
  'description': 'Información pública del taller.',
  'width_cm': 20.0,
  'reference_path': 'reference.jpg',
  'reference_version': 'reference-v1',
  'tested_version': tested ? 'reference-v1' : null,
  'storage': 'local',
  'active': false,
});

class MarkerUiRepository implements MarkerRepository {
  List<ArMarker> items = [];
  final listedOwners = <String>[];
  final gets = <(String, String)>[];
  final deletions = <(String, String)>[];
  final saves =
      <({String owner, Map<String, dynamic> values, Uint8List? bytes})>[];
  final loadedOwners = <String>[];
  bool failSave = false, failDelete = false;
  final imageBytes = panoramaJpegFixture(includeXmp: false);

  @override
  Future<List<ArMarker>> listOwned(String ownerId) async {
    listedOwners.add(ownerId);
    return items;
  }

  @override
  Future<ArMarker?> get(String ownerId, String id) async {
    gets.add((ownerId, id));
    return items.where((item) => item.id == id).firstOrNull;
  }

  @override
  Future<Uint8List> loadImage(String ownerId, ArMarker marker) async {
    loadedOwners.add(ownerId);
    return imageBytes;
  }

  @override
  Future<ArMarker> save(
    String ownerId,
    Map<String, dynamic> values, {
    Uint8List? imageBytes,
  }) async {
    saves.add((
      owner: ownerId,
      values: Map<String, dynamic>.from(values),
      bytes: imageBytes == null ? null : Uint8List.fromList(imageBytes),
    ));
    if (failSave) throw StateError('No pudimos guardar el archivo local.');
    final saved = ArMarker({
      ...marker().data,
      ...values,
      'id': values['id'] ?? markerId,
      'owner_id': ownerId,
    });
    items = [saved];
    return saved;
  }

  @override
  Future<void> delete(String ownerId, String id) async {
    deletions.add((ownerId, id));
    if (failDelete) throw StateError('No pudimos eliminar el archivo.');
    items = items.where((item) => item.id != id).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'La interfaz no debe reconocer ni publicar por sí sola.',
  );
}

class MarkerGallery extends ImagePickerPlatform {
  XFile? result;
  int calls = 0;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    expect(source, ImageSource.gallery);
    calls++;
    return result;
  }
}

class MarkerLocation implements DeviceLocationService {
  final prompts = <bool>[];
  DevicePosition position = const DevicePosition(
    latitude: 19.4326,
    longitude: -99.1332,
    accuracy: 8,
  );
  bool fails = false;

  @override
  Future<DevicePosition> current({
    bool requestPermission = false,
    bool Function()? isCurrent,
  }) async {
    prompts.add(requestPermission);
    expect(isCurrent?.call(), isTrue);
    if (fails) {
      throw const DeviceLocationFailure(DeviceLocationFailureKind.denied);
    }
    return position;
  }

  @override
  Future<bool> openSettings({bool locationDisabled = false}) async => false;
}

Future<AppSessionController> markerController({bool signedIn = true}) async {
  final auth = FakeAuthRepository();
  if (!signedIn) auth.user = null;
  final controller = AppSessionController(
    authRepository: auth,
    profileRepository: FakeProfileRepository(),
  );
  await controller.initialize();
  addTearDown(controller.dispose);
  return controller;
}

Future<void> mountEditor(
  WidgetTester tester,
  AppSessionController controller,
  MarkerUiRepository repo, {
  String? id,
  MarkerLocation? location,
}) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: MarkerEditorScreen(
        controller: controller,
        repository: repo,
        markerId: id,
        locationService: location ?? MarkerLocation(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> field(WidgetTester tester, String key, String value) async {
  final input = find.byKey(Key(key));
  await tester.ensureVisible(input);
  await tester.enterText(input, value);
}

Future<void> saveMarker(WidgetTester tester) async {
  final save = find.text('Guardar marcador');
  if (save.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      save,
      250,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  if (save.hitTestable().evaluate().isEmpty) {
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
  }
  await tester.tap(save);
  await tester.pumpAndSettle();
}

Future<void> waitForMarker(WidgetTester tester, bool Function() done) async {
  for (var frame = 0; frame < 200; frame++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (done()) {
      await tester.pumpAndSettle();
      return;
    }
  }
  fail('La imagen no terminó de prepararse.');
}

Uint8List markerPreviewBytes(WidgetTester tester) {
  final provider = tester.widget<Image>(find.byType(Image)).image;
  return ((provider is ResizeImage ? provider.imageProvider : provider)
          as MemoryImage)
      .bytes;
}

void main() {
  late ImagePickerPlatform originalGallery;
  late MarkerGallery gallery;

  setUp(() {
    originalGallery = ImagePickerPlatform.instance;
    gallery = MarkerGallery();
    ImagePickerPlatform.instance = gallery;
  });

  tearDown(() => ImagePickerPlatform.instance = originalGallery);

  test(
    'image preparation normalizes JPEG orientation and validates bounds',
    () {
      final original = image.decodeJpg(panoramaJpegFixture(includeXmp: false))!;
      original.exif.imageIfd.orientation = 6;
      final prepared = prepareMarkerImage(
        Uint8List.fromList(image.encodeJpg(original)),
      );
      final decoded = image.decodeJpg(prepared)!;
      expect(decoded.width, 128);
      expect(decoded.height, 256);
      expect(decoded.exif.imageIfd.orientation ?? 1, 1);
      expect(
        () => prepareMarkerImage(Uint8List.fromList([1, 2, 3])),
        throwsStateError,
      );
      expect(
        () => prepareMarkerImage(
          Uint8List.fromList(
            image.encodeJpg(image.Image(width: 32, height: 32)),
          ),
        ),
        throwsStateError,
      );
    },
  );

  testWidgets('management scopes images, navigates and confirms deletion', (
    tester,
  ) async {
    final controller = await markerController();
    final repo = MarkerUiRepository()
      ..items = [marker(), marker(owner: 'other')];
    final router = GoRouter(
      initialLocation: '/ar-markers',
      routes: [
        GoRoute(
          path: '/ar-markers',
          builder: (_, _) =>
              MarkerManagementScreen(controller: controller, repository: repo),
        ),
        for (final path in [
          '/ar-markers/new',
          '/ar-markers/:id/edit',
          '/ar-markers/:id/scan',
        ])
          GoRoute(
            path: path,
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => context.pop(),
                child: Text('Volver de ${state.uri.path}'),
              ),
            ),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Menú del taller'), findsOneWidget);
    expect(find.textContaining('Guardado en este dispositivo'), findsOneWidget);
    expect(repo.listedOwners, [sampleProfile.id]);
    expect(repo.loadedOwners, [sampleProfile.id]);
    expect(find.byType(FilledButton), findsOneWidget);
    await tester.tap(find.text('Añadir marcador'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver de /ar-markers/new'));
    await tester.pumpAndSettle();
    expect(repo.listedOwners, hasLength(2));
    for (final (label, route) in [('Editar', 'edit'), ('Probar RA', 'scan')]) {
      await tester.tap(find.byTooltip('Opciones de Menú del taller'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Volver de /ar-markers/$markerId/$route'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byTooltip('Opciones de Menú del taller'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conservar'));
    await tester.pumpAndSettle();
    expect(repo.deletions, isEmpty);
    expect(find.text('Menú del taller'), findsOneWidget);
    repo.items = [marker()];
    await tester.tap(find.byTooltip('Opciones de Menú del taller'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();
    expect(repo.deletions, [(sampleProfile.id, markerId)]);
    expect(find.text('Menú del taller'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'new marker preserves its chosen image on cancel and save error',
    (tester) async {
      final controller = await markerController();
      final repo = MarkerUiRepository()..failSave = true;
      final location = MarkerLocation();
      await mountEditor(tester, controller, repo, location: location);
      expect(location.prompts, isEmpty);
      await field(tester, 'marker-name', 'Mi referencia');
      gallery.result = XFile.fromData(
        panoramaJpegFixture(includeXmp: false),
        name: 'reference.jpg',
      );
      await tester.ensureVisible(find.text('Elegir imagen'));
      await tester.tap(find.text('Elegir imagen'));
      await waitForMarker(
        tester,
        () => find.byType(Image).evaluate().isNotEmpty,
      );
      final preview = markerPreviewBytes(tester);
      gallery.result = null;
      await tester.tap(find.text('Cambiar imagen'));
      await tester.pumpAndSettle();
      expect(gallery.calls, 2);
      final afterCancel = markerPreviewBytes(tester);
      expect(afterCancel, orderedEquals(preview));
      await saveMarker(tester);
      expect(find.text('No pudimos guardar el archivo local.'), findsOneWidget);
      expect(repo.saves, hasLength(1));
      expect(repo.saves.single.bytes, orderedEquals(preview));
      expect(find.byType(Image), findsOneWidget);
      repo.failSave = false;
      await saveMarker(tester);
      expect(repo.saves, hasLength(2));
      expect(repo.saves.last.owner, sampleProfile.id);
      expect(repo.saves.last.values['name'], 'Mi referencia');
      expect(repo.saves.last.values['width_cm'], 20.0);
      expect(repo.saves.last.values['latitude'], isNull);
      expect(repo.saves.last.values['longitude'], isNull);
      expect(repo.saves.last.values['active'], isFalse);
      expect(repo.saves.last.values.containsKey('id'), isFalse);
      // The preview must keep its height while switching to the saved image;
      // otherwise the scroll jumps and hides the success message.
      expect(
        find.text('Guardado en este dispositivo').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new marker rejects an unreadable image and requires a reference',
    (tester) async {
      final controller = await markerController();
      final repo = MarkerUiRepository();
      await mountEditor(tester, controller, repo);
      await field(tester, 'marker-name', 'Sin imagen válida');
      gallery.result = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'bad.jpg',
      );
      await tester.ensureVisible(find.text('Elegir imagen'));
      await tester.tap(find.text('Elegir imagen'));
      await waitForMarker(
        tester,
        () => find
            .textContaining('No pudimos leer la imagen')
            .evaluate()
            .isNotEmpty,
      );
      await saveMarker(tester);
      expect(
        find.text('Elige la imagen que reconocerá la cámara.'),
        findsOneWidget,
      );
      expect(repo.saves, isEmpty);
      expect(find.byType(Image), findsNothing);
    },
  );

  testWidgets(
    'editing validates width and URL before preserving the saved image',
    (tester) async {
      final controller = await markerController();
      final repo = MarkerUiRepository()..items = [marker()];
      await mountEditor(tester, controller, repo, id: markerId);
      for (final width in ['0', 'NaN', '1001']) {
        await field(tester, 'marker-width', width);
        await saveMarker(tester);
        expect(
          find.text('Escribe un ancho de entre 1 y 1000 cm.'),
          findsOneWidget,
        );
        expect(repo.saves, isEmpty);
      }
      await field(tester, 'marker-width', '25,5');
      await field(tester, 'marker-menu-url', 'javascript:alert(1)');
      await saveMarker(tester);
      expect(
        find.text('Usa un enlace http:// o https:// válido.'),
        findsOneWidget,
      );
      expect(repo.saves, isEmpty);
      await field(tester, 'marker-menu-url', 'https://example.com/menu');
      await saveMarker(tester);
      expect(repo.saves.single.values['id'], markerId);
      expect(repo.saves.single.values['width_cm'], 25.5);
      expect(repo.saves.single.values['menu_url'], 'https://example.com/menu');
      expect(repo.saves.single.bytes, isNull);
      expect(gallery.calls, 0);
    },
  );

  for (final accuracy in [8.0, 35.0]) {
    testWidgets(
      'location is explicit and ${accuracy}m accuracy controls nearby',
      (tester) async {
        final controller = await markerController();
        final repo = MarkerUiRepository()..items = [marker(tested: true)];
        final location = MarkerLocation()
          ..position = DevicePosition(
            latitude: 19.4326,
            longitude: -99.1332,
            accuracy: accuracy,
          );
        await mountEditor(
          tester,
          controller,
          repo,
          id: markerId,
          location: location,
        );
        expect(location.prompts, isEmpty);
        await tester.ensureVisible(find.text('Usar mi ubicación'));
        await tester.tap(find.text('Usar mi ubicación'));
        await tester.pumpAndSettle();
        expect(location.prompts, [true]);
        final toggle = tester.widget<SwitchListTile>(
          find.byType(SwitchListTile),
        );
        expect(toggle.onChanged != null, accuracy <= 20);
        if (accuracy <= 20) {
          await tester.tap(find.text('Notificar cerca'));
          await tester.pump();
        }
        await saveMarker(tester);
        expect(repo.saves.single.values['latitude'], 19.4326);
        expect(repo.saves.single.values['longitude'], -99.1332);
        expect(repo.saves.single.values['location_exact'], accuracy <= 20);
        expect(repo.saves.single.values['location_accuracy'], accuracy);
        expect(repo.saves.single.values['active'], accuracy <= 20);
      },
    );
  }

  testWidgets('a denied location request saves no invented coordinates', (
    tester,
  ) async {
    final controller = await markerController();
    final repo = MarkerUiRepository()..items = [marker(tested: true)];
    final location = MarkerLocation()..fails = true;
    await mountEditor(
      tester,
      controller,
      repo,
      id: markerId,
      location: location,
    );
    await tester.ensureVisible(find.text('Usar mi ubicación'));
    await tester.tap(find.text('Usar mi ubicación'));
    await tester.pumpAndSettle();
    await saveMarker(tester);
    expect(repo.saves.single.values['latitude'], isNull);
    expect(repo.saves.single.values['longitude'], isNull);
    expect(repo.saves.single.values['location_exact'], isFalse);
    expect(repo.saves.single.values['active'], isFalse);
  });

  testWidgets('a missing or foreign marker never exposes an editable form', (
    tester,
  ) async {
    final controller = await markerController();
    final repo = MarkerUiRepository()..items = [marker(owner: 'other-account')];
    await mountEditor(tester, controller, repo, id: markerId);
    expect(
      find.text('No encontramos este marcador en tu cuenta.'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNothing);
    expect(repo.loadedOwners, isEmpty);
    expect(repo.saves, isEmpty);
  });

  testWidgets('signing out clears the draft and blocks writes', (tester) async {
    final controller = await markerController();
    final repo = MarkerUiRepository()..items = [marker()];
    await mountEditor(tester, controller, repo, id: markerId);
    expect(find.byType(TextFormField), findsNWidgets(4));
    await controller.signOut();
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(find.text('Guardar marcador'), findsNothing);
    expect(find.textContaining('La cuenta cambió'), findsOneWidget);
    expect(repo.saves, isEmpty);
  });

  testWidgets(
    'without an account neither management nor editor reads markers',
    (tester) async {
      final controller = await markerController(signedIn: false);
      final repo = MarkerUiRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: MarkerManagementScreen(
            controller: controller,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Inicia sesión para ver tus marcadores.'),
        findsOneWidget,
      );
      await mountEditor(tester, controller, repo, id: markerId);
      expect(
        find.text('Inicia sesión para guardar un marcador.'),
        findsOneWidget,
      );
      expect(repo.listedOwners, isEmpty);
      expect(repo.gets, isEmpty);
      expect(repo.saves, isEmpty);
    },
  );
}
