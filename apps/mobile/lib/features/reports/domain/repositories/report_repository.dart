import '../models/report_summary.dart';

abstract class ReportRepository {
  Future<ReportSummary> getReportSummary({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
    required bool includePreviousPeriod,
  });
}
