import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:marea/features/profile/presentation/edit_profile_screen.dart';
import 'package:marea/shared/widgets/profile_image.dart';
import '../../support/fakes.dart';
import '../../support/test_app.dart';
import 'data/profile_image_picker_test.dart' show png;

class _Gallery extends ImagePickerPlatform {
  XFile? result;
  int calls = 0;
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    calls++;
    return result;
  }
}

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('camera receives taps and previews/cancels at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final original = ImagePickerPlatform.instance;
      final gallery = _Gallery();
      ImagePickerPlatform.instance = gallery;
      addTearDown(() => ImagePickerPlatform.instance = original);
      final controller = await authenticatedController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        testApp(EditProfileScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
      final action = find.byKey(const Key('edit-avatar-action'));
      await tester.ensureVisible(action);
      expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
      await tester.tap(action, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(
        gallery.calls,
        1,
        reason: 'A real pointer must reach the camera button',
      );
      expect(find.text('Todo guardado'), findsOneWidget);

      final Uint8List bytes = (await tester.runAsync(() => png(80, 80)))!;
      gallery.result = XFile.fromData(
        bytes,
        name: 'avatar.png',
        mimeType: 'image/png',
      );
      await tester.runAsync(() async {
        await tester.tap(action);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(gallery.calls, 2);
      expect(
        tester
            .widgetList<ProfileImage>(find.byType(ProfileImage))
            .where((image) => image.preview != null),
        hasLength(1),
      );
      expect(find.text('Guardar cambios'), findsOneWidget);

      gallery.result = null;
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(gallery.calls, 3);
      expect(
        tester
            .widgetList<ProfileImage>(find.byType(ProfileImage))
            .where((image) => image.preview != null),
        hasLength(1),
      );
      final cover = find.byKey(const Key('edit-cover-action'));
      await tester.ensureVisible(cover);
      await tester.tap(cover);
      await tester.pumpAndSettle();
      expect(gallery.calls, 4);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
