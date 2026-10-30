import 'dart:ui' show SemanticsAction, Tristate;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/theme/app_theme.dart';
import 'package:marea/features/shell/presentation/marea_mobile_navigation.dart';
import 'package:marea/shared/widgets/marea_panel.dart';

void main() {
  late ValueNotifier<String> route;
  late List<String> navigations;
  late List<MethodCall> feedback;

  setUp(() {
    route = ValueNotifier('/home');
    navigations = [];
    feedback = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') feedback.add(call);
          return null;
        });
  });
  tearDown(() {
    route.dispose();
    mareaOpenPanels.value = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> mount(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
    bool reduced = false,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduced,
          ),
          child: Scaffold(
            body: Column(
              children: [
                const Expanded(child: Text('Contenido estable')),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ValueListenableBuilder<String>(
                    valueListenable: route,
                    builder: (_, path, _) => MareaMobileNavigation(
                      location: path,
                      selectedDestination: MobileDestination.forLocation(path),
                      onSelected: (destination) {
                        navigations.add(destination.path);
                        route.value = destination.path;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder tab(String name) => find.byKey(ValueKey('mobile-tab-$name'));
  Finder getIndicator() => find.byKey(const Key('mobile-selection-indicator'));
  Offset center(WidgetTester tester) => tester.getCenter(getIndicator());

  testWidgets('indicator follows intermediate positions without navigating', (
    tester,
  ) async {
    await mount(tester);
    final original = center(tester);
    final gesture = await tester.startGesture(original + const Offset(8, 0));
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(center(tester).dx, closeTo(original.dx + 30, .01));
    await gesture.moveBy(const Offset(90, 0));
    await tester.pump();
    expect(center(tester).dx, closeTo(original.dx + 120, .01));
    expect(route.value, '/home');
    expect(navigations, isEmpty);
    expect(find.text('Contenido estable'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(feedback.length, 1);
    await gesture.moveBy(const Offset(2, 0));
    await tester.pump();
    expect(feedback.length, 1);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(center(tester), original);
    expect(navigations, isEmpty);
  });

  testWidgets('one drag reaches profile, clamps, then confirms after snap', (
    tester,
  ) async {
    await mount(tester);
    final gesture = await tester.startGesture(center(tester));
    await gesture.moveBy(const Offset(1000, 0));
    await tester.pump();
    expect(
      center(tester).dx,
      closeTo(tester.getCenter(tab('profile')).dx, .01),
    );
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    expect(route.value, '/home');
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(navigations, isEmpty);
    await tester.pumpAndSettle();
    expect(navigations, ['/profile']);
    expect(
      center(tester).dx,
      closeTo(tester.getCenter(tab('profile')).dx, .01),
    );
  });

  testWidgets('return to origin and cancel both avoid navigation', (
    tester,
  ) async {
    await mount(tester);
    final original = center(tester);
    final gesture = await tester.startGesture(original);
    await gesture.moveBy(const Offset(180, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-180, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(center(tester), original);
    expect(navigations, isEmpty);
  });

  testWidgets('tap and semantic activation use the same selection flow', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mount(tester);
    expect(
      tester.getSemantics(tab('home')).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    await tester.tap(tab('map'));
    await tester.pump();
    expect(route.value, '/home');
    expect(
      tester.getSemantics(tab('home')).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    await tester.pumpAndSettle();
    expect(route.value, '/map');
    expect(
      tester.getSemantics(tab('map')).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    final node = tester.getSemantics(tab('discover'));
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(navigations, ['/map', '/discover']);
    semantics.dispose();
  });

  testWidgets('external route supersedes drag and pending navigation', (
    tester,
  ) async {
    await mount(tester);
    final gesture = await tester.startGesture(center(tester));
    await gesture.moveBy(const Offset(160, 0));
    await tester.pump();
    route.value = '/profile';
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      center(tester).dx,
      closeTo(tester.getCenter(tab('profile')).dx, .01),
    );
    expect(navigations, isEmpty);
    await tester.tap(tab('map'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    route.value = '/discover';
    await tester.pumpAndSettle();
    expect(navigations, isEmpty);
    expect(
      center(tester).dx,
      closeTo(tester.getCenter(tab('discover')).dx, .01),
    );
  });

  testWidgets('cancelled contact during snap restores the confirmed route', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(tab('map'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final gesture = await tester.startGesture(center(tester));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(navigations, isEmpty);
    expect(center(tester).dx, closeTo(tester.getCenter(tab('home')).dx, .01));
  });

  testWidgets('swipe starting outside indicator during snap restores route', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(tab('map'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final gesture = await tester.startGesture(tester.getCenter(tab('profile')));
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(navigations, isEmpty);
    expect(center(tester).dx, closeTo(tester.getCenter(tab('home')).dx, .01));
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
  });

  testWidgets('rapid taps discard older confirmations', (tester) async {
    await mount(tester);
    await tester.tap(tab('map'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(tab('profile'));
    await tester.pumpAndSettle();
    expect(navigations, ['/profile']);
  });

  testWidgets('panel opening and lifecycle pause cancel pending selection', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(tab('map'));
    await tester.pump();
    mareaOpenPanels.value = 1;
    await tester.pumpAndSettle();
    expect(navigations, isEmpty);
    mareaOpenPanels.value = 0;
    await tester.tap(tab('profile'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(navigations, isEmpty);
    expect(center(tester).dx, closeTo(tester.getCenter(tab('home')).dx, .01));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('resize cancels pending selection', (tester) async {
    await mount(tester);
    await tester.tap(tab('map'));
    await tester.pump();
    tester.view.physicalSize = const Size(320, 844);
    await tester.pumpAndSettle();
    expect(navigations, isEmpty);
    expect(center(tester).dx, closeTo(tester.getCenter(tab('home')).dx, .01));
  });

  testWidgets('legacy paths highlight discover but tapping opens placeholder', (
    tester,
  ) async {
    route.value = '/explore?section=saved';
    await mount(tester);
    expect(
      center(tester).dx,
      closeTo(tester.getCenter(tab('discover')).dx, .01),
    );
    await tester.tap(tab('discover'));
    await tester.pumpAndSettle();
    expect(navigations, ['/discover']);
    route.value = '/missions';
    await tester.pumpAndSettle();
    expect(
      center(tester).dx,
      closeTo(tester.getCenter(tab('discover')).dx, .01),
    );
    route.value = '/create';
    await tester.pumpAndSettle();
    expect(getIndicator(), findsNothing);
    await tester.tap(tab('home'));
    await tester.pumpAndSettle();
    expect(route.value, '/home');
  });

  testWidgets('reduced motion confirms without waiting for snap', (
    tester,
  ) async {
    await mount(tester, reduced: true);
    await tester.tap(tab('profile'));
    await tester.pump();
    expect(route.value, '/profile');
    expect(
      center(tester).dx,
      closeTo(tester.getCenter(tab('profile')).dx, .01),
    );
  });

  for (final width in [320.0, 360.0, 390.0, 599.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('labels and touch targets fit $width at scale $scale', (
        tester,
      ) async {
        await mount(tester, width: width, scale: scale);
        for (final name in ['home', 'discover', 'map', 'profile']) {
          final rect = tester.getRect(tab(name));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(tab(name).hitTestable(), findsOneWidget);
        }
        for (final label in ['Inicio', 'Descubrir', 'Mapa', 'Perfil']) {
          expect(find.text(label).hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
