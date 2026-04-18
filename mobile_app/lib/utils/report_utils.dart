import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'currency_utils.dart';

class ReportUtils {
  static Future<void> generateAndShareReport({
    required String title,
    required Map<String, dynamic> data,
    required String type, // 'daily', 'monthly', 'yearly', 'custom'
  }) async {
    final pdf = pw.Document();

    try {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Wise Wallet - $title', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Summary Section
            pw.Text('Financial Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Income', CurrencyUtils.format(double.parse(_getValue(data, 'income', type))), PdfColors.green),
                _buildSummaryItem('Total Expense', CurrencyUtils.format(double.parse(_getValue(data, 'expense', type))), PdfColors.red),
                _buildSummaryItem('Net Balance', CurrencyUtils.format(double.parse(_getNet(data, type))), PdfColors.blue),
              ],
            ),
            pw.SizedBox(height: 30),

            // Categories Table
            pw.Text('Expense by Category', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.TableHelper.fromTextArray(
              headers: ['Category', 'Amount'],
              data: _getCategoryData(data, type),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            
            pw.SizedBox(height: 40),
            pw.Footer(
              trailing: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}'),
            ),
          ],
        ),
      );

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'Wise_Wallet_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    } catch (e) {
      rethrow; // Re-throw to be caught by the UI
    }
  }

  static pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
        pw.SizedBox(height: 5),
        pw.Text(value, style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  static String _getValue(Map<String, dynamic> data, String key, String type) {
    // Map alternative keys (backend uses totalIncome/totalExpense for some aggregations)
    // Adding total_income/total_expenses as requested by user too
    final keys = [key, 'totalIncome', 'totalExpense', 'total_income', 'total_expenses'];
    
    if (type == 'monthly') {
      final dynamic currentMonth = data['currentMonth'];
      if (currentMonth is Map) {
        for (var k in keys) {
          if (currentMonth[k] is num) return (currentMonth[k] as num).toDouble().toStringAsFixed(2);
        }
      }
    }
    
    if (type == 'yearly') {
      final dynamic summary = data['summary'];
      if (summary is Map) {
        for (var k in keys) {
          if (summary[k] is num) return (summary[k] as num).toDouble().toStringAsFixed(2);
        }
      }
      
      // Fallback: sum up monthlyBreakdown
      final monthlyBreakdown = data['monthlyBreakdown'] as List<dynamic>? ?? [];
      double total = 0;
      for (var m in monthlyBreakdown) {
        if (m is Map) {
          for (var k in keys) {
            if (m[k] is num) {
              total += (m[k] as num).toDouble();
              break; // Found one, move to next month
            }
          }
        }
      }
      return total.toStringAsFixed(2);
    }
    
    final s = data['summary'] ?? {};
    for (var k in keys) {
      if (s[k] is num) return (s[k] as num).toDouble().toStringAsFixed(2);
    }
    return '0.00';
  }

  static String _getNet(Map<String, dynamic> data, String type) {
    final double inc = double.tryParse(_getValue(data, 'income', type)) ?? 0.0;
    final double exp = double.tryParse(_getValue(data, 'expense', type)) ?? 0.0;
    return (inc - exp).toStringAsFixed(2);
  }

  static List<List<String>> _getCategoryData(Map<String, dynamic> data, String type) {
    List<dynamic> cats = [];
    if (type == 'monthly') {
      cats = data['currentMonth']?['categories'] ?? [];
    } else if (type == 'yearly') {
      cats = data['topCategories'] ?? [];
    } else {
      cats = data['categories'] ?? [];
    }

    if (cats.isEmpty) return [['No data', CurrencyUtils.format(0)]];

    return cats.map((c) {
      if (c is! Map) return ['Unknown', CurrencyUtils.format(0)];
      final String id = c['_id']?.toString() ?? 'Other';
      final dynamic totalRaw = c['total'];
      final double totalValue = (totalRaw is num) ? totalRaw.toDouble() : 0.0;
      return [id, CurrencyUtils.format(totalValue)];
    }).toList();
  }
}
