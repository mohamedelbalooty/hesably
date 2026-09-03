import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import '../presentation/bloc/reports_bloc.dart';

class ExportService {
  static Future<void> exportPdf(ReportsLoaded state) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Hesably Financial Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Period: ${state.startDate.toString().split(' ').first} to ${state.endDate.toString().split(' ').first}'),
            pw.SizedBox(height: 24),
            pw.Text('Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Income:'),
                pw.Text(state.summary.totalIncome.toStringAsFixed(2)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Expenses:'),
                pw.Text(state.summary.totalExpense.toStringAsFixed(2)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Net:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(state.summary.net.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Text('Expense Category Breakdown', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            ...state.summary.expenseCategories.map((c) => pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(c.categoryName),
                pw.Text(c.totalAmount.toStringAsFixed(2)),
              ],
            )),
            pw.SizedBox(height: 24),
            pw.Text('Income Category Breakdown', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            ...state.summary.incomeCategories.map((c) => pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(c.categoryName),
                pw.Text(c.totalAmount.toStringAsFixed(2)),
              ],
            )),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/hesably_report.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'Hesably Financial Report');
  }

  static Future<void> exportCsv(ReportsLoaded state) async {
    List<List<dynamic>> rows = [];
    rows.add(['Hesably Financial Report']);
    rows.add(['Period', '${state.startDate.toString().split(' ').first} to ${state.endDate.toString().split(' ').first}']);
    rows.add([]);
    rows.add(['Summary']);
    rows.add(['Total Income', state.summary.totalIncome.toStringAsFixed(2)]);
    rows.add(['Total Expenses', state.summary.totalExpense.toStringAsFixed(2)]);
    rows.add(['Net', state.summary.net.toStringAsFixed(2)]);
    rows.add([]);
    rows.add(['Expense Category Breakdown']);
    rows.add(['Category Name', 'Total Amount']);
    
    for (var c in state.summary.expenseCategories) {
      rows.add([c.categoryName, c.totalAmount.toStringAsFixed(2)]);
    }

    rows.add([]);
    rows.add(['Income Category Breakdown']);
    rows.add(['Category Name', 'Total Amount']);
    
    for (var c in state.summary.incomeCategories) {
      rows.add([c.categoryName, c.totalAmount.toStringAsFixed(2)]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/hesably_report.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(file.path)], text: 'Hesably Financial Report CSV');
  }
}
