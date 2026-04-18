import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/gradient_container.dart';
import '../../utils/currency_utils.dart';
import 'package:intl/intl.dart';
import '../main_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _timeframe = 'last30days';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Standard role normalization
      final role = (authProvider.user?['role'] ?? 'user').toString().trim().toLowerCase();
      
      // SECURITY GUARD: Strictly allow ONLY administrators.
      if (role != 'admin') {
        debugPrint('SECURITY GUARD: Unauthorized access attempt by role ($role).');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Denied: Administrator privileges required.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Redirect to MainScreen using direct route as requested
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
        return;
      }
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await Future.wait([
      adminProvider.fetchDashboardStats(),
      adminProvider.fetchAnalytics(timeframe: _timeframe),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final stats = adminProvider.stats;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: adminProvider.isLoading && stats.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final isTablet = constraints.maxWidth > 600 && constraints.maxWidth <= 900;
                final horizontalPadding = constraints.maxWidth > 1200 ? AppSpacing.xl * 2 : AppSpacing.l;

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: CustomScrollView(
                    slivers: [
                      _buildAppBar(context),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: AppSpacing.l),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildSectionHeader('Key Statistics'),
                            const SizedBox(height: AppSpacing.m),
                            _buildResponsiveStatsGrid(stats, constraints.maxWidth),
                            const SizedBox(height: AppSpacing.xl),
                            
                            _buildSectionHeader('Quick Functions'),
                            const SizedBox(height: AppSpacing.m),
                            _buildAdminActions(context, constraints.maxWidth),
                            const SizedBox(height: AppSpacing.xl),

                            Row(
                              children: [
                                Expanded(child: _buildSectionHeader('System Analytics & Trends')),
                                _buildTimeframeDropdown(),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.m),
                            
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: _buildTrendsChart(adminProvider.analytics)),
                                  const SizedBox(width: AppSpacing.l),
                                  Expanded(flex: 2, child: _buildCategoryBreakdown(adminProvider.analytics)),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _buildTrendsChart(adminProvider.analytics),
                                  const SizedBox(height: AppSpacing.l),
                                  _buildCategoryBreakdown(adminProvider.analytics),
                                ],
                              ),
                            const SizedBox(height: AppSpacing.xxl),
                          ]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      drawer: _buildDrawer(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primaryStart,
      flexibleSpace: FlexibleSpaceBar(
        background: GradientContainer(
          borderRadius: 0,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  'Global Admin Dashboard',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Monitoring ${DateTime.now().year} System Overview',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _refreshData,
        ),
        const SizedBox(width: AppSpacing.s),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildResponsiveStatsGrid(Map<String, dynamic> stats, double maxWidth) {
    int crossAxisCount = 2;
    double childAspectRatio = 1.35;

    if (maxWidth > 1000) {
      crossAxisCount = 4;
      childAspectRatio = 1.6;
    } else if (maxWidth > 600) {
      crossAxisCount = 2;
      childAspectRatio = 1.8;
    } else if (maxWidth < 360) {
      // Very small devices
      crossAxisCount = 1;
      childAspectRatio = 2.8;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: AppSpacing.m,
      mainAxisSpacing: AppSpacing.m,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: childAspectRatio,
      children: [
        _buildMetricCard(
          'Total Users',
          (stats['totalUsers'] ?? 0).toString(),
          Icons.people_rounded,
          const [Color(0xFF4facfe), Color(0xFF00f2fe)],
        ),
        _buildMetricCard(
          'Transactions',
          (stats['totalTransactions'] ?? 0).toString(),
          Icons.account_balance_wallet_rounded,
          const [Color(0xFFfa709a), Color(0xFFfee140)],
        ),
        _buildMetricCard(
          'Gross Income',
          CurrencyUtils.format((stats['totalIncome'] ?? 0.0).toDouble()),
          Icons.arrow_circle_up_rounded,
          const [Color(0xFF43e97b), Color(0xFF38f9d7)],
        ),
        _buildMetricCard(
          'Total Expenses',
          CurrencyUtils.format((stats['totalExpenses'] ?? 0.0).toDouble()),
          Icons.arrow_circle_down_rounded,
          const [Color(0xFFf093fb), Color(0xFFf5576c)],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, List<Color> gradient) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const Icon(Icons.more_horiz, color: AppColors.textSecondary, size: 14),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context, double maxWidth) {
    int crossAxisCount = maxWidth > 800 ? 4 : (maxWidth > 400 ? 2 : 1);
    
    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: AppSpacing.m,
      mainAxisSpacing: AppSpacing.m,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: maxWidth > 400 ? 2.5 : 4.0,
      children: [
        _buildActionCard(context, 'Users', Icons.manage_accounts_rounded, '/admin/users', Colors.blue),
        _buildActionCard(context, 'Receipts', Icons.receipt_rounded, '/admin/transactions', Colors.orange),
        _buildActionCard(context, 'Reports', Icons.bar_chart_rounded, '/reports', Colors.teal),
        _buildActionCard(context, 'System Log', Icons.track_changes_rounded, '/admin/logs', Colors.deepPurple),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, String? route, Color color) {
    return InkWell(
      onTap: route != null ? () => Navigator.pushNamed(context, route) : null,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: color.withOpacity(0.1), width: 1.5),
        ),
        padding: const EdgeInsets.all(AppSpacing.s),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsChart(Map<String, dynamic> analytics) {
    final dailyTrends = analytics['dailyTrends'] as List? ?? [];
    
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Income vs Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Income', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Expense', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Tap on the chart to view exact values', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.l),
          AspectRatio(
            aspectRatio: 1.7,
            child: dailyTrends.isEmpty
                ? const Center(child: Text('Insufficient data to map trends'))
                : LineChart(_getTrendsChartData(dailyTrends)),
          ),
        ],
      ),
    );
  }

  LineChartData _getTrendsChartData(List dailyTrends) {
    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    Map<String, double> incomeMap = {};
    Map<String, double> expenseMap = {};
    Set<String> allDates = {};

    for (var entry in dailyTrends) {
      final date = entry['_id']['date'] as String;
      final type = entry['_id']['type'] as String;
      final total = (entry['total'] as num).toDouble();
      allDates.add(date);
      if (type == 'income') incomeMap[date] = total;
      else expenseMap[date] = total;
    }

    final sortedDates = allDates.toList()..sort();
    for (int i = 0; i < sortedDates.length; i++) {
        incomeSpots.add(FlSpot(i.toDouble(), (incomeMap[sortedDates[i]] ?? 0)));
        expenseSpots.add(FlSpot(i.toDouble(), (expenseMap[sortedDates[i]] ?? 0)));
    }

    double maxVal = 0;
    for (var s in incomeSpots) if (s.y > maxVal) maxVal = s.y;
    for (var s in expenseSpots) if (s.y > maxVal) maxVal = s.y;
    if (maxVal == 0) maxVal = 1000;

    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => AppColors.primaryStart.withOpacity(0.8),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final flSpot = barSpot;
              return LineTooltipItem(
                '${barSpot.barIndex == 0 ? 'Income' : 'Expense'}\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                children: [
                  TextSpan(
                    text: CurrencyUtils.format(flSpot.y),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: maxVal / 4,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
        getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (sortedDates.length / 5).clamp(1, 10).toDouble(),
            getTitlesWidget: (val, meta) {
              final idx = val.toInt();
              if (idx < 0 || idx >= sortedDates.length) return const SizedBox();
              // Show only day
              final dateParts = sortedDates[idx].split('-');
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(dateParts.last, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxVal / 4,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const SizedBox();
              String text = '';
              if (value >= 1000000) text = '${(value / 1000000).toStringAsFixed(1)}M';
              else if (value >= 1000) text = '${(value / 1000).toStringAsFixed(0)}k';
              else text = value.toStringAsFixed(0);
              return Text(text, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary), textAlign: TextAlign.right);
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minY: 0,
      maxY: maxVal * 1.2,
      lineBarsData: [
        LineChartBarData(
          spots: incomeSpots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: Colors.green,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        LineChartBarData(
          spots: expenseSpots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: Colors.red,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(Map<String, dynamic> analytics) {
    final catStats = analytics['categoryStats'] as List? ?? [];

    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Expenses by Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: AppSpacing.l),
          AspectRatio(
            aspectRatio: 1.0,
            child: _buildProfessionalPieChart(catStats)
          ),
          const SizedBox(height: AppSpacing.l),
          _buildPieLegend(catStats),
        ],
      ),
    );
  }

  Widget _buildProfessionalPieChart(List catStats) {
    if (catStats.isEmpty) return const Center(child: Text('No data'));
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.teal];

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        startDegreeOffset: 180,
        sections: catStats.asMap().entries.map((entry) {
          final idx = entry.key;
          final data = entry.value;
          final isSelected = idx == 0; // Highlight largest
          return PieChartSectionData(
            color: colors[idx % colors.length],
            value: (data['total'] as num).toDouble(),
            title: isSelected ? '${data['_id']}' : '',
            radius: isSelected ? 50 : 45,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieLegend(List catStats) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.teal];
    return Column(
      children: catStats.asMap().entries.map((entry) {
        final idx = entry.key;
        final data = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[idx % colors.length], shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(data['_id'] ?? 'Other', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
              Text(
                CurrencyUtils.format((data['total'] as num).toDouble()),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeframeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _timeframe,
          items: const [
            DropdownMenuItem(value: 'last7days', child: Text('7 Days', style: TextStyle(fontSize: 11))),
            DropdownMenuItem(value: 'last30days', child: Text('30 Days', style: TextStyle(fontSize: 11))),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _timeframe = val);
              _refreshData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final adminName = user?['name'] ?? 'Admin';
    final adminEmail = user?['email'] ?? 'admin@example.com';
    final initial = adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A';

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings, color: AppColors.primaryStart),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Admin Control',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Admin Profile Section
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Logged in as: $adminName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              adminEmail,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.dashboard_rounded, 'Overview', true, () => Navigator.pop(context)),
          _buildDrawerItem(Icons.history_edu_rounded, 'Transaction Feed', false, () => Navigator.pushNamed(context, '/admin/transactions')),
          const Spacer(),
          const Divider(),
          _buildDrawerItem(Icons.logout_rounded, 'Sign Out', false, () {
            _showLogoutConfirmation(context);
          }, isError: true),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool active, VoidCallback onTap, {bool isError = false}) {
    return ListTile(
      leading: Icon(icon, size: 22, color: isError ? Colors.red : (active ? AppColors.primaryStart : AppColors.textSecondary)),
      title: Text(title, style: TextStyle(fontSize: 14, color: isError ? Colors.red : (active ? AppColors.primaryStart : AppColors.textPrimary), fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      onTap: onTap,
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
                    Provider.of<AuthProvider>(context, listen: false).logout();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
}
