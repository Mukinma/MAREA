import 'dart:async';
import 'package:flutter/material.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/shared/widgets/primary_button.dart';
import 'package:marea/shared/widgets/marea_skeleton.dart';
import '../../support/test_app.dart';

void main() {
  testWidgets(
    'refresh retains loaded content while pending and after failure',
    (tester) async {
      Completer<String>? pending;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: CommunityLoad<String>(
              load: () async =>
                  pending == null ? 'Contenido anterior' : pending.future,
              builder: (value, reload) => Column(
                children: [
                  Text(value),
                  TextButton(
                    onPressed: reload,
                    child: const Text('Actualizar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      pending = Completer<String>();
      await tester.tap(find.text('Actualizar'));
      await tester.pump();
      expect(find.text('Contenido anterior'), findsOneWidget);
      expect(find.byType(MareaSkeleton), findsNothing);
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Contenido anterior'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byType(MareaSkeleton), findsNothing);
    },
  );

  for (final size in [
    const Size(28, 28),
    const Size(100, 80),
    const Size(320, 200),
    const Size(320, 250),
  ]) {
    for (final kind in SkeletonKind.values) {
      testWidgets('skeleton $kind fits $size with reduced motion', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(
          testApp(
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Center(
                child: SizedBox.fromSize(
                  size: size,
                  child: MareaSkeleton(kind: kind),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel('Cargando contenido'), findsOneWidget);
        expect(tester.binding.hasScheduledFrame, false);
        semantics.dispose();
      });
    }
  }

  testWidgets('busy action retains a readable label without a spinner', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: PrimaryButton(
            label: 'Guardar',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.text('Guardando…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
