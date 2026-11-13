import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/tours/capture/capture_guidance_panel.dart';
import 'package:marea/features/tours/capture/capture_plan.dart';

Widget panel({
  CaptureTarget? target = const CaptureTarget('first', 0, 0),
  double yaw = 0,
  double pitch = 0,
  bool fresh = true,
  bool aimed = false,
  bool steady = false,
  bool busy = false,
  VoidCallback? onTake,
  double textScale = 1,
  bool automatic = false,
  bool paused = false,
  bool showAngles = false,
  VoidCallback? onTogglePause,
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
        target: target,
        yaw: yaw,
        pitch: pitch,
        fresh: fresh,
        aimed: aimed,
        steady: steady,
        busy: busy,
        onTake: onTake ?? () {},
        automatic: automatic,
        paused: paused,
        showAngles: showAngles,
        onTogglePause: onTogglePause,
      ),
    ),
  ),
);

void main() {
  for (final (pitch, place, screenDirection) in [
    (90.0, 'techo', 'abajo'),
    (-90.0, 'piso', 'arriba'),
  ]) {
    testWidgets(
      '$place guide explains phone posture without demanding polar yaw',
      (tester) async {
        for (final yaw in [-179.0, 0.0, 163.0]) {
          await tester.pumpWidget(
            panel(
              target: CaptureTarget('pole', 0, pitch),
              yaw: yaw,
              pitch: pitch > 0 ? 55 : -55,
              automatic: true,
            ),
          );
          expect(
            find.textContaining('cámara trasera al $place'),
            findsOneWidget,
          );
          expect(
            find.textContaining('pantalla hacia $screenDirection'),
            findsOneWidget,
          );
          expect(find.textContaining('la foto se toma sola'), findsOneWidget);
          expect(find.textContaining('Gira'), findsNothing);
          expect(find.textContaining('90°'), findsNothing);
          expect(find.byType(FilledButton), findsOneWidget);
          expect(
            find.byIcon(
              pitch > 0
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
            ),
            findsOneWidget,
          );
        }
      },
    );
  }

  testWidgets(
    'returning from a polar pose first guides the camera to the front',
    (tester) async {
      await tester.pumpWidget(
        panel(
          target: const CaptureTarget('upper', -36, 45),
          yaw: 160,
          pitch: 88,
          automatic: true,
        ),
      );
      expect(
        find.textContaining('Primero apunta la cámara al frente'),
        findsOneWidget,
      );
      expect(find.textContaining('Gira'), findsNothing);
      expect(find.byIcon(Icons.stay_current_portrait), findsOneWidget);
    },
  );

  testWidgets(
    'automatic guide gives one movement at a time without exact degrees',
    (tester) async {
      await tester.pumpWidget(panel(yaw: -40, pitch: -25, automatic: true));
      expect(find.text('Gira despacio hacia la derecha.'), findsOneWidget);
      expect(find.textContaining('Inclina'), findsNothing);
      expect(find.textContaining('°'), findsNothing);
      await tester.pumpWidget(panel(yaw: 0, pitch: -25, automatic: true));
      expect(find.text('Inclina la cámara hacia arriba.'), findsOneWidget);
      expect(find.textContaining('Gira'), findsNothing);
      expect(find.textContaining('°'), findsNothing);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Pausar captura'), findsOneWidget);
    },
  );

  testWidgets(
    'polar guidance keeps pause and stale sensor explanations first',
    (tester) async {
      await tester.pumpWidget(
        panel(
          target: const CaptureTarget('ceiling', 0, 90),
          automatic: true,
          paused: true,
          fresh: false,
        ),
      );
      expect(find.textContaining('Captura en pausa'), findsOneWidget);
      expect(find.text('Continuar captura'), findsOneWidget);
      expect(find.textContaining('cámara trasera al techo'), findsNothing);
      await tester.pumpWidget(
        panel(
          target: const CaptureTarget('ceiling', 0, 90),
          automatic: true,
          fresh: false,
        ),
      );
      expect(find.textContaining('Esperando orientación'), findsOneWidget);
      expect(find.textContaining('cámara trasera al techo'), findsNothing);
    },
  );

  testWidgets(
    'polar instructions and the single pause button fit enlarged phone text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        panel(
          target: const CaptureTarget('ceiling', 0, 90),
          automatic: true,
          textScale: 2,
          onTogglePause: () {},
        ),
      );
      expect(find.text('Pausar captura').hitTestable(), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'automatic capture has one pause control and hides technical angles',
    (tester) async {
      var pauses = 0;
      var manualTakes = 0;
      await tester.pumpWidget(
        panel(
          automatic: true,
          aimed: true,
          steady: true,
          onTogglePause: () => pauses++,
          onTake: () => manualTakes++,
        ),
      );
      expect(find.text('Pausar captura'), findsOneWidget);
      expect(find.text('Tomar foto'), findsNothing);
      expect(find.textContaining('Actual: giro'), findsNothing);
      await tester.tap(find.text('Pausar captura'));
      expect(pauses, 1);
      expect(manualTakes, 0);
      await tester.pumpWidget(
        panel(automatic: true, paused: true, onTogglePause: () => pauses++),
      );
      expect(find.text('Continuar captura'), findsOneWidget);
      expect(find.textContaining('Captura en pausa'), findsOneWidget);
      await tester.tap(find.text('Continuar captura'));
      expect(pauses, 2);
    },
  );
  testWidgets('advanced automatic guide shows movement from the current pose', (
    tester,
  ) async {
    await tester.pumpWidget(
      panel(yaw: -40, pitch: -25, showAngles: true, automatic: true),
    );
    expect(find.textContaining('Inclina hacia arriba 25°'), findsOneWidget);
    expect(find.textContaining('Gira 40° a la derecha'), findsOneWidget);
    expect(find.textContaining('Actual: giro -40°'), findsOneWidget);
    expect(find.text('Tomar foto'), findsNothing);
    expect(find.text('Pausar captura'), findsOneWidget);
  });

  testWidgets('automatic guide still waits for stable recent sensors', (
    tester,
  ) async {
    await tester.pumpWidget(panel(automatic: true, aimed: true));
    expect(find.text('Mantén el teléfono estable un momento.'), findsOneWidget);
    expect(find.text('Tomar foto'), findsNothing);

    await tester.pumpWidget(
      panel(automatic: true, aimed: true, steady: true, fresh: false),
    );
    expect(find.textContaining('Esperando orientación'), findsOneWidget);
    expect(find.text('Pausar captura'), findsOneWidget);
  });

  for (final state in [
    (name: 'misaligned', fresh: true, aimed: false, steady: true, yaw: 120.0),
    (name: 'moving', fresh: true, aimed: true, steady: false, yaw: 0.0),
    (name: 'stale', fresh: false, aimed: true, steady: true, yaw: 0.0),
    (
      name: 'missing sensors',
      fresh: false,
      aimed: false,
      steady: false,
      yaw: double.nan,
    ),
  ]) {
    testWidgets('manual shutter works with ${state.name}', (tester) async {
      var takes = 0;
      await tester.pumpWidget(
        panel(
          target: const CaptureTarget('ceiling', 0, 90),
          fresh: state.fresh,
          aimed: state.aimed,
          steady: state.steady,
          yaw: state.yaw,
          pitch: state.fresh ? 0 : double.nan,
          paused: true,
          onTake: () => takes++,
        ),
      );
      expect(
        find.text('Gira despacio y toma fotos alrededor de ti.'),
        findsOneWidget,
      );
      expect(find.textContaining('Esperando'), findsNothing);
      expect(find.textContaining('Mantén'), findsNothing);
      expect(find.textContaining('°'), findsNothing);
      expect(find.byType(FilledButton), findsOneWidget);
      final shutter = find.text('Tomar foto');
      expect(shutter.hitTestable(), findsOneWidget);
      await tester.tap(shutter);
      expect(takes, 1);
    });
  }

  testWidgets('manual angle details are optional and never block the shutter', (
    tester,
  ) async {
    var takes = 0;
    await tester.pumpWidget(
      panel(yaw: -40, pitch: -25, showAngles: true, onTake: () => takes++),
    );
    expect(find.textContaining('Actual: giro -40°'), findsOneWidget);
    expect(
      find.text('Gira despacio y toma fotos alrededor de ti.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tomar foto'));
    expect(takes, 1);
  });

  testWidgets('manual camera needs no target and shows only measured angles', (
    tester,
  ) async {
    var takes = 0;
    await tester.pumpWidget(
      panel(
        target: null,
        yaw: 12,
        pitch: -8,
        showAngles: true,
        onTake: () => takes++,
      ),
    );
    expect(
      find.text('Gira despacio y toma fotos alrededor de ti.'),
      findsOneWidget,
    );
    expect(find.text('Actual: giro 12° · inclinación -8°'), findsOneWidget);
    expect(find.textContaining('Objetivo:'), findsNothing);
    await tester.tap(find.text('Tomar foto'));
    expect(takes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('automatic camera with no target stays simple and can pause', (
    tester,
  ) async {
    var pauses = 0;
    var takes = 0;
    await tester.pumpWidget(
      panel(
        target: null,
        automatic: true,
        fresh: false,
        yaw: double.nan,
        pitch: double.nan,
        showAngles: true,
        onTake: () => takes++,
        onTogglePause: () => pauses++,
      ),
    );
    expect(
      find.text('Mueve la cámara despacio alrededor de ti.'),
      findsOneWidget,
    );
    expect(find.textContaining('Objetivo:'), findsNothing);
    expect(find.textContaining('Actual:'), findsNothing);
    expect(find.text('Tomar foto'), findsNothing);
    await tester.tap(find.text('Pausar captura'));
    expect(pauses, 1);
    expect(takes, 0);
    expect(tester.takeException(), isNull);
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
    expect(find.text('Tomar foto').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Tomar foto'));
    expect(accepted, 1);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Tomar foto').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving disables manual shutter and prevents duplicate photos', (
    tester,
  ) async {
    var takes = 0;
    await tester.pumpWidget(
      panel(aimed: true, steady: true, busy: true, onTake: () => takes++),
    );
    expect(find.text('Guardando la toma…'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Tomar foto'));
    expect(takes, 0);
  });
}
