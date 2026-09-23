import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';

Future<Uint8List> png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xff00aa99),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final avatar in [true, false]) {
    test(
      'prepares ${avatar ? 'profile' : 'post/cover'} PNG with bounded dimensions',
      () async {
        final result = await ProfileImagePicker.prepare(
          await png(2000, 1000),
          avatar: avatar,
        );
        expect(result.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
        expect(result.length, lessThanOrEqualTo(4194304));
        final codec = await ui.instantiateImageCodec(result);
        final image = (await codec.getNextFrame()).image;
        expect(image.width, avatar ? 640 : 1600);
        expect(image.height, avatar ? 320 : 800);
        image.dispose();
        codec.dispose();
      },
    );
  }
  test('small images retain their original dimensions', () async {
    final result = await ProfileImagePicker.prepare(
      await png(80, 120),
      avatar: true,
    );
    final codec = await ui.instantiateImageCodec(result);
    final image = (await codec.getNextFrame()).image;
    expect([image.width, image.height], [80, 120]);
    image.dispose();
    codec.dispose();
  });
  test('invalid image data returns a readable failure', () async {
    await expectLater(
      ProfileImagePicker.prepare(Uint8List.fromList([1, 2, 3]), avatar: false),
      throwsA(isA<AppFailure>()),
    );
    await expectLater(
      ProfileImagePicker.prepare(Uint8List(0), avatar: false),
      throwsA(isA<AppFailure>()),
    );
  });
}
