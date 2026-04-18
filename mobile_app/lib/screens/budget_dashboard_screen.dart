import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/currency_utils.dart';
import '../theme/app_theme.dart';
import 'budget/overspending_screen.dart';

class BudgetDashboardScreen extends StatefulWidget {
  const BudgetDashboardScreen({super.key});

  @override
  State<BudgetDashboardScreen> createState() => _BudgetDashboardScreenState();
}

class _BudgetDashboardScreenState extends State<BudgetDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final provider = Provider.of<BudgetProvider>(context, listen: false);
      provider.fetchPersonalBudget(now.month, now.year);
      provider.fetchFamilyBudget(now.month, now.year);
      provider.fetchAlertHistory();
      provider.fetchOverspendingAnalysis();
    });
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isHead = user?['role'] == 'family_head';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/budget-setup');
              if (result == true) {
                final now = DateTime.now();
                if (mounted) {
                  final provider = Provider.of<BudgetProvider>(context, listen: false);
                  await provider.fetchPersonalBudget(now.month, now.year);
                  await provider.fetchOverspendingAnalysis();
                }
              }
            },
          ),
        ],
      ),
      body: budgetProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final now = DateTime.now();
                await budgetProvider.fetchPersonalBudget(now.month, now.year);
                await budgetProvider.fetchFamilyBudget(now.month, now.year);
                await budgetProvider.fetchAlertHistory();
                await budgetProvider.fetchOverspendingAnalysis();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (budgetProvider.personalBudget == null)
                      _buildNoBudgetCard()
                    else ...[
                      _buildOverallProgress(budgetProvider.personalBudget!),
                      const SizedBox(height: 24),
                      _buildRecommendations(budgetProvider.overspendingAnalysis),
                      const SizedBox(height: 24),
                      _buildSpendingTrends(budgetProvider.overspendingAnalysis),
                      const SizedBox(height: 24),
                      const Text(
                        'Category Breakdown',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ..._buildCategoryList(budgetProvider.personalBudget!),
                    ],
                    if (isHead) ...[
                      const SizedBox(height: 32),
                      const Text(
                        'Family Spending Breakdown',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      _buildFamilyBreakdown(budgetProvider.familyBreakdown),
                    ],
                    const SizedBox(height: 32),
                    _buildAlertHistory(budgetProvider.alertHistory),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNoBudgetCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Budget Set for this Month',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Set a budget to track your spending limits'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/budget-setup'),
              child: const Text('Set Up Budget'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallProgress(Map<String, dynamic> budget) {
    final limit = (budget['total_budget'] as num?)?.toDouble() ?? 0.0;
    final spent = (budget['total_spent'] as num?)?.toDouble() ?? 0.0;
    final percent = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final color = percent >= 1.0 ? Colors.red : (percent >= 0.8 ? Colors.orange : Colors.green);
    
    // Status text
    String statusText = 'Healthy';
    if (percent >= 1.0) statusText = 'Overspent';
    else if (percent >= 0.8) statusText = 'Warning';

    // Days left calculation
    final now = DateTime.now();
    final budgetMonthStr = budget['month'] as String? ?? '';
    int daysLeft = 0;
    if (budgetMonthStr.isNotEmpty) {
       try {
         final parts = budgetMonthStr.split('-');
         if (parts.length >= 2) {
           final bYear = int.parse(parts[0]);
           final bMonth = int.parse(parts[1]);
           if (bYear == now.year && bMonth == now.month) {
              final lastDay = DateTime(bYear, bMonth + 1, 0).day;
              daysLeft = lastDay - now.day;
           }
         }
       } catch (e) {
         print('Error parsing budget month: $e');
       }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Month Overview', style: TextStyle(color: Colors.grey)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      CurrencyUtils.format(spent),
                      style: TextStyle(
                        fontSize: constraints.maxWidth < 350 ? 22 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'of ${CurrencyUtils.format(limit)}',
                        style: TextStyle(
                          fontSize: constraints.maxWidth < 350 ? 14 : 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 12,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(percent * 100).toStringAsFixed(1)}% used',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                if (daysLeft > 0)
                  Text(
                    '$daysLeft days left',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(Map<String, dynamic>? analysis) {
    if (analysis == null) return const SizedBox.shrink();
    final recommendations = analysis['recommendations'] as List<dynamic>?;
    if (recommendations == null || recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Smart Recommendations',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        ...recommendations.map((rec) {
          final isHigh = rec['severity'] == 'high';
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isHigh ? Colors.orange.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
                width: 1,
              ),
            ),
            color: isHigh ? Colors.orange.shade50.withOpacity(0.5) : Colors.blue.shade50.withOpacity(0.5),
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isHigh ? Colors.orange.shade100 : Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isHigh ? Icons.warning_rounded : Icons.lightbulb_outline_rounded,
                      color: isHigh ? Colors.deepOrange : Colors.blue.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHigh ? 'Urgent Action' : 'Smart Tip',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isHigh ? Colors.deepOrange : Colors.blue.shade700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rec['message'] as String? ?? 'No recommendation',
                          style: TextStyle(
                            color: isHigh ? Colors.deepOrange.shade900 : Colors.blue.shade900,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSpendingTrends(Map<String, dynamic>? analysis) {
    if (analysis == null) return const SizedBox.shrink();
    final trends = analysis['trends'] as List<dynamic>?;
    if (trends == null || trends.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spending Trends (Last 3 Months)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: trends.reversed.map((trend) {
            final spent = (trend['spent'] as num?)?.toDouble() ?? 0.0;
            final limit = (trend['limit'] as num?)?.toDouble() ?? 0.0;
            final percent = limit > 0 ? (spent / limit) : 0.0;
            final isOver = trend['overspent'] == true;
            
            // Cap height for display
            final displayPercent = percent > 1.5 ? 1.5 : percent;

            return Column(
              children: [
                Text(CurrencyUtils.format(spent), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOver ? Colors.red : Colors.black87)),
                const SizedBox(height: 8),
                Container(
                  width: 32,
                  height: 100 * displayPercent,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: isOver 
                        ? [Colors.red.shade400, Colors.red.shade200] 
                        : [AppColors.primaryStart, AppColors.primaryEnd],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    boxShadow: [
                      BoxShadow(
                        color: (isOver ? Colors.red : AppColors.primaryStart).withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('${_getMonthName(trend['month'] as int? ?? 1)}\n${trend['year'] ?? ""}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OverspendingScreen()),
              );
            },
            child: const Text('View Full Analysis'),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  List<Widget> _buildCategoryList(Map<String, dynamic> budget) {
    final categories = budget['categories'] as List<dynamic>? ?? [];

    return categories.map((cat) {
      final name = cat['category_name'] as String? ?? 'Uncategorized';
      final limit = (cat['budget_limit'] as num?)?.toDouble() ?? 0.0;
      final spent = (cat['spent_amount'] as num?)?.toDouble() ?? 0.0;
      final percent = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : (spent > 0 ? 1.0 : 0.0); 
      
      final color = percent >= 1.0 ? Colors.red : (percent >= 0.8 ? Colors.orange : Colors.green);

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    name, 
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    '${CurrencyUtils.format(spent)} / ${CurrencyUtils.format(limit)}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildFamilyBreakdown(List<dynamic> breakdown) {
    if (breakdown.isEmpty) return const Text('No family data available');

    // Find max spent for bar scaling
    final maxSpent = breakdown.fold<double>(0, (prev, m) => ((m['spent'] as num?)?.toDouble() ?? 0.0) > prev ? ((m['spent'] as num?)?.toDouble() ?? 0.0) : prev);

     return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: breakdown.map((member) {
            final spent = (member['spent'] as num?)?.toDouble() ?? 0.0;
            final relativeWidth = (maxSpent > 0 ? spent / maxSpent : 0.0).clamp(0.01, 1.0);
            final name = member['name'] as String? ?? 'Unknown';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   CircleAvatar(
                     backgroundColor: Colors.blue.shade50,
                     child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Expanded(
                               child: Text(
                                 name, 
                                 style: const TextStyle(fontWeight: FontWeight.bold),
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                             const SizedBox(width: 12),
                             Text(CurrencyUtils.format(spent), style: const TextStyle(fontWeight: FontWeight.w500)),
                           ],
                         ),
                         const SizedBox(height: 8),
                         Stack(
                           children: [
                             Container(
                               height: 6,
                               width: double.infinity,
                               decoration: BoxDecoration(
                                 color: Colors.white,
                                 border: Border.all(color: Colors.grey.shade200),
                                 borderRadius: BorderRadius.circular(3)
                               ),
                             ),
                             FractionallySizedBox(
                               widthFactor: relativeWidth,
                               child: Container(
                                 height: 6,
                                 decoration: BoxDecoration(
                                   color: AppColors.primaryStart,
                                   borderRadius: BorderRadius.circular(3)
                                 ),
                               ),
                             ),
                           ],
                         )
                       ],
                     ),
                   )
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAlertHistory(List<dynamic> history) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alert History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        ...history.take(5).map((alert) {
          final dateStr = alert['date'] as String? ?? DateTime.now().toIso8601String();
          final date = DateTime.tryParse(dateStr) ?? DateTime.now();
          final threshold = (alert['threshold'] ?? 0).toString();
          final category = alert['category'] as String? ?? 'Overall Budget';
          final amount = (alert['amountAtTime'] as num?)?.toDouble() ?? 0.0;

          return Card(
            color: Colors.red.shade50,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.warning_amber, color: Colors.red),
              title: Text('$threshold% Limit Reached'),
              subtitle: Text('$category • ${date.day}/${date.month}/${date.year}'),
              trailing: Text(
                CurrencyUtils.format(amount),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          );
        }),
      ],
    );
  }
}
