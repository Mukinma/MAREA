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

class ReloadTourFake extends TourFake {
  bool failList = false, failRequests = false;
  int loads = 0, requestLoads = 0;
  String title = 'Recorrido inicial';
  @override
  Future<List<TourRecord>> list({
    String? owner,
    double? latitude,
    double? longitude,
  }) async {
    loads++;
    if (failList && loads == 1) throw StateError('Consulta interrumpida');
    return [
      TourRecord({
        'id': 'tour',
        'owner_id': sampleProfile.id,
        'title': title,
        'state': 'draft',
      }),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> requests() async {
    requestLoads++;
    if (failRequests && requestLoads == 1) {
      throw StateError('Consulta interrumpida');
    }
    return [];
  }
}

void main() {
  testWidgets(
    'retrying a failed tour list starts a new lookup without an async setState',
    (tester) async {
      final repo = ReloadTourFake()..failList = true;
      final controller = AppSessionController(
        authRepository: FakeAuthRepository(),
        profileRepository: FakeProfileRepository(),
        tourRepository: repo,
      );
      await tester.pumpWidget(
        MaterialApp(home: TourManagementScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(repo.loads, 2);
      expect(find.text('Recorrido inicial'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
  testWidgets('returning from an editor reloads the owned tour list', (
    tester,
  ) async {
    final repo = ReloadTourFake();
    final controller = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: FakeProfileRepository(),
      tourRepository: repo,
    );
    final router = GoRouter(
      initialLocation: '/tours',
      routes: [
        GoRoute(
          path: '/tours',
          builder: (_, _) => TourManagementScreen(controller: controller),
        ),
        GoRoute(
          path: '/tours/:id/edit',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () {
                repo.title = 'Recorrido actualizado';
                context.pop();
              },
              child: const Text('Regresar al listado'),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar borrador'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Regresar al listado'));
    await tester.pumpAndSettle();
    expect(repo.loads, 2);
    expect(find.text('Recorrido actualizado'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    controller.dispose();
  });
  testWidgets('request-list errors can be retried without an async setState', (
    tester,
  ) async {
    final repo = ReloadTourFake()..failRequests = true;
    final controller = AppSessionController(
      authRepository: FakeAuthRepository(),
      profileRepository: FakeProfileRepository(),
      tourRepository: repo,
    );
    await tester.pumpWidget(
      MaterialApp(home: TourRequestsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(repo.requestLoads, 2);
    expect(find.text('No hay solicitudes pendientes.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
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
