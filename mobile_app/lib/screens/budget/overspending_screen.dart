import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';

class OverspendingScreen extends StatefulWidget {
  const OverspendingScreen({super.key});

  @override
  _OverspendingScreenState createState() => _OverspendingScreenState();
}

class _OverspendingScreenState extends State<OverspendingScreen> {
  bool isLoading = true;
  Map<String, dynamic>? analysisData;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchAnalysis();
  }

  Future<void> _fetchAnalysis() async {
    try {
      final data = await ApiService.getOverspendingAnalysis();
      if (mounted) {
        setState(() {
          analysisData = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overspending Analysis'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recommendations Section
                      const Text(
                        'Insights & Recommendations',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildRecommendationsList(analysisData?['recommendations'] as List?),
                      
                      const SizedBox(height: 32),

                      // Trends Section
                      const Text(
                        'Spending Trends (Last 3 Months)',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildTrendsChart(analysisData?['trends'] as List?),
                    ],
                  ),
                ),
    );
  }

  Widget _buildRecommendationsList(List<dynamic>? recommendations) {
    if (recommendations == null || recommendations.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Expanded(child: Text('Great job! You are within your budget limits.')),
            ],
          ),
        ),
      );
    }

    return Column(
      children: recommendations.map((rec) {
        final severity = rec['severity'] ?? 'medium';
        final color = severity == 'high' ? Colors.red : Colors.orange;
        final icon = severity == 'high' ? Icons.warning : Icons.info;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(side: BorderSide(color: color.withOpacity(0.5)), borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        severity.toString().toUpperCase(),
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(rec['message'] ?? '', style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrendsChart(List<dynamic>? trends) {
    if (trends == null || trends.isEmpty) {
      return const Center(child: Text('No trend data available.'));
    }

    // Reverse trends to show oldest to newest
    final reversedTrends = List.from(trends.reversed);

    return SizedBox(
      height: 250,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: reversedTrends.map((e) => (e['spent'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
              barGroups: reversedTrends.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final spent = (item['spent'] as num).toDouble();
                final limit = (item['limit'] as num).toDouble();
                final isOverspent = spent > limit;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: spent,
                      color: isOverspent ? Colors.red : Colors.green,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: limit > 0 ? limit : spent * 1.5, // approximate background logic
                        color: Colors.grey.shade200,
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < reversedTrends.length && index >= 0) {
                        final item = reversedTrends[index];
                        final monthName = _getMonthName(item['month']);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(monthName, style: const TextStyle(fontSize: 12)),
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
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
