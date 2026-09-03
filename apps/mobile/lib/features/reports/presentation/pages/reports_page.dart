import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/reports_bloc.dart';
import '../../utils/export_service.dart';
import '../../domain/models/report_summary.dart';

class ReportsPage extends StatelessWidget {
  final String businessId;
  const ReportsPage({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('reports.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'reports.export_pdf'.tr(),
            onPressed: () {
              final state = context.read<ReportsBloc>().state;
              if (state is ReportsLoaded) {
                HapticFeedback.lightImpact();
                _showExportOptions(context, state);
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          if (state is ReportsInitial || state is ReportsLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (state is ReportsLoaded) {
            final summary = state.summary;
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildPeriodSelector(context, state.period),
                const SizedBox(height: 16),
                _buildSummaryCards(context, summary),
                const SizedBox(height: 24),
                _buildIncomeExpenseRatio(summary),
                const SizedBox(height: 28),

                // Expense Breakdown
                Text(
                  'reports.expense_breakdown'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 12),
                if (summary.expenseCategories.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'لا توجد مصروفات في هذه الفترة',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  )
                else
                  ...summary.expenseCategories.map((c) => _buildCategoryRow(
                        name: c.categoryName,
                        amount: c.totalAmount,
                        total: summary.totalExpense,
                        color: AppTheme.expense,
                      )),

                const SizedBox(height: 28),

                // Income Breakdown
                Text(
                  'reports.income_breakdown'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 12),
                if (summary.incomeCategories.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'لا توجد إيرادات في هذه الفترة',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  )
                else
                  ...summary.incomeCategories.map((c) => _buildCategoryRow(
                        name: c.categoryName,
                        amount: c.totalAmount,
                        total: summary.totalIncome,
                        color: AppTheme.income,
                      )),
                const SizedBox(height: 32),
              ],
            );
          }

          if (state is ReportsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error: ${state.message}', style: const TextStyle(color: AppTheme.expense)),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, ReportPeriod currentPeriod) {
    return SegmentedButton<ReportPeriod>(
      segments: [
        ButtonSegment(
          value: ReportPeriod.thisWeek,
          label: Text('reports.period_week'.tr()),
        ),
        ButtonSegment(
          value: ReportPeriod.thisMonth,
          label: Text('reports.period_month'.tr()),
        ),
        ButtonSegment(
          value: ReportPeriod.custom,
          label: Text('reports.period_custom'.tr()),
        ),
      ],
      selected: {currentPeriod},
      onSelectionChanged: (set) {
        HapticFeedback.selectionClick();
        final period = set.first;
        if (period == ReportPeriod.custom) {
          _selectCustomDateRange(context);
        } else {
          context.read<ReportsBloc>().add(LoadReport(businessId: businessId, period: period));
        }
      },
    );
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null && context.mounted) {
      context.read<ReportsBloc>().add(LoadReport(
        businessId: businessId,
        period: ReportPeriod.custom,
        customStartDate: picked.start,
        customEndDate: picked.end,
      ));
    }
  }

  Widget _buildSummaryCards(BuildContext context, ReportSummary summary) {
    String? compareText;
    if (summary.previousPeriodTotalExpense != null && summary.previousPeriodTotalExpense! > 0) {
      final diff = summary.totalExpense - summary.previousPeriodTotalExpense!;
      final pct = (diff / summary.previousPeriodTotalExpense!) * 100;
      final sign = pct > 0 ? '+' : '';
      compareText = '$sign${pct.toStringAsFixed(1)}% vs previous';
    }

    final isProfit = summary.net >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        children: [
          // Net Profit / Loss Highlight
          Text(
            'reports.net'.tr(),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            '${summary.net.toStringAsFixed(2)} ج.م',
            style: TextStyle(
              color: isProfit ? AppTheme.income : AppTheme.expense,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (compareText != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                compareText,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(color: AppTheme.surfaceLight),
          const SizedBox(height: 16),

          // Side-by-side Income & Expense
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.income,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'reports.income'.tr(),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.totalIncome.toStringAsFixed(2)} ج.م',
                      style: const TextStyle(
                        color: AppTheme.income,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.expense,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'reports.expenses'.tr(),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.totalExpense.toStringAsFixed(2)} ج.م',
                      style: const TextStyle(
                        color: AppTheme.expense,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseRatio(ReportSummary summary) {
    final total = summary.totalIncome + summary.totalExpense;
    if (total == 0) return const SizedBox.shrink();

    final incomeRatio = summary.totalIncome / total;
    final expenseRatio = summary.totalExpense / total;

    return Container(
      height: 10,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            flex: (incomeRatio * 100).toInt().clamp(1, 100),
            child: Container(color: AppTheme.income),
          ),
          Expanded(
            flex: (expenseRatio * 100).toInt().clamp(1, 100),
            child: Container(color: AppTheme.expense),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow({
    required String name,
    required double amount,
    required double total,
    required Color color,
  }) {
    final ratio = total > 0 ? (amount / total) : 0.0;
    final pct = (ratio * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                '${amount.toStringAsFixed(2)} ج.م ($pct%)',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: AppTheme.surfaceLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context, ReportsLoaded state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'reports.export_pdf'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.expense.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.expense),
                ),
                title: Text('reports.export_pdf'.tr(), style: const TextStyle(color: AppTheme.text)),
                subtitle: const Text('تقرير منسق ومجهز للمشاركة مع المحاسب', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                onTap: () async {
                  HapticFeedback.selectionClick();
                  Navigator.of(bContext).pop();
                  await ExportService.exportPdf(state);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.income.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.table_chart_rounded, color: AppTheme.income),
                ),
                title: Text('reports.export_csv'.tr(), style: const TextStyle(color: AppTheme.text)),
                subtitle: const Text('ملف بيانات خام يدعم برامج Excel والجداول', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                onTap: () async {
                  HapticFeedback.selectionClick();
                  Navigator.of(bContext).pop();
                  await ExportService.exportCsv(state);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
