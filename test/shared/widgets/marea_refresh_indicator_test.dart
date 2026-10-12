import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:marea/shared/widgets/marea_refresh_indicator.dart';

void main() {
  testWidgets('refresh retains the list and uses linear progress', (
    tester,
  ) async {
    final pending = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MareaRefreshIndicator(
            onRefresh: () => pending.future,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [Text('Existing content')],
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Existing content'), findsOneWidget);
    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    pending.complete();
    await tester.pumpAndSettle();
  });
  test('refresh scrolling accepts touch and mouse dragging', () {
    final devices = MareaRefreshScrollBehavior().dragDevices;

    expect(devices, contains(PointerDeviceKind.touch));
    expect(devices, contains(PointerDeviceKind.mouse));
    expect(devices, contains(PointerDeviceKind.trackpad));
  });
}
