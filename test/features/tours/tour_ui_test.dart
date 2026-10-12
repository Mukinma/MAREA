import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/tours/data/tour_repository.dart';
import 'package:marea/features/tours/models/tour_models.dart';
import 'package:marea/features/tours/presentation/tour_management_screen.dart';
import '../../support/fakes.dart';

class TourFake implements TourRepository {
  @override
  Future<List<TourRecord>> list({
    String? owner,
    double? latitude,
    double? longitude,
  }) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('un enlace directo a administración tiene salida al perfil', (
    tester,
  ) async {
    final controller = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: FakeProfileRepository(),
      tourRepository: TourFake(),
    );
    final router = GoRouter(
      initialLocation: '/tours',
      routes: [
        GoRoute(
          path: '/tours',
          builder: (_, _) => TourManagementScreen(controller: controller),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, _) => const Scaffold(body: Text('Perfil de regreso')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Perfil de regreso'), findsOneWidget);
    router.dispose();
    controller.dispose();
  });
  testWidgets(
    'administración vacía ofrece salida, creación y solicitudes con texto ampliado',
    (tester) async {
      final controller = AppSessionController(
        authRepository: FakeAuthRepository(),
        profileRepository: FakeProfileRepository(),
        tourRepository: TourFake(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2),
            ),
            child: TourManagementScreen(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tus recorridos'), findsOneWidget);
      expect(find.text('Solicitudes y revisión'), findsOneWidget);
      expect(tester.takeException(), isNull);
      controller.dispose();
    },
  );
}
