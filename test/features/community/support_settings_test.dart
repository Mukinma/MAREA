import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/data/community_reports_repository.dart';
import 'package:marea/features/community/models/report_receipt.dart';
import 'package:marea/features/community/presentation/support_settings_screen.dart';

import '../../support/fakes.dart';
import '../../support/mission_repository_fake.dart';
import '../../support/test_app.dart';

void main() {
  testWidgets(
    'report history keeps reviewed and removed receipts at 200% text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final auth = FakeAuthRepository();
      final repository = _ReportRepository();
      final controller = AppSessionController(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
        legalRepository: FakeLegalRepository(),
        communityRepository: repository,
      );
      addTearDown(auth.close);
      addTearDown(controller.dispose);
      await controller.initialize();
      await tester.pumpWidget(
        testApp(UserReportsScreen(controller: controller)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mis reportes'), findsOneWidget);
      expect(find.text('Cuenta'), findsOneWidget);
      expect(find.textContaining('Revisado'), findsOneWidget);
      expect(find.text('Misión'), findsOneWidget);
      expect(find.textContaining('Contenido no disponible'), findsOneWidget);
      expect(repository.requestedOffsets, [0]);
      expect(tester.takeException(), isNull);
    },
  );
}

class _ReportRepository extends MissionRepositoryFake
    implements CommunityReportsRepository {
  final requestedOffsets = <int>[];

  @override
  Future<List<ReportReceipt>> myReports({int offset = 0}) async {
    requestedOffsets.add(offset);
    return [
      ReportReceipt(
        id: 'one',
        target: ReportTarget.account,
        createdAt: DateTime.utc(2026),
        reviewed: true,
      ),
      ReportReceipt(
        id: 'two',
        target: ReportTarget.mission,
        createdAt: DateTime.utc(2026),
        reviewed: false,
        targetUnavailable: true,
      ),
    ];
  }

  @override
  Future<List<ReportedAccount>> accountReports({int offset = 0}) async => [];

  @override
  Future<void> markReportReviewed(String id, {required bool account}) async {}

  @override
  Future<void> reportAccount(String profileId, String reason) async {}
}
