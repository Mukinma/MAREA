import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/proximity/application/proximity_controller.dart';
import 'package:marea/features/proximity/data/local_proximity_notifications.dart';
import 'package:marea/features/proximity/models/proximity_models.dart';
import 'package:marea/features/proximity/presentation/foreground_proximity.dart';
import 'package:marea/features/proximity/presentation/proximity_settings_screen.dart';

import 'proximity_controller_test.dart' show LocationFake, TargetsFake;
import 'proximity_fixture.dart';

void main() {
  for (final kind in ProximityTargetKind.values) {
    testWidgets('visible opt-in shows a live actionable ${kind.name} notice', (
      tester,
    ) async {
      final location = LocationFake();
      final targets = TargetsFake()..items = [target(kind: kind)];
      final notices = ForegroundProximityNotices(
        claim: (_, _, _) async => true,
      );
      final controller = ProximityController(
        location: location,
        targets: targets,
        notifications: notices,
        now: () => testTime,
      );
      await controller.setForeground(true);
      await controller.setAccount(accountA);
      ProximityNotificationPayload? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ForegroundProximitySettings(
                  monitor: controller,
                  account: accountA,
                  supported: true,
                ),
                ForegroundProximityBanner(
                  notices: notices,
                  open: (notice) => opened = notice,
                ),
              ],
            ),
          ),
        ),
      );
      expect(location.prompts, isEmpty);
      await tester.tap(find.text('Activar avisos'));
      await tester.pumpAndSettle();
      expect(location.prompts, [true]);
      location.positions.add(fix());
      await tester.pumpAndSettle();
      expect(find.textContaining('Lugar de prueba'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
        findsWidgets,
      );
      await tester.tap(
        find.text(
          kind == ProximityTargetKind.mission ? 'Ver misión' : 'Ver marcador',
        ),
      );
      await tester.pumpAndSettle();
      expect(opened?.recipientId, accountA);
      expect(opened?.route, targets.items.single.route);
      expect(find.textContaining('Lugar de prueba'), findsNothing);
      await tester.tap(find.text('Detener avisos'));
      await tester.pumpAndSettle();
      expect(controller.running, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      notices.dispose();
      await location.positions.close();
    });
  }

  test(
    'late cross-tab claim and blocked duplicate cannot show a stale alert',
    () async {
      final claim = Completer<bool>();
      final notices = ForegroundProximityNotices(
        claim: (_, _, _) => claim.future,
      );
      var current = true;
      final work = notices.present(
        encounter(),
        accountId: accountA,
        isCurrent: () => current,
      );
      current = false;
      claim.complete(true);
      await work;
      expect(notices.current, isNull);
      final duplicate = ForegroundProximityNotices(
        claim: (_, _, _) async => false,
      );
      await duplicate.present(
        encounter(),
        accountId: accountA,
        isCurrent: () => true,
      );
      expect(duplicate.current, isNull);
      notices.dispose();
      duplicate.dispose();
    },
  );
}
