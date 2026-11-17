import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/tours/capture/capture_aim_overlay.dart';
import 'package:marea/features/tours/capture/capture_plan.dart';

void main() {
  Widget overlay({
    CaptureTarget? target = const CaptureTarget('front', 0, 0),
    double yaw = 0,
    double pitch = 0,
    bool fresh = true,
  }) => MaterialApp(
    home: Scaffold(
      body: CaptureAimOverlay(
        target: target,
        yaw: yaw,
        pitch: pitch,
        fresh: fresh,
      ),
    ),
  );

  testWidgets('only recent aligned readings turn the visual cue green', (
    tester,
  ) async {
    for (final widget in [
      overlay(yaw: 30),
      overlay(fresh: false),
      overlay(yaw: double.nan),
      overlay(target: null),
    ]) {
      await tester.pumpWidget(widget);
      expect(find.byKey(const Key('capture-aim-ready')), findsNothing);
      expect(find.byType(Text), findsNothing);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(overlay(yaw: 2, pitch: -1));
    expect(find.byKey(const Key('capture-aim-ready')), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('ceiling guidance does not demand an arbitrary compass heading', (
    tester,
  ) async {
    await tester.pumpWidget(
      overlay(target: const CaptureTarget('roof', 0, 90), yaw: 179, pitch: 88),
    );
    expect(find.byKey(const Key('capture-aim-ready')), findsOneWidget);
    await tester.pumpWidget(
      overlay(target: const CaptureTarget('roof', 0, 90), yaw: 179, pitch: 30),
    );
    expect(find.byKey(const Key('capture-aim-ready')), findsNothing);
  });
}
