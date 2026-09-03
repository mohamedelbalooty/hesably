import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/report_summary.dart';
import '../../domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final SupabaseClient _supabase;

  ReportRepositoryImpl(this._supabase);

  @override
  Future<ReportSummary> getReportSummary({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
    required bool includePreviousPeriod,
  }) async {
    final startStr = startDate.toIso8601String().split('T').first;
    final endStr = endDate.toIso8601String().split('T').first;

    // Fetch main period summary
    final summaryRes = await _supabase.rpc('get_financial_summary', params: {
      'p_business_id': businessId,
      'p_start_date': startStr,
      'p_end_date': endStr,
    }) as List;
    
    // Fetch categories
    final expenseCatsRes = await _supabase.rpc('get_category_breakdown', params: {
      'p_business_id': businessId,
      'p_start_date': startStr,
      'p_end_date': endStr,
      'p_type': 'expense',
    }) as List;

    final incomeCatsRes = await _supabase.rpc('get_category_breakdown', params: {
      'p_business_id': businessId,
      'p_start_date': startStr,
      'p_end_date': endStr,
      'p_type': 'income',
    }) as List;

    double? prevIncome;
    double? prevExpense;

    if (includePreviousPeriod) {
      final diff = endDate.difference(startDate).inDays + 1;
      final prevEnd = startDate.subtract(const Duration(days: 1));
      final prevStart = prevEnd.subtract(Duration(days: diff - 1));
      
      final prevStartStr = prevStart.toIso8601String().split('T').first;
      final prevEndStr = prevEnd.toIso8601String().split('T').first;
      
      final prevSummaryRes = await _supabase.rpc('get_financial_summary', params: {
        'p_business_id': businessId,
        'p_start_date': prevStartStr,
        'p_end_date': prevEndStr,
      }) as List;
      
      if (prevSummaryRes.isNotEmpty) {
         prevIncome = (prevSummaryRes[0]['total_income'] as num).toDouble();
         prevExpense = (prevSummaryRes[0]['total_expense'] as num).toDouble();
      }
    }

    final expenseCategories = expenseCatsRes.map((e) => CategorySummary(
      categoryId: e['category_id'] as String,
      categoryName: e['category_name'] as String,
      totalAmount: (e['total_amount'] as num).toDouble(),
    )).toList();

    final incomeCategories = incomeCatsRes.map((e) => CategorySummary(
      categoryId: e['category_id'] as String,
      categoryName: e['category_name'] as String,
      totalAmount: (e['total_amount'] as num).toDouble(),
    )).toList();

    return ReportSummary(
      totalIncome: summaryRes.isNotEmpty ? (summaryRes[0]['total_income'] as num).toDouble() : 0,
      totalExpense: summaryRes.isNotEmpty ? (summaryRes[0]['total_expense'] as num).toDouble() : 0,
      net: summaryRes.isNotEmpty ? (summaryRes[0]['net'] as num).toDouble() : 0,
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
      previousPeriodTotalIncome: prevIncome,
      previousPeriodTotalExpense: prevExpense,
    );
  }
}
