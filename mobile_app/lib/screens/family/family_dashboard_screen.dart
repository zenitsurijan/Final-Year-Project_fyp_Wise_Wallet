import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/family_provider.dart';
import 'family_setup_screen.dart';
import 'family_setup_screen.dart';
import 'family_management_screen.dart';
import 'set_family_budget_screen.dart';
import '../../utils/currency_utils.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FamilyProvider>(context, listen: false).fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Family Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => Provider.of<FamilyProvider>(context, listen: false).fetchDashboard(),
            ),
            Consumer<FamilyProvider>(
              builder: (context, provider, _) {
                if (provider.dashboardData != null) {
                  return IconButton(
                    icon: const Icon(Icons.people_outline),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FamilyManagementScreen()),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: Consumer<FamilyProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              // Broaden check for not being in a family
              final errMsg = (provider.error ?? '').toLowerCase();
              if (errMsg.contains('not part of a family') || 
                  errMsg.contains('must be part of a family') ||
                  errMsg.contains('family not found')) {
                return const FamilySetupScreen();
              }
              return RefreshIndicator(
                onRefresh: () => provider.fetchDashboard(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 100,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('Error: ${provider.error}', 
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  ),
                ),
              );
            }

            final data = provider.dashboardData;
            if (data == null) {
              return RefreshIndicator(
                onRefresh: () => provider.fetchDashboard(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 100,
                    child: const Center(child: Text('No data loaded')),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.fetchDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(data),
                    const SizedBox(height: 24),
                    _buildBudgetStatusSection(data?['budgetStatus'], data?['isHead'] == true),
                    const SizedBox(height: 24),
                    _buildSavingsGoalsSection(data?['savingsGoals'] as List?),
                    const SizedBox(height: 24),
                    const Text('Spending by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildCategorySpendingPieChart(data['categorySpending'] as List?),
                    const SizedBox(height: 24),
                    const Text('Member Comparison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildSpendingChart(data['memberComparison'] as List?),
                    const SizedBox(height: 24),
                    const Text('Recent Shared Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildRecentTransactionsList(data['recentTransactions'] as List?),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      return Scaffold(
        appBar: AppBar(title: const Text('Family Dashboard Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Render Error: $e', style: const TextStyle(color: Colors.red)),
          ),
        ),
      );
    }
  }

  Widget _buildRecentTransactionsList(List<dynamic>? transactions) {
    if (transactions == null || transactions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No family transactions yet')),
        ),
      );
    }

    return Column(
      children: transactions.map((tx) {
        final isExpense = (tx?['type'] ?? 'expense') == 'expense';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isExpense ? Colors.red.shade50 : Colors.green.shade50,
              child: Icon(
                isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                color: isExpense ? Colors.red : Colors.green,
              ),
            ),
            title: Text(tx?['category']?.toString() ?? 'General'),
            subtitle: Text('By ${tx?['userId']?['name']?.toString() ?? 'Unknown'} • ${tx?['description']?.toString() ?? ''}'),
            trailing: Text(
              '${isExpense ? '-' : '+'} ${CurrencyUtils.format((tx?['amount'] as num?)?.toDouble() ?? 0.0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isExpense ? Colors.red : Colors.green,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetStatusSection(dynamic budget, bool isHead) {
    if (budget == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber),
              const SizedBox(height: 8),
              const Text('No family budget set for this month'),
              if (isHead)
                TextButton(
                  onPressed: () async {
                     final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SetFamilyBudgetScreen()),
                    );
                    if (result == true) {
                      Provider.of<FamilyProvider>(context, listen: false).fetchDashboard();
                    }
                  },
                  child: const Text('Set Budget'),
                )
            ],
          ),
        ),
      );
    }

    final double percentage = ((budget?['percentage'] ?? 0) as num).toDouble() / 100.0;
    final color = percentage > 0.9 ? Colors.red : (percentage > 0.7 ? Colors.orange : Colors.blue);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Family Budget Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (isHead)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SetFamilyBudgetScreen()),
                      );
                      if (result == true) {
                        Provider.of<FamilyProvider>(context, listen: false).fetchDashboard();
                      }
                    },
                  )
                else
                  const Icon(Icons.bar_chart, color: Colors.blue),
              ],
            ),
            if (isHead)
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${CurrencyUtils.format((budget?['totalSpent'] as num?)?.toDouble() ?? 0.0)} spent of ${CurrencyUtils.format((budget?['totalBudget'] as num?)?.toDouble() ?? 0.0)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(percentage * 100).toInt()}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic>? data) {
    if (data == null) return const SizedBox.shrink();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              data?['familyName']?.toString() ?? 'Family',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildStatItem('Total Income', CurrencyUtils.format((data?['totalIncome'] as num?)?.toDouble() ?? 0.0), Colors.green.shade100)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatItem('Total Expense', CurrencyUtils.format((data?['totalExpense'] as num?)?.toDouble() ?? 0.0), Colors.red.shade100)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Members: ${data?['memberCount'] ?? 0}',
                  style: const TextStyle(color: Colors.white70),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FamilyManagementScreen()),
                  ),
                  icon: const Icon(Icons.people, color: Colors.white, size: 20),
                  label: Text(
                    (data?['isHead'] ?? false) == true ? 'Manage Members' : 'Family Members',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSpendingChart(List<dynamic>? members) {
    if (members == null || members.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No spending data yet', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final maxVal = members
        .map((e) => (e?['total'] as num?)?.toDouble() ?? 0.0)
        .fold(0.0, (max, current) => current > max ? current : max);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal == 0 ? 100 : maxVal * 1.2,
          barGroups: members.asMap().entries.map((entry) {
            final val = (entry.value?['total'] as num?)?.toDouble() ?? 0.0;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: val,
                  color: Colors.blue.shade400,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < members.length && index >= 0) {
                    final name = members[index]?['name']?.toString() ?? 'User';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        name.split(' ')[0],
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildSavingsGoalsSection(List<dynamic>? goals) {
    if (goals == null || goals.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Family Savings Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No family savings goals yet')),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Family Savings Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...goals.map((goal) {
          final double percentage = ((goal?['percentage'] ?? 0) as num).toDouble() / 100.0;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(goal?['name']?.toString() ?? 'Saving Goal', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Text('${(percentage * 100).toStringAsFixed(1)}%', 
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: percentage.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${CurrencyUtils.format((goal?['currentAmount'] as num?)?.toDouble() ?? 0.0)} of ${CurrencyUtils.format((goal?['targetAmount'] as num?)?.toDouble() ?? 0.0)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      if (goal?['deadline'] != null)
                        Text('Deadline: ${DateTime.parse(goal['deadline']).toString().split(' ')[0]}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCategorySpendingPieChart(List<dynamic>? spending) {
    if (spending == null || spending.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No expense data available for charts')),
        ),
      );
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: spending.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: (item?['amount'] as num?)?.toDouble() ?? 0.0,
                      title: '${item?['percentage'] ?? 0}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: spending.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item?['category'] ?? 'Other'}: ${CurrencyUtils.format((item?['amount'] as num?)?.toDouble() ?? 0.0)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

}
