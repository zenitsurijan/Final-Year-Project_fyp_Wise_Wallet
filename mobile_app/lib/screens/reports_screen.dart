import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/report_provider.dart';
import '../widgets/chart_widgets.dart';
import '../utils/report_utils.dart';
import '../utils/currency_utils.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  DateTimeRange? _customRange;

  Map<String, dynamic>? _getTabData(ReportProvider provider) {
    switch (_tabController.index) {
      case 0: return provider.dailyReport;
      case 1: return provider.monthlyReport;
      case 2: return provider.yearlyReport;
      case 3: return provider.customReport;
      default: return null;
    }
  }

  void debugReportData(Map<String, dynamic>? reportData) {
    print('=== REPORT DATA DEBUG ===');
    print('reportData is null: ${reportData == null}');
    if (reportData != null) {
      print('reportData keys: ${reportData.keys.toList()}');
      // Deep check based on type
      if (reportData.containsKey('currentMonth')) {
        print('Monthly format detected');
        print('currentMonth income: ${reportData['currentMonth']?['income']}');
      } else if (reportData.containsKey('summary')) {
        print('Summary format detected');
        print('summary income: ${reportData['summary']?['income']}');
      }
    }
    print('========================');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDaily(DateTime.now());
      _loadMonthly(_selectedMonth, _selectedYear);
      _loadYearly(_selectedYear);
    });
  }

  void _loadDaily(DateTime date) {
    Provider.of<ReportProvider>(context, listen: false)
        .fetchDailyReport(DateFormat('yyyy-MM-dd').format(date));
  }

  void _loadMonthly(int month, int year) {
    Provider.of<ReportProvider>(context, listen: false).fetchMonthlyReport(month, year);
  }

  void _loadYearly(int year) {
    Provider.of<ReportProvider>(context, listen: false).fetchYearlyReport(year);
  }

  void _loadCustom(DateTime start, DateTime end) {
    Provider.of<ReportProvider>(context, listen: false)
        .fetchCustomReport(DateFormat('yyyy-MM-dd').format(start), DateFormat('yyyy-MM-dd').format(end));
  }

  Future<void> _exportPdf() async {
    print('🔍 DEBUG: Export PDF started');
    
    final provider = Provider.of<ReportProvider>(context, listen: false);
    final reportData = _getTabData(provider);
    
    debugReportData(reportData);

    if (reportData == null) {
      print('❌ ERROR: reportData is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No data available. Please wait for report to load.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('✅ Data exists: $reportData');

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Helper to find values with NULL SAFETY and multiple key support
      double getVal(String key) {
        final alt1 = key == 'income' ? 'totalIncome' : 'totalExpense';
        final alt2 = key == 'income' ? 'total_income' : 'total_expenses';
        
        dynamic val;
        if (reportData.containsKey('currentMonth')) {
          val = reportData['currentMonth']?[key] ?? reportData['currentMonth']?[alt1] ?? reportData['currentMonth']?[alt2];
        } else if (reportData.containsKey('summary')) {
          val = reportData['summary']?[key] ?? reportData['summary']?[alt1] ?? reportData['summary']?[alt2];
        } else {
          val = reportData[key] ?? reportData[alt1] ?? reportData[alt2];
        }
        
        // Final fallback for root level
        val ??= reportData[key] ?? reportData[alt1] ?? reportData[alt2];
        
        return (val is num) ? val.toDouble() : 0.0;
      }

      final income = getVal('income');
      final expenses = getVal('expense');
      final balance = income - expenses;
      
      List<dynamic> categories = [];
      if (reportData.containsKey('currentMonth')) {
        categories = reportData['currentMonth']?['categories'] as List? ?? [];
      } else if (reportData.containsKey('topCategories')) {
        categories = reportData['topCategories'] as List? ?? [];
      } else {
        categories = reportData['categories'] as List? ?? [];
      }

      print('📊 Income: $income, Expenses: $expenses, Balance: $balance');
      print('📋 Categories count: ${categories.length}');

      // Create PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Wise Wallet Financial Report',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Generated on - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey),
                ),
                pw.SizedBox(height: 24),

                // Summary Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Summary',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Income:'),
                          pw.Text(
                            CurrencyUtils.format(income),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Expenses:'),
                          pw.Text(
                            CurrencyUtils.format(expenses),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                          ),
                        ],
                      ),
                      pw.Divider(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Net Balance:'),
                          pw.Text(
                            CurrencyUtils.format(balance),
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: balance >= 0 ? PdfColors.green : PdfColors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // Categories section
                if (categories.isNotEmpty) ...[
                  pw.Text('Expense Categories', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 12),
                  ...categories.map((category) {
                    final name = category?['_id']?.toString() ?? category?['name']?.toString() ?? 'Unknown';
                    final amountVal = (category?['total'] ?? category?['amount'] ?? 0) as num;
                    
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey200),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(name),
                          pw.Text(CurrencyUtils.format(amountVal.toDouble())),
                        ],
                      ),
                    );
                  }).toList(),
                ] else ...[
                  pw.Text('No expense categories found'),
                ],

                pw.Spacer(),
                pw.Divider(),
                pw.Text('Generated by Wise Wallet', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ],
            );
          },
        ),
      );

      // Close loading dialog
      if (Navigator.canPop(context)) Navigator.pop(context);

      // Save and share PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'wise_wallet_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      print('✅ PDF exported successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ PDF exported successfully!'), backgroundColor: Colors.green),
      );
    } catch (e, stackTrace) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      print('❌ PDF Export Error: $e');
      print('Stack Trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
            Tab(text: 'Custom'),
          ],
        ),
        actions: [
          Consumer<ReportProvider>(
            builder: (context, provider, child) {
              final reportData = _getTabData(provider);
              
              return IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Export to PDF',
                onPressed: () {
                  // Validate data before export
                  if (reportData == null || (reportData['success'] != true && reportData.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚠️ No data to export. Please wait for report to load.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  
                  // Call export function
                  _exportPdf();
                },
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyTab(),
          _buildMonthlyTab(),
          _buildYearlyTab(),
          _buildCustomTab(),
        ],
      ),
    );
  }

  Widget _buildDailyTab() {
    return Consumer<ReportProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error: ${provider.error}', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => _loadDaily(_selectedDate), child: const Text('Retry')),
              ],
            ),
          );
        }
        final data = provider.dailyReport;
        if (data == null) return const Center(child: Text('No data loaded'));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildDateSelector('Daily', _selectedDate, (date) {
                setState(() => _selectedDate = date);
                _loadDaily(date);
              }),
              const SizedBox(height: 20),
              _buildSummaryCard(data['summary']),
              const SizedBox(height: 24),
              const Text('Category Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(height: 350, child: CategoryPieChart(categories: data['categories'])),
              const SizedBox(height: 24),
              _buildCategoryList(data['categories']),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyTab() {
    return Consumer<ReportProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        final data = provider.monthlyReport;
        if (data == null) return const Center(child: Text('No data loaded'));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildMonthYearSelector(),
              const SizedBox(height: 20),
              _buildSummaryComparison(data),
              const SizedBox(height: 24),
              const Text('Spending Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(height: 200, child: IncomeExpenseLineChart(trends: data['currentMonth']['trends'])),
              const SizedBox(height: 24),
              const Text('Top Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(height: 350, child: CategoryPieChart(categories: data['currentMonth']['categories'])),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYearlyTab() {
    return Consumer<ReportProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        final data = provider.yearlyReport;
        if (data == null) return const Center(child: Text('No data loaded'));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildYearSelector(),
              const SizedBox(height: 20),
              const Text('Monthly Comparison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(height: 250, child: MonthlyBarChart(monthlyData: data['monthlyBreakdown'])),
              const SizedBox(height: 24),
              const Text('Top Expense Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildCategoryList(data['topCategories']),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomTab() {
    return Consumer<ReportProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(_customRange == null 
                  ? 'Select Date Range' 
                  : '${DateFormat('dd/MM/yy').format(_customRange!.start)} - ${DateFormat('dd/MM/yy').format(_customRange!.end)}'),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _customRange = picked);
                    _loadCustom(picked.start, picked.end);
                  }
                },
              ),
              if (provider.isLoading) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
              if (provider.customReport != null && !provider.isLoading) ...[
                const SizedBox(height: 20),
                _buildSummaryCard(provider.customReport!['summary']),
                const SizedBox(height: 24),
                const Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(height: 350, child: CategoryPieChart(categories: provider.customReport!['categories'])),
                _buildCategoryList(provider.customReport!['categories']),
              ]
            ],
          ),
        );
      },
    );
  }

  // Helper Widgets
  Widget _buildDateSelector(String label, DateTime current, Function(DateTime) onSelected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => onSelected(current.subtract(const Duration(days: 1)))),
        Text(DateFormat('MMMM dd, yyyy').format(current), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => onSelected(current.add(const Duration(days: 1)))),
      ],
    );
  }

  Widget _buildMonthYearSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DropdownButton<int>(
          value: _selectedMonth,
          items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(DateFormat('MMMM').format(DateTime(2024, i + 1))))),
          onChanged: (v) {
            setState(() => _selectedMonth = v!);
            _loadMonthly(_selectedMonth, _selectedYear);
          },
        ),
        const SizedBox(width: 16),
        DropdownButton<int>(
          value: _selectedYear,
          items: List.generate(5, (i) => DropdownMenuItem(value: 2024 + i, child: Text((2024 + i).toString()))),
          onChanged: (v) {
            setState(() => _selectedYear = v!);
            _loadMonthly(_selectedMonth, _selectedYear);
          },
        ),
      ],
    );
  }

  Widget _buildYearSelector() {
    return DropdownButton<int>(
      value: _selectedYear,
      items: List.generate(5, (i) => DropdownMenuItem(value: 2024 + i, child: Text((2024 + i).toString()))),
      onChanged: (v) {
        setState(() => _selectedYear = v!);
        _loadYearly(v!);
      },
    );
  }

  Widget _buildSummaryCard(dynamic summary) {
    if (summary == null) return const SizedBox.shrink();
    
    final double income = (summary['income'] as num?)?.toDouble() ?? 0.0;
    final double expense = (summary['expense'] as num?)?.toDouble() ?? 0.0;
    final double net = (summary['netBalance'] as num?)?.toDouble() ?? (income - expense);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(child: _buildSummaryItem('Income', CurrencyUtils.format(income), Colors.green)),
            Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.3)),
            Expanded(child: _buildSummaryItem('Expense', CurrencyUtils.format(expense), Colors.red)),
            Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.3)),
            Expanded(child: _buildSummaryItem('Net', CurrencyUtils.format(net), Colors.blue)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value, 
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryComparison(dynamic data) {
    final double curExp = (data['currentMonth']['expense'] as num?)?.toDouble() ?? 0.0;
    final double prevExp = (data['prevMonth']['expense'] as num?)?.toDouble() ?? 0.0;
    final double curInc = (data['currentMonth']['income'] as num?)?.toDouble() ?? 0.0;
    
    final diff = curExp - prevExp;
    final percent = prevExp > 0 ? (diff / prevExp * 100).toStringAsFixed(1) : '100';

    return Column(
      children: [
        _buildSummaryCard({
          'income': curInc,
          'expense': curExp,
          'netBalance': curInc - curExp
        }),
        const SizedBox(height: 12),
        Card(
          color: diff > 0 ? Colors.red.shade50 : Colors.green.shade50,
          child: ListTile(
            leading: Icon(diff > 0 ? Icons.trending_up : Icons.trending_down, color: diff > 0 ? Colors.red : Colors.green),
            title: Text('${diff > 0 ? 'Spent' : 'Saved'} ${CurrencyUtils.format(diff.abs().toDouble())} more than last month'),
            subtitle: Text('$percent% ${diff > 0 ? 'increase' : 'decrease'} in spending'),
          ),
        ),
        if (data['budgetAdherence'] > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(
              value: (data['budgetAdherence'] / 100).clamp(0, 1),
              backgroundColor: Colors.grey.shade300,
              color: data['budgetAdherence'] > 100 ? Colors.red : Colors.green,
              minHeight: 10,
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryList(List<dynamic> categories) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return ListTile(
          leading: CircleAvatar(backgroundColor: Colors.primaries[index % Colors.primaries.length].withOpacity(0.2), child: Text('${index + 1}')),
          title: Text(cat['_id'], overflow: TextOverflow.ellipsis),
          trailing: Text(CurrencyUtils.format(cat['total']?.toDouble() ?? 0.0), style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}
