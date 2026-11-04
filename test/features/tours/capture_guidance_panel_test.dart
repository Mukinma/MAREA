import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/tours/capture/capture_guidance_panel.dart';
import 'package:marea/features/tours/capture/capture_plan.dart';

Widget panel({
  double yaw = 0,
  double pitch = 0,
  bool fresh = true,
  bool aimed = false,
  bool steady = false,
  bool busy = false,
  VoidCallback? onTake,
  double textScale = 1,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(
      body: ListView(
        children: const [
          SizedBox(height: 1800, child: Text('Vista de cámara')),
        ],
      ),
      bottomNavigationBar: CaptureGuidancePanel(
        target: const CaptureTarget('first', 0, 0),
        yaw: yaw,
        pitch: pitch,
        fresh: fresh,
        aimed: aimed,
        steady: steady,
        busy: busy,
        onTake: onTake ?? () {},
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'shows movement from current pose and keeps misaligned shutter off',
    (tester) async {
      await tester.pumpWidget(panel(yaw: -40, pitch: -25));
      expect(find.textContaining('Inclina hacia arriba 25°'), findsOneWidget);
      expect(find.textContaining('Gira 40° a la derecha'), findsOneWidget);
      expect(find.textContaining('Actual: giro -40°'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    },
  );

  testWidgets('matching pose still waits for stable recent sensors', (
    tester,
  ) async {
    await tester.pumpWidget(panel(aimed: true));
    expect(find.text('Mantén el teléfono estable un momento.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.pumpWidget(panel(aimed: true, steady: true, fresh: false));
    expect(find.textContaining('Esperando orientación'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('ready shutter stays reachable on a phone with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var accepted = 0;
    await tester.pumpWidget(
      panel(aimed: true, steady: true, textScale: 2, onTake: () => accepted++),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Aceptar toma').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Aceptar toma'));
    expect(accepted, 1);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Aceptar toma').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving disables shutter even with a fresh aligned pose', (
    tester,
  ) async {
    await tester.pumpWidget(panel(aimed: true, steady: true, busy: true));
    expect(find.text('Guardando la toma…'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}
