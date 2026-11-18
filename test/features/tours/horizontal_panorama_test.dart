import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/tours/presentation/horizontal_panorama.dart';
import '../../support/panorama_fixture.dart';

void main() {
  testWidgets(
    'horizontal panorama starts at the center and stops at the image edges',
    (tester) async {
      final image = MemoryImage(
        panoramaJpegFixture(width: 768, height: 128, includeXmp: false),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: HorizontalPanorama(image: image, aspectRatio: 6),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final view = find.byKey(const ValueKey('horizontal-panorama-scroll'));
      final scroll = tester.widget<SingleChildScrollView>(view);
      expect(scroll.scrollDirection, Axis.horizontal);
      expect(scroll.controller!.offset, closeTo(450, 1));
      expect(find.text(horizontalPanoramaNotice), findsOneWidget);
      await tester.drag(view, const Offset(2000, 0));
      await tester.pumpAndSettle();
      expect(scroll.controller!.offset, 0);
      await tester.drag(view, const Offset(-2500, 0));
      await tester.pumpAndSettle();
      expect(
        scroll.controller!.offset,
        scroll.controller!.position.maxScrollExtent,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
