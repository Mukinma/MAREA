import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/tours/capture/capture_cube.dart';
import 'package:marea/features/tours/capture/capture_cube_guide.dart';
import 'package:marea/features/tours/capture/capture_frames.dart';
import 'package:marea/features/tours/capture/capture_guidance_panel.dart';
import 'package:marea/features/tours/capture/capture_plan.dart';

void main() {
  test(
    'calibrated guide starts at the centre of every side and keeps all measured-plan targets',
    () {
      final plan = CapturePlan.create(
        hfov: 39.2791466920366,
        vfov: 64.78388988521341,
      );
      final guide = CaptureCubeGuide.forPlan(plan);
      expect(guide.steps.length, 36);
      expect(
        guide.steps.map((s) => s.target.id).toSet(),
        plan.targets.map((t) => t.id).toSet(),
      );
      expect(guide.steps.first.target.yaw, 0);
      expect(guide.steps.first.target.pitch, 0);
      expect(guide.steps.first.face, CaptureCubeFace.front);
      for (final face in CaptureCubeFace.values) {
        final first = guide.steps.firstWhere((s) => s.face == face);
        expect(first.row, 1, reason: face.name);
        expect(first.column, 1, reason: face.name);
      }
      expect(guide.steps[guide.steps.length - 2].face, CaptureCubeFace.ceiling);
      expect(guide.steps.last.face, CaptureCubeFace.floor);
    },
  );

  test(
    'missing lens uses a 38-step visual route without inventing processing poses',
    () {
      final guide = CaptureCubeGuide.forPlan(null);
      expect(guide.steps, hasLength(38));
      expect(
        guide.steps.first.instruction(first: true),
        contains('altura de tus ojos'),
      );
      final frame = {
        'cube_guide_version': 1,
        'cube_guide_step': guide.steps.first.target.id,
      };
      expect(guide.nextIndex([frame]), 1);
      expect(canProcessCaptureFrame(frame), isFalse);
    },
  );

  test(
    'old photos do not falsely complete the guide; saved suggestions resume and repeat rolls back',
    () {
      final guide = CaptureCubeGuide.forPlan(null);
      final old = List.generate(67, (i) => {'target_id': '$i', 'yaw': 0.0});
      expect(guide.nextIndex(old), 0);
      final tagged = {
        'cube_guide_version': 1,
        'cube_guide_step': guide.steps.first.target.id,
      };
      expect(guide.nextIndex([...old, tagged]), 1);
      final restored = CaptureCubeGuide.restore(guide.toJson())!;
      expect(restored.nextIndex([...old, tagged]), 1);
      expect(
        restored.steps.map((s) => s.target.id),
        guide.steps.map((s) => s.target.id),
      );
      expect(restored.nextIndex(old), 0);
      expect(
        guide.nextIndex([
          {
            'cube_guide_version': 2,
            'cube_guide_step': guide.steps.last.target.id,
          },
        ]),
        0,
      );
    },
  );

  test('malformed or oversized saved guides cannot corrupt the screen', () {
    for (final raw in [
      null,
      {},
      {'version': 99, 'targets': []},
      {
        'version': 1,
        'targets': List.filled(41, {'id': 'x', 'yaw': 0, 'pitch': 0}),
      },
      {
        'version': 1,
        'targets': [
          {'id': 'x', 'yaw': double.nan, 'pitch': 0},
        ],
      },
      {
        'version': 1,
        'targets': [
          {'id': 'x', 'yaw': 0, 'pitch': 91},
        ],
      },
      {
        'version': 1,
        'targets': [
          {'id': 'x', 'yaw': 0, 'pitch': 0},
          {'id': 'x', 'yaw': 0, 'pitch': 0},
        ],
      },
    ]) {
      expect(CaptureCubeGuide.restore(raw), isNull);
    }
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'animated cube keeps one unrestricted shutter visible at text scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final guide = CaptureCubeGuide.forPlan(null);
        var takes = 0;
        Widget build(int index, {bool busy = false}) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              bottomNavigationBar: CaptureGuidancePanel(
                cubeGuide: guide,
                guideIndex: index,
                yaw: 177,
                pitch: -83,
                fresh: false,
                aimed: false,
                steady: false,
                busy: busy,
                onTake: () => takes++,
              ),
            ),
          ),
        );
        await tester.pumpWidget(build(0));
        await tester.pumpAndSettle();
        expect(find.byType(CaptureCube), findsOneWidget);
        expect(find.textContaining('altura de tus ojos'), findsOneWidget);
        expect(find.text('Tomar foto').hitTestable(), findsOneWidget);
        await tester.tap(find.text('Tomar foto'));
        expect(takes, 1);
        final roof = guide.steps.indexWhere(
          (s) => s.face == CaptureCubeFace.ceiling,
        );
        await tester.pumpWidget(build(roof));
        await tester.pump(const Duration(milliseconds: 320));
        expect(find.text('Techo · Centro'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tomar foto'));
        expect(takes, 2);
        await tester.pumpWidget(build(guide.steps.length));
        await tester.pumpAndSettle();
        expect(find.textContaining('Puedes tomar más fotos'), findsOneWidget);
        expect(find.text('Tomar foto').hitTestable(), findsOneWidget);
        await tester.pumpWidget(build(0, busy: true));
        await tester.pumpAndSettle();
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
