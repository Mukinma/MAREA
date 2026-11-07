import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart'
    as files;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/features/profile/presentation/cover_photo_editor.dart';
import 'package:marea/features/profile/presentation/edit_profile_screen.dart';
import 'package:marea/features/profile/presentation/profile_waves.dart';
import 'package:marea/shared/widgets/profile_image.dart';
import '../../support/fakes.dart';
import 'data/profile_image_picker_test.dart' show png;

class _Photos extends ImagePickerPlatform {
  XFile? result;
  ImageSource? source;
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    this.source = source;
    return result;
  }
}

class _Files extends files.FileSelectorPlatform {
  XFile? result;
  int calls = 0;
  @override
  Future<XFile?> openFile({
    List<files.XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    calls++;
    expect(
      acceptedTypeGroups!.single.uniformTypeIdentifiers,
      contains('public.image'),
    );
    return result;
  }
}

class _Media implements ProfileMediaRepository {
  final uploads = <Uint8List>[];
  @override
  Future<String> upload(Uint8List png) async {
    uploads.add(png);
    return '${sampleProfile.id}/cover.png';
  }

  @override
  Future<void> remove(String path) async {}
  @override
  Future<String> signedUrl(String path) async =>
      throw StateError('No network in tests');
}

Future<void> _tapAsync(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.runAsync(() async {
    await tester.tap(finder);
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
  }
  await tester.pumpAndSettle();
}

void main() {
  test('cover framing stays inside the image with a fixed aspect ratio', () {
    for (final size in [const Size(1200, 600), const Size(600, 1200)]) {
      for (final zoom in [1.0, 2.0, 4.0]) {
        for (final center in [
          Offset.zero,
          const Offset(.5, .5),
          const Offset(1, 1),
        ]) {
          final rect = coverPhotoRect(size, zoom, center);
          expect(rect.width / rect.height, 2);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
        }
      }
    }
  });

  for (final source in ['Galería']) {
    testWidgets(
      '$source previews and saves the photo only with the general save button',
      (tester) async {
        final photos = _Photos(), filePicker = _Files(), media = _Media();
        final originalPhotos = ImagePickerPlatform.instance;
        final originalFiles = files.FileSelectorPlatform.instance;
        ImagePickerPlatform.instance = photos;
        files.FileSelectorPlatform.instance = filePicker;
        addTearDown(() {
          ImagePickerPlatform.instance = originalPhotos;
          files.FileSelectorPlatform.instance = originalFiles;
        });
        final bytes = (await tester.runAsync(() => png(120, 180)))!;
        photos.result = filePicker.result = XFile.fromData(
          bytes,
          name: 'photo.png',
          mimeType: 'image/png',
        );
        const waveColors = [0xFF123456, 0xFFABCDEF];
        final profiles = FakeProfileRepository()
          ..value = sampleProfile.copyWith(waveColors: waveColors);
        final controller = AppSessionController(
          authRepository: FakeAuthRepository(),
          profileRepository: profiles,
          legalRepository: FakeLegalRepository(),
        );
        await controller.initialize();
        addTearDown(controller.dispose);
        final router = GoRouter(
          initialLocation: '/profile/edit',
          routes: [
            GoRoute(
              path: '/profile/edit',
              builder: (_, _) => EditProfileScreen(
                controller: controller,
                mediaRepository: media,
              ),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, _) => const Scaffold(body: Text('Perfil')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('edit-cover-action')));
        await tester.tap(find.byKey(const Key('edit-cover-action')));
        await tester.pumpAndSettle();
        expect(find.text('Galería'), findsOneWidget);
        expect(find.text('Cámara'), findsNothing);
        expect(find.text('Archivos'), findsNothing);
        expect(find.text('Estilos de MAREA'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(ListTile),
          ),
          findsNWidgets(2),
        );
        await _tapAsync(tester, find.text(source));
        expect(find.byType(CoverPhotoEditor), findsOneWidget);
        expect(
          tester
              .widget<CoverPhotoEditor>(find.byType(CoverPhotoEditor))
              .waveColors,
          waveColors,
        );
        expect(filePicker.calls, 0);
        expect(photos.source, ImageSource.gallery);
        await tester.tap(find.byTooltip('Acercar foto'));
        await tester.drag(
          find.byKey(const Key('cover-photo-crop')),
          const Offset(12, -16),
        );
        await tester.pumpAndSettle();
        await _tapAsync(tester, find.text('Usar foto'));
        expect(find.byType(CoverPhotoEditor), findsNothing);
        expect(media.uploads, isEmpty);
        expect(profiles.value.coverPath, sampleProfile.coverPath);
        final image = tester
            .widgetList<ProfileImage>(find.byType(ProfileImage))
            .singleWhere((p) => p.preview != null);
        final decoded = await tester.runAsync(() async {
          final codec = await ui.instantiateImageCodec(image.preview!);
          final frame = (await codec.getNextFrame()).image;
          final data = await frame.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final result = (
            frame.width,
            frame.height,
            data!.buffer.asUint8List().sublist(data.lengthInBytes - 4),
          );
          frame.dispose();
          codec.dispose();
          return result;
        });
        expect(decoded!.$1 / decoded.$2, closeTo(2, .06));
        expect(decoded.$3, [
          0,
          170,
          153,
          255,
        ]); // The lower pixels are the photo, not baked-in waves.
        expect(
          tester
              .widgetList<ProfileWaves>(find.byType(ProfileWaves))
              .every((p) => p.colors[0] == waveColors[0]),
          isTrue,
        );
        await tester.tap(find.byKey(const Key('edit-save-button')));
        await tester.pumpAndSettle();
        expect(media.uploads, hasLength(1));
        expect(profiles.value.coverPath, '${sampleProfile.id}/cover.png');
        expect(profiles.value.waveColors, waveColors);
        expect(profiles.value.fullName, sampleProfile.fullName);
        expect(profiles.value.avatarPath, sampleProfile.avatarPath);
        await tester.pump(const Duration(seconds: 3));
        router.go('/profile/edit');
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<ProfileImage>(find.byType(ProfileImage))
              .any((p) => p.path == profiles.value.coverPath),
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'unified styles replace a photo only on save and preserve wave colors',
    (tester) async {
      const waveColors = [0xFF123456, 0xFFABCDEF];
      final previous = '${sampleProfile.id}/previous.png';
      final profiles = FakeProfileRepository()
        ..value = sampleProfile.copyWith(
          coverPath: previous,
          waveColors: waveColors,
        );
      final media = _Media();
      final controller = AppSessionController(
        authRepository: FakeAuthRepository(),
        profileRepository: profiles,
        legalRepository: FakeLegalRepository(),
      );
      await controller.initialize();
      addTearDown(controller.dispose);
      final router = GoRouter(
        initialLocation: '/profile/edit',
        routes: [
          GoRoute(
            path: '/profile/edit',
            builder: (_, _) => EditProfileScreen(
              controller: controller,
              mediaRepository: media,
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, _) => const Scaffold(body: Text('Perfil')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cambiar foto de portada'), findsOneWidget);
      expect(find.text('Cambiar portada'), findsNothing);
      expect(find.text('Estilo de portada'), findsNothing);
      Future<void> styles() async {
        await tester.ensureVisible(find.byKey(const Key('edit-cover-action')));
        await tester.tap(find.byKey(const Key('edit-cover-action')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Estilos de MAREA'));
        await tester.pumpAndSettle();
      }

      await styles();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(profiles.value.coverPath, previous);
      expect(
        tester
            .widgetList<ProfileImage>(find.byType(ProfileImage))
            .any((image) => image.path == previous),
        isTrue,
      );
      await styles();
      await tester.tap(find.text('Menta'));
      await tester.pumpAndSettle();
      expect(profiles.value.coverPath, previous);
      expect(media.uploads, isEmpty);
      expect(
        tester.widget<ProfileCover>(find.byType(ProfileCover)).preset,
        'menta',
      );
      expect(
        tester
            .widgetList<ProfileWaves>(find.byType(ProfileWaves))
            .every(
              (waves) =>
                  waves.colors[0] == waveColors[0] &&
                  waves.colors[1] == waveColors[1],
            ),
        isTrue,
      );
      await tester.tap(find.byKey(const Key('edit-save-button')));
      await tester.pumpAndSettle();
      expect(profiles.value.coverPath, isNull);
      expect(profiles.value.coverPreset, 'menta');
      expect(profiles.value.waveColors, waveColors);
      expect(profiles.value.avatarPath, sampleProfile.avatarPath);
      expect(media.uploads, isEmpty);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'menu and crop cancellation preserve the cover; presets remain available',
    (tester) async {
      final original = ImagePickerPlatform.instance;
      final photos = _Photos();
      ImagePickerPlatform.instance = photos;
      addTearDown(() => ImagePickerPlatform.instance = original);
      final controller = await authenticatedController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: EditProfileScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cambiar foto de portada'), findsOneWidget);
      expect(find.text('Cambiar portada'), findsNothing);
      expect(find.text('Estilo de portada'), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('edit-cover-action')));
      await tester.tap(find.byKey(const Key('edit-cover-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(photos.source, isNull);
      final bytes = (await tester.runAsync(() => png(100, 100)))!;
      photos.result = XFile.fromData(
        bytes,
        name: 'cover.png',
        mimeType: 'image/png',
      );
      await tester.ensureVisible(find.byKey(const Key('edit-cover-action')));
      await tester.tap(find.byKey(const Key('edit-cover-action')));
      await tester.pumpAndSettle();
      await _tapAsync(tester, find.text('Galería'));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<ProfileImage>(find.byType(ProfileImage))
            .where((p) => p.preview != null),
        isEmpty,
      );
      await tester.ensureVisible(find.byKey(const Key('edit-cover-action')));
      await tester.tap(find.byKey(const Key('edit-cover-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Estilos de MAREA'));
      await tester.pumpAndSettle();
      for (final name in ['Marea', 'Lavanda', 'Durazno', 'Menta']) {
        expect(find.text(name), findsWidgets);
      }
      await tester.tap(find.text('Lavanda'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<ProfileCover>(find.byType(ProfileCover))
            .every((p) => p.preset == 'lavanda'),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
