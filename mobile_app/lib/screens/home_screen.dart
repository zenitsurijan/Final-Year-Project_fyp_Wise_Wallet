import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'budget_dashboard_screen.dart';
import 'transaction_list_screen.dart';
import 'reports_screen.dart';
import '../providers/auth_provider.dart';

import '../services/notification_service.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/amount_display.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/gradient_container.dart';
import '../models/transaction.dart';
import '../utils/icon_mapping.dart';
import '../providers/transaction_provider.dart';
import '../providers/report_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    NotificationService.uploadToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final transProvider = Provider.of<TransactionProvider>(context, listen: false);
    final reportProvider = Provider.of<ReportProvider>(context, listen: false);
    final now = DateTime.now();
    await Future.wait([
      transProvider.fetchRecentTransactions(),
      transProvider.fetchSummary(),
      reportProvider.fetchMonthlyReport(now.month, now.year),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final transProvider = Provider.of<TransactionProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Premium Header with Welcome & Profile
            SliverToBoxAdapter(
              child: GradientContainer(
                padding: const EdgeInsets.only(
                  top: 60,
                  left: AppSpacing.l,
                  right: AppSpacing.l,
                  bottom: AppSpacing.xl,
                ),
                borderRadius: AppRadius.xLarge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?['name'] ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/notifications'),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.notifications_none, color: Colors.white),
                              ),
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                height: 10,
                                width: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Balance Card
                    CustomCard(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      borderRadius: AppRadius.large,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total Balance",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AmountDisplay(
                            amount: (transProvider.summary['balance'] ?? 0.0).toDouble(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _BalanceIndicator(
                                  label: "Income",
                                  amount: (transProvider.summary['income']?['total'] ?? 0.0).toDouble(),
                                  icon: Icons.arrow_downward,
                                  color: AppColors.income,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s),
                              Expanded(
                                child: _BalanceIndicator(
                                  label: "Expenses",
                                  amount: (transProvider.summary['expense']?['total'] ?? 0.0).toDouble(),
                                  icon: Icons.arrow_upward,
                                  color: AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Quick Actions
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.l),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.m,
                      crossAxisSpacing: AppSpacing.m,
                      childAspectRatio: 1.0, 
                      children: [
                        _QuickActionCard(
                          title: 'Add',
                          icon: Icons.add_circle_outline,
                          color: AppColors.primaryStart,
                          onTap: () async {
                            final result = await Navigator.pushNamed(context, '/add-transaction');
                            if (result == true) {
                              _refreshData();
                            }
                          },
                        ),
                        _QuickActionCard(
                          title: 'History',
                          icon: Icons.history,
                          color: Colors.blue,
                          onTap: () => Navigator.pushNamed(context, '/transactions'),
                        ),
                        _QuickActionCard(
                          title: 'Budget',
                          icon: Icons.pie_chart_outline,
                          color: Colors.orange,
                          onTap: () => Navigator.pushNamed(context, '/budget-dashboard'),
                        ),
                        _QuickActionCard(
                          title: 'Reports',
                          icon: Icons.analytics_outlined,
                          color: Colors.purple,
                          onTap: () => Navigator.pushNamed(context, '/reports'),
                        ),
                        _QuickActionCard(
                          title: 'Family',
                          icon: Icons.people_outline,
                          color: Colors.indigo,
                          onTap: () => Navigator.pushNamed(context, '/family'),
                        ),
                        _QuickActionCard(
                          title: 'Savings',
                          icon: Icons.savings_outlined,
                          color: Colors.teal,
                          onTap: () => Navigator.pushNamed(context, '/savings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 3. Recent Transactions
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Recent Transactions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/transactions'),
                      child: const Text("View All"),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (transProvider.isLoading && transProvider.recentTransactions.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s),
                        child: LoadingShimmer.listTile(),
                      );
                    }
                    if (transProvider.recentTransactions.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.xl),
                        child: Text("No transactions yet.", textAlign: TextAlign.center),
                      );
                    }
                    final t = transProvider.recentTransactions[index];
                    return TransactionTile(
                      title: t.description.isNotEmpty ? t.description : t.category,
                      category: t.category,
                      amount: t.amount,
                      date: t.date,
                      icon: IconMapping.getIconData(t.category),
                      categoryColor: _getCategoryColor(t.category),
                      isExpense: t.type == 'expense',
                      onTap: () {},
                    );
                  },
                  childCount: transProvider.isLoading && transProvider.recentTransactions.isEmpty 
                    ? 3 
                    : transProvider.recentTransactions.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  IconData _getCategoryIcon(String category) {
    // This should ideally use an icon mapping utility
    switch (category.toLowerCase()) {
      case 'food': return Icons.restaurant;
      case 'transport': return Icons.directions_car;
      case 'entertainment': return Icons.movie;
      case 'shopping': return Icons.shopping_bag;
      default: return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    if (category.toLowerCase().contains('food')) return Colors.orange;
    if (category.toLowerCase().contains('health')) return Colors.red;
    if (category.toLowerCase().contains('transport')) return Colors.blue;
    if (category.toLowerCase().contains('shopping')) return Colors.purple;
    return AppColors.primaryStart;
  }

  Widget _buildMonthlyStat(String label, double amount, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            AmountDisplay(
              amount: amount,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
      ],
    );
  }
}

class _BalanceIndicator extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _BalanceIndicator({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
              AmountDisplay(
                amount: amount,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final iconSize = constraints.maxWidth * 0.35;
              final spacing = constraints.maxHeight * 0.08;
              
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(constraints.maxWidth * 0.1),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        size: iconSize.clamp(20, 32), // Dynamic but capped
                        color: widget.color,
                      ),
                    ),
                    SizedBox(height: spacing),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        ),
      ),
    );
  }
}


