import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              final state = context.read<ReportsBloc>().state;
              if (state is ReportsLoaded) {
                _showExportOptions(context, state);
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          if (state is ReportsInitial || state is ReportsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is ReportsLoaded) {
            final summary = state.summary;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPeriodSelector(context, state.period),
                const SizedBox(height: 16),
                _buildSummaryCard(context, summary, state),
                const SizedBox(height: 24),
                const Text('Expense Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (summary.expenseCategories.isEmpty)
                  const Text('No expenses in this period.'),
                ...summary.expenseCategories.map((c) => ListTile(
                  title: Text(c.categoryName),
                  trailing: Text(c.totalAmount.toStringAsFixed(2), style: const TextStyle(color: Colors.red)),
                )),
                const SizedBox(height: 24),
                const Text('Income Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (summary.incomeCategories.isEmpty)
                  const Text('No income in this period.'),
                ...summary.incomeCategories.map((c) => ListTile(
                  title: Text(c.categoryName),
                  trailing: Text(c.totalAmount.toStringAsFixed(2), style: const TextStyle(color: Colors.green)),
                )),
              ],
            );
          }
          
          if (state is ReportsError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, ReportPeriod currentPeriod) {
    return SegmentedButton<ReportPeriod>(
      segments: const [
        ButtonSegment(value: ReportPeriod.thisWeek, label: Text('Week')),
        ButtonSegment(value: ReportPeriod.thisMonth, label: Text('Month')),
        ButtonSegment(value: ReportPeriod.custom, label: Text('Custom')),
      ],
      selected: {currentPeriod},
      onSelectionChanged: (set) {
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
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      if (context.mounted) {
        context.read<ReportsBloc>().add(LoadReport(
          businessId: businessId,
          period: ReportPeriod.custom,
          customStartDate: picked.start,
          customEndDate: picked.end,
        ));
      }
    }
  }

  Widget _buildSummaryCard(BuildContext context, ReportSummary summary, ReportsLoaded state) {
    String? compareText;
    if (summary.previousPeriodTotalExpense != null && summary.previousPeriodTotalExpense! > 0) {
      final diff = summary.totalExpense - summary.previousPeriodTotalExpense!;
      final pct = (diff / summary.previousPeriodTotalExpense!) * 100;
      final sign = pct > 0 ? '+' : '';
      compareText = '$sign${pct.toStringAsFixed(1)}% vs previous period';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Income'),
                Text(summary.totalIncome.toStringAsFixed(2), style: const TextStyle(color: Colors.green)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Expenses'),
                Text(summary.totalExpense.toStringAsFixed(2), style: const TextStyle(color: Colors.red)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(summary.net.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (compareText != null) ...[
              const SizedBox(height: 8),
              Text(compareText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]
          ],
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context, ReportsLoaded state) {
    showModalBottomSheet(
      context: context,
      builder: (bContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () async {
                Navigator.of(bContext).pop();
                await ExportService.exportPdf(state);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              onTap: () async {
                Navigator.of(bContext).pop();
                await ExportService.exportCsv(state);
              },
            ),
          ],
        ),
      ),
    );
  }
}
