import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/router/app_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/data/social_repository.dart';
import 'package:marea/core/theme/app_theme.dart';
import '../../support/fakes.dart';

class Social implements SocialRepository {
  @override
  Stream<void> changes(String id) => const Stream.empty();
  @override
  Future<int> unreadCount() async => 0;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  for (final width in [390.0, 600.0, 1440.0]) {
    testWidgets('header tools remain accessible outside nested route $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final controller = AppSessionController(
        authRepository: FakeAuthRepository(),
        profileRepository: FakeProfileRepository(),
        socialRepository: Social(),
      );
      await controller.initialize();
      addTearDown(controller.dispose);
      final router = AppRouter.create(controller);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Guardados'), findsOneWidget);
      expect(find.bySemanticsLabel('Notificaciones'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
