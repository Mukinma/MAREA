import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../../support/fakes.dart';
import '../../support/mission_repository_fake.dart';
import 'missions_screen_test.dart' as flow;

void main() {
  testWidgets('compatible filter includes open calls for the viewer type', (
    tester,
  ) async {
    final repo = MissionRepositoryFake();
    await flow.openRoute(tester, repo, '/missions');
    await flow.tapVisible(tester, find.text('Para mi perfil'));
    expect(repo.lastTarget, sampleProfile.userType);
    await flow.tapVisible(tester, find.text('Todas'));
    expect(repo.lastTarget, isNull);
  });

  testWidgets('section links update an already mounted missions screen', (
    tester,
  ) async {
    final repo = MissionRepositoryFake();
    final router = await flow.openRoute(tester, repo, '/missions');
    router.go('/missions?section=own');
    await tester.pumpAndSettle();
    expect(repo.lastScope, 'active');
    router.go('/missions?section=applications');
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(
      find.text('Tus postulaciones y sus respuestas aparecerán aquí.'),
      findsOneWidget,
    );
  });

  testWidgets('application filters show only the selected response status', (
    tester,
  ) async {
    final accepted = application(
      applicant: sampleProfile.id,
      status: 'accepted',
    );
    final pending = application(applicant: sampleProfile.id);
    final repo = MissionRepositoryFake()..requests = [accepted, pending];
    await flow.openRoute(tester, repo, '/missions?section=applications');
    await flow.tapVisible(tester, find.text('Aceptadas'));
    expect(find.textContaining('Postulación aceptada'), findsOneWidget);
    expect(find.textContaining('Postulación pendiente'), findsNothing);
    await flow.tapVisible(tester, find.text('Pendientes'));
    expect(find.textContaining('Postulación aceptada'), findsNothing);
    expect(find.textContaining('Postulación pendiente'), findsOneWidget);
  });

  for (final scenario in [
    (missionFixture(accepted: 2), 'Esta misión ya alcanzó su cupo.'),
    (missionFixture(status: 'closed'), 'El organizador cerró la convocatoria.'),
    (missionFixture(past: true), 'La fecha de esta convocatoria ya pasó.'),
    (
      missionFixture(target: UserType.business),
      'Esta misión busca Negocio. Tu perfil es Artista / creador.',
    ),
  ]) {
    testWidgets(
      'unavailable participation explains ${scenario.$1.statusLabel}',
      (tester) async {
        await flow.openRoute(
          tester,
          MissionRepositoryFake()..value = scenario.$1,
          '/missions/mission-1',
        );
        expect(find.text('Postularme'), findsNothing);
        expect(find.text(scenario.$2), findsOneWidget);
      },
    );
  }
}
