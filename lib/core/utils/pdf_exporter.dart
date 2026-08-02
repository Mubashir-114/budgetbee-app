import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../models/report_models.dart';

class PdfExporter {
  PdfExporter._();

  static Future<String> generateReport({
    required ReportSummary summary,
    required List<CategoryReport> categoryReports,
    required List<CashflowReport> cashflowReports,
    required String dateRangeStr,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "FINANCE REPORT",
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex("#4F46E5"),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text("Period: $dateRangeStr", style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Personal Finance Manager", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text("Generated on: ${DateTime.now().toString().split(' ')[0]}", style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1.0, color: PdfColor.fromHex("#E2E8F0")),
            pw.SizedBox(height: 16),

            // Summary Section
            pw.Text("Financial Summary", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 0.28,
              children: [
                _buildSummaryBox("Total Income", "\$${summary.totalIncome.toStringAsFixed(2)}", PdfColor.fromHex("#10B981")),
                _buildSummaryBox("Total Expense", "\$${summary.totalExpense.toStringAsFixed(2)}", PdfColor.fromHex("#F43F5E")),
                _buildSummaryBox("Net Savings", "\$${summary.netBalance.toStringAsFixed(2)}", PdfColor.fromHex("#3B82F6")),
                _buildSummaryBox("Savings Rate", "${summary.savingsRate.toStringAsFixed(1)}%", PdfColor.fromHex("#F59E0B")),
              ],
            ),
            pw.SizedBox(height: 24),

            // Category Breakdown Table
            pw.Text("Category-wise Breakdown", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ["Category", "Budget Limit", "Spent Amount", "Remaining", "Usage %"],
              data: categoryReports.map((c) => [
                c.category,
                c.budget == 0 ? "No Limit" : "\$${c.budget.toStringAsFixed(2)}",
                "\$${c.spent.toStringAsFixed(2)}",
                c.budget == 0 ? "-" : "\$${c.remaining.toStringAsFixed(2)}",
                c.budget == 0 ? "-" : "${c.percentage.toStringAsFixed(1)}%",
              ]).toList(),
              border: pw.TableBorder.all(color: PdfColor.fromHex("#E2E8F0"), width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex("#4F46E5")),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 24),

            // Cashflow Ledger Table
            pw.Text("Recent Transactions Ledger", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ["Date", "Title", "Category", "Type", "Amount", "Balance"],
              data: cashflowReports.take(15).map((c) => [
                c.date,
                c.title,
                c.category,
                c.type.toUpperCase(),
                "${c.type == 'expense' ? '-' : '+'}\$${c.amount.toStringAsFixed(2)}",
                "\$${c.runningBalance.toStringAsFixed(2)}",
              ]).toList(),
              border: pw.TableBorder.all(color: PdfColor.fromHex("#E2E8F0"), width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex("#1E293B")),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              },
            ),
          ];
        },
      ),
    );

    // Save PDF file locally
    final outputDir = await getApplicationDocumentsDirectory();
    final file = File("${outputDir.path}/finance_report_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static pw.Widget _buildSummaryBox(String label, String value, PdfColor valueColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      margin: const pw.EdgeInsets.all(3),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex("#E2E8F0"), width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}
