import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/auth/data/mobile_intro_store.dart';
import 'package:marea/features/auth/presentation/welcome_entry_screen.dart';
import '../../support/test_app.dart';

class _NeverLoadedStore implements MobileIntroStore {
  @override
  Future<bool> hasSeenIntro() => Completer<bool>().future;
  @override
  Future<void> markSeenIntro() async =>
      throw StateError('Web does not complete intro');
}

void main() {
  testWidgets(
    'web shows access immediately even when the browser reports a mobile platform',
    (tester) async {
      await tester.pumpWidget(
        testApp(WelcomeEntryScreen(store: _NeverLoadedStore())),
      );
      await tester.pump();
      expect(find.byKey(const Key('welcome-register')), findsOneWidget);
      expect(find.byKey(const Key('welcome-login')), findsOneWidget);
      expect(find.byKey(const Key('mobile-intro')), findsNothing);
    },
    skip: !kIsWeb,
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );
}
