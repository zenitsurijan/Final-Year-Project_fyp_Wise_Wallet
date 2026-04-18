import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryPieChart extends StatelessWidget {
  final List<dynamic> categories;
  final double radius;

  const CategoryPieChart({
    super.key,
    required this.categories,
    this.radius = 50,
  });

  // High-contrast professional palette
  static const List<Color> chartColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEF4444), // Red
    Color(0xFF06B6D4), // Cyan
  ];

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: Text('No expense data available'));
    }

    final double totalAmount = categories.fold(0.0, (sum, cat) => sum + (cat['total'] as num).toDouble());

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 65,
                sections: categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  final amount = (category['total'] as num).toDouble();
                  final percentage = (amount / totalAmount * 100);
                  
                  final color = chartColors[index % chartColors.length];

                  return PieChartSectionData(
                    color: color,
                    value: amount,
                    title: percentage > 10 ? '${percentage.toStringAsFixed(1)}%' : '',
                    radius: radius,
                    titlePositionPercentageOffset: 0.5,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    badgeWidget: percentage <= 10 ? _buildSmallSectionBadge(percentage, color) : null,
                    badgePositionPercentageOffset: 1.35,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Legend with consistent spacing
        Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: categories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final color = chartColors[index % chartColors.length];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color, 
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category['_id'],
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSmallSectionBadge(double percentage, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class IncomeExpenseLineChart extends StatelessWidget {
  final List<dynamic> trends;

  const IncomeExpenseLineChart({super.key, required this.trends});

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const Center(child: Text('No trend data available'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value % 5 != 0 && value != 1) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(value.toInt().toString(), style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: trends.map((t) => FlSpot((t['_id'] as num).toDouble(), (t['income'] as num).toDouble())).toList(),
            isCurved: true,
            color: Colors.teal,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.teal.withOpacity(0.3), Colors.teal.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: trends.map((t) => FlSpot((t['_id'] as num).toDouble(), (t['expense'] as num).toDouble())).toList(),
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.orange.withOpacity(0.3), Colors.orange.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlyBarChart extends StatelessWidget {
  final List<dynamic> monthlyData;

  const MonthlyBarChart({super.key, required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return const Center(child: Text('No monthly data available'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(),
        barGroups: monthlyData.map((m) {
          final monthIdx = m['_id'] as int;
          return BarChartGroupData(
            x: monthIdx,
            barRods: [
              BarChartRodData(
                toY: (m['income'] as num).toDouble(),
                color: Colors.teal.shade300,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: (m['expense'] as num).toDouble(),
                color: Colors.orange.shade300,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                if (value >= 1 && value <= 12) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(months[value.toInt() - 1], style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  double _getMaxY() {
    double max = 0;
    for (var m in monthlyData) {
      if ((m['income'] as num) > max) max = (m['income'] as num).toDouble();
      if ((m['expense'] as num) > max) max = (m['expense'] as num).toDouble();
    }
    return max * 1.2;
  }
}
