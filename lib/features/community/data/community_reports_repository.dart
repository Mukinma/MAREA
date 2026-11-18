import 'package:marea/features/community/models/report_receipt.dart';

abstract interface class CommunityReportsRepository {
  static const pageSize = 30;

  Future<void> reportAccount(String profileId, String reason);
  Future<List<ReportReceipt>> myReports({int offset = 0});
  Future<List<ReportedAccount>> accountReports({int offset = 0});
  Future<void> markReportReviewed(String id, {required bool account});
}
