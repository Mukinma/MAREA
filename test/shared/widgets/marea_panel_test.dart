import 'package:flutter/material.dart';
import 'package:marea/shared/widgets/marea_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/community/presentation/social_panels.dart';
import 'package:marea/features/shell/presentation/app_shell.dart';
import '../../support/test_app.dart';

void main() {
  testWidgets('disposing a navigator with an open panel releases suppression', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showMareaBottomSheet(
              context: context,
              builder: (_) => const Text('Sheet'),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(mareaOpenPanels.value, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(mareaOpenPanels.value, 0);
  });

  testWidgets('nested panels retain dock suppression through exit and back', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMareaBottomSheet(
                context: context,
                builder: (context) => TextButton(
                  onPressed: () => showMareaBottomSheet(
                    context: context,
                    builder: (_) => const Text('Nested'),
                  ),
                  child: const Text('Nest'),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(mareaOpenPanels.value, 1);
    await tester.tap(find.text('Nest'));
    await tester.pumpAndSettle();
    expect(mareaOpenPanels.value, 2);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pop();
    await tester.pump(const Duration(milliseconds: 50));
    expect(mareaOpenPanels.value, 2);
    await tester.pumpAndSettle();
    expect(mareaOpenPanels.value, 1);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(mareaOpenPanels.value, 0);
  });

  testWidgets(
    'bottom panels hide the dock without moving content and restore it',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        testApp(
          AppShell(
            location: '/home',
            child: Builder(
              builder: (context) => Column(
                children: [
                  const Text('Content marker'),
                  TextButton(
                    onPressed: () => showSocialPanel(
                      context,
                      const SocialPanelFrame(
                        title: 'Comments',
                        child: Text('Panel content'),
                      ),
                    ),
                    child: const Text('Open panel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final before = tester.getTopLeft(find.text('Content marker'));
      await tester.tap(find.text('Open panel'));
      await tester.pumpAndSettle();
      final dock = find.byKey(const Key('mobile-dock'));
      final opacity = tester.widget<AnimatedOpacity>(
        find.ancestor(of: dock, matching: find.byType(AnimatedOpacity)).first,
      );
      expect(opacity.opacity, 0);
      expect(tester.getTopLeft(find.text('Content marker')), before);
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedOpacity>(
              find
                  .ancestor(of: dock, matching: find.byType(AnimatedOpacity))
                  .first,
            )
            .opacity,
        1,
      );
      expect(tester.getTopLeft(find.text('Content marker')), before);
    },
  );
}
