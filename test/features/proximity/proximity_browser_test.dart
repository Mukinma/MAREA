@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/proximity/data/proximity_browser.dart';

import 'proximity_fixture.dart';

void main() {
  test(
    'same-origin claims serialize and expire per account and destination',
    () async {
      clearBrowserAlerts(accountA);
      clearBrowserAlerts(accountB);
      addTearDown(() {
        clearBrowserAlerts(accountA);
        clearBrowserAlerts(accountB);
      });
      expect(browserLocationSupported, isTrue);
      expect(proximityPageVisible, isTrue);
      final claims = await Future.wait([
        claimBrowserAlert(accountA, targetId, testTime),
        claimBrowserAlert(accountA, targetId, testTime),
      ]);
      expect(claims.where((value) => value), hasLength(1));
      expect(await claimBrowserAlert(accountB, targetId, testTime), isTrue);
      expect(
        await claimBrowserAlert(
          accountA,
          targetId,
          testTime.add(const Duration(minutes: 5)),
        ),
        isTrue,
      );
    },
  );
}
