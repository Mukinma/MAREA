import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/tours/presentation/local_panorama_viewer.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import '../../support/panorama_fixture.dart';

void main() {
  testWidgets('a local sphere turns horizontally and vertically by touch', (
    tester,
  ) async {
    final bytes = panoramaJpegFixture();
    final views = <(double, double)>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocalPanoramaViewer(
            bytes: bytes,
            onViewChanged: (yaw, pitch, _) => views.add((yaw, pitch)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final viewer = tester.widget<PanoramaViewer>(find.byType(PanoramaViewer));
    expect(viewer.sensorControl, SensorControl.none);
    expect((viewer.child!.image as MemoryImage).bytes, same(bytes));
    views.clear();
    await tester.drag(find.byType(PanoramaViewer), const Offset(-180, 80));
    await tester.pumpAndSettle();
    expect(views, isNotEmpty);
    expect(views.any((p) => p.$1.abs() > 1), isTrue);
    expect(views.any((p) => p.$2.abs() > 1), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
