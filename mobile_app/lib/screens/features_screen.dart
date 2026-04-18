import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/family_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/report_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/savings_provider.dart';
import '../providers/bills_provider.dart';
import 'transaction_list_screen.dart';
import 'calendar_screen.dart';
import '../theme/app_theme.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Features'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FeatureCard(
            title: 'Transaction Categories',
            subtitle: 'Food, Transport, Bills, Shopping & more',
            icon: Icons.category,
            onTap: () => Navigator.pushNamed(context, '/categories'),
          ),
          _FeatureCard(
            title: 'Smart Filtering',
            subtitle: 'Filter by date, category, amount, or search',
            icon: Icons.filter_list,
            onTap: () => Navigator.pushNamed(context, '/transactions'),
          ),
          _FeatureCard(
            title: 'Spending Calendar',
            subtitle: 'Color-coded days: red=high, green=low',
            icon: Icons.calendar_month,
            onTap: () => Navigator.pushNamed(context, '/calendar'),
          ),
          _FeatureCard(
            title: 'Receipt Photos',
            subtitle: 'Capture and attach receipts to transactions',
            icon: Icons.camera_alt,
            onTap: () => Navigator.pushNamed(
              context,
              '/transactions',
              arguments: {'hasReceipt': true},
            ),
          ),
          _FeatureCard(
            title: 'Budget Management',
            subtitle: 'Set category budgets and track spending',
            icon: Icons.account_balance_wallet,
            onTap: () => Navigator.pushNamed(context, '/budget-dashboard'),
          ),
          _FeatureCard(
            title: 'Family Tracking',
            subtitle: 'Monitor family spending and add members',
            icon: Icons.group,
            onTap: () => Navigator.pushNamed(context, '/family'),
          ),
          _FeatureCard(
            title: 'Savings Goals',
            subtitle: 'Plan for the future with personal & family goals',
            icon: Icons.savings,
            onTap: () => Navigator.pushNamed(context, '/savings'),
          ),
          _FeatureCard(
            title: 'Recurring Bills',
            subtitle: 'Manage upcoming payments and get reminders',
            icon: Icons.receipt_long,
            onTap: () => Navigator.pushNamed(context, '/bills'),
          ),
          _FeatureCard(
            title: 'Financial Reports',
            subtitle: 'Visualize your spending with PDF and charts',
            icon: Icons.analytics,
            onTap: () => Navigator.pushNamed(context, '/reports'),
          ),
          Consumer<FamilyProvider>(
            builder: (context, provider, child) {
              final isHead = provider.dashboardData?['isHead'] == true;
              if (!isHead) return const SizedBox.shrink();
              
              return _FeatureCard(
                title: 'Manage Family',
                subtitle: 'View members, remove members, or manage roles',
                icon: Icons.manage_accounts,
                onTap: () => Navigator.pushNamed(context, '/family-management'),
              );
            },
          ),
          const Divider(),
          _FeatureCard(
            title: 'Logout',
            subtitle: 'Sign out of your account',
            icon: Icons.logout,
            onTap: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
        titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Confirm Logout',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _executeLogout(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryStart,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _executeLogout(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Clear all state providers to ensure data isolation
    Provider.of<TransactionProvider>(context, listen: false).clear();
    Provider.of<ReportProvider>(context, listen: false).clear();
    Provider.of<BudgetProvider>(context, listen: false).clear();
    Provider.of<SavingsProvider>(context, listen: false).clear();
    Provider.of<BillsProvider>(context, listen: false).clear();
    Provider.of<FamilyProvider>(context, listen: false).clear();

    authProvider.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature feature coming soon!')),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 90,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (color ?? Colors.blue).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color ?? Colors.blue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
