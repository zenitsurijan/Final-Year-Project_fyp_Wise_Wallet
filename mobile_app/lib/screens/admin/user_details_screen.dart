import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_container.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/amount_display.dart';
import 'package:intl/intl.dart';
import '../../services/pdf_report_service.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserDetailsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getAdminUserDetails(widget.userId);
      if (result['success'] == true) {
        setState(() {
          _data = result;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadPdfReport() async {
    if (_data == null) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF Report...'), duration: Duration(seconds: 2)),
      );

      await PdfReportService.generateUserReport(
        user: _data!['user'],
        stats: _data!['stats'],
        transactions: _data!['recentTransactions'] as List,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildContentView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchDetails,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    final user = _data!['user'];
    final stats = _data!['stats'];
    final transactions = _data!['recentTransactions'] as List;
    final budget = _data!['currentBudget'];
    final savings = _data!['savingsGoals'] as List;
    final familyData = _data!['familyDetails'];


    return CustomScrollView(
      slivers: [
        // Premium Header
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: _downloadPdfReport,
              tooltip: 'Download Report',
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              widget.userName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 10, color: Colors.black26)],
              ),
            ),
            background: GradientContainer(
              borderRadius: 0,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user['email'],
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Stats Grid
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Financial Summary'),
                const SizedBox(height: AppSpacing.s),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.m,
                  mainAxisSpacing: AppSpacing.m,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard('Income', stats['totalIncome'], AppColors.income, Icons.arrow_upward),
                    _buildStatCard('Expenses', stats['totalExpenses'], AppColors.expense, Icons.arrow_downward),
                    _buildStatCard('Net Balance', stats['netBalance'], AppColors.primaryStart, Icons.account_balance_wallet),
                    _buildStatCard('Savings Goals', savings.length.toDouble(), Colors.orange, Icons.savings, isCurrency: false),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),

                // Family Members Section
                _buildFamilySection(familyData),
                const SizedBox(height: AppSpacing.l),

                // Current Budget

                _buildSectionHeader('Budget Overview'),
                const SizedBox(height: AppSpacing.s),
                _buildBudgetModule(budget),
                const SizedBox(height: AppSpacing.l),

                // Recent Activity
                _buildSectionHeader('Recent Transactions'),
                const SizedBox(height: AppSpacing.s),
                if (transactions.isEmpty)
                  _buildEmptyState('No recent transactions')
                else
                  ...transactions.map((tx) => _buildTransactionItem(tx)),
                const SizedBox(height: AppSpacing.l),

                // Savings Goals
                _buildSectionHeader('Savings Progress'),
                const SizedBox(height: AppSpacing.s),
                if (savings.isEmpty)
                  _buildEmptyState('No active savings goals')
                else
                  ...savings.map((goal) => _buildSavingsItem(goal)),
                
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildStatCard(String label, dynamic value, Color color, IconData icon, {bool isCurrency = true}) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: isCurrency 
              ? AmountDisplay(amount: (value as num).toDouble(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))
              : Text(value.toInt().toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetModule(dynamic budget) {
    if (budget == null) return _buildEmptyState('No budget set for this month');

    final double total = (budget['total_budget'] as num).toDouble();
    final double spent = (budget['total_spent'] as num).toDouble();
    final double percent = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;

    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Limit', style: TextStyle(fontWeight: FontWeight.w600)),
              AmountDisplay(amount: total),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation(percent > 0.9 ? AppColors.error : AppColors.success),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(percent * 100).toInt()}% Spent', style: const TextStyle(fontSize: 12)),
              Text('Remaining: Rs. ${(total - spent).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final isExpense = tx['type'] == 'expense';
    final date = DateTime.parse(tx['date']);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: CustomCard(
        padding: const EdgeInsets.all(AppSpacing.s),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: (isExpense ? AppColors.expense : AppColors.success).withOpacity(0.1),
            child: Icon(
              isExpense ? Icons.remove_circle_outline : Icons.add_circle_outline,
              color: isExpense ? AppColors.expense : AppColors.success,
            ),
          ),
          title: Text(tx['category'] ?? 'General', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(DateFormat('MMM dd, yyyy').format(date)),
          trailing: AmountDisplay(
            amount: (tx['amount'] as num).toDouble(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isExpense ? AppColors.expense : AppColors.income,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsItem(Map<String, dynamic> goal) {
    final double target = (goal['targetAmount'] as num).toDouble();
    final double current = (goal['currentAmount'] as num).toDouble();
    final double progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: CustomCard(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(goal['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${(progress * 100).toInt()}%', style: const TextStyle(color: AppColors.primaryStart, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryStart),
            ),
            const SizedBox(height: 4),
            Text('Saved: Rs. ${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilySection(dynamic familyData) {
    if (familyData == null || familyData['count'] == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Family Members'),
          const SizedBox(height: AppSpacing.s),
          _buildEmptyState('No family members added'),
        ],
      );
    }

    final members = familyData['members'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Family Members'),
        const SizedBox(height: AppSpacing.s),
        CustomCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryStart, AppColors.primaryStart.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.medium)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Shared Household',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Members: ${familyData['count']}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryStart.withOpacity(0.1),
                      child: Text(
                        member['name'][0].toUpperCase(),
                        style: const TextStyle(color: AppColors.primaryStart, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      member['name'],
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      member['email'],
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: member['relation'] == 'Head' 
                            ? Colors.orange.withOpacity(0.1) 
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        member['relation'],
                        style: TextStyle(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold,
                          color: member['relation'] == 'Head' ? Colors.orange : Colors.blue,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
      ),
    );
  }
}
