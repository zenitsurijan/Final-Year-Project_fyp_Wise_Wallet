import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/family_provider.dart';
import '../../utils/currency_utils.dart';

class MemberReportScreen extends StatefulWidget {
  final String memberId;
  final String memberName;

  const MemberReportScreen({super.key, required this.memberId, required this.memberName});

  @override
  State<MemberReportScreen> createState() => _MemberReportScreenState();
}

class _MemberReportScreenState extends State<MemberReportScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    final result = await Provider.of<FamilyProvider>(context, listen: false).fetchMemberReport(widget.memberId);
    
    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _reportData = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load report';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.memberName}\'s Report')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMemberHeader(),
                      const SizedBox(height: 24),
                      const Text('Spending Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildCategoryPieChart(),
                      const SizedBox(height: 24),
                      const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildTransactionList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMemberHeader() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              child: Text(widget.memberName[0].toUpperCase(), style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.memberName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(_reportData!['member']['email'], style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
            Column(
              children: [
                Text(CurrencyUtils.format((_reportData!['totalExpense'] as num).toDouble()), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                const Text('Total Spent', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    final spending = _reportData!['categorySpending'] as List;
    if (spending.isEmpty) {
      return const Center(child: Text('No spending data found for this member'));
    }

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: spending.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: (item['amount'] as num).toDouble(),
                      radius: 40,
                      title: '',
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: spending.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, color: colors[index % colors.length]),
                    const SizedBox(width: 4),
                    Text('${item['category']}: ${CurrencyUtils.format((item['amount'] as num).toDouble())}', style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactions = _reportData!['recentTransactions'] as List;
    if (transactions.isEmpty) {
      return const Center(child: Text('No recent transactions'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isExpense = tx['type'] == 'expense';
        return ListTile(
          leading: Icon(isExpense ? Icons.remove_circle : Icons.add_circle, color: isExpense ? Colors.red : Colors.green),
          title: Text(tx['category'] ?? 'General'),
          subtitle: Text(tx['description'] ?? ''),
          trailing: Text(
            '${isExpense ? '-' : '+'} ${CurrencyUtils.format((tx['amount'] as num).toDouble())}',
            style: TextStyle(fontWeight: FontWeight.bold, color: isExpense ? Colors.red : Colors.green),
          ),
        );
      },
    );
  }
}
