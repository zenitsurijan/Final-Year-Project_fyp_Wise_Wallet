import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/savings_provider.dart';
import '../../models/savings_goal_model.dart';
import 'add_savings_goal_screen.dart';
import 'savings_goal_detail_screen.dart';
import '../../utils/currency_utils.dart';
import '../../theme/app_theme.dart';

class SavingsGoalListScreen extends StatefulWidget {
  const SavingsGoalListScreen({super.key});

  @override
  State<SavingsGoalListScreen> createState() => _SavingsGoalListScreenState();
}

class _SavingsGoalListScreenState extends State<SavingsGoalListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SavingsProvider>(context, listen: false).fetchGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<SavingsProvider>(context, listen: false).fetchGoals(),
          ),
        ],
      ),
      body: Consumer<SavingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)));
          }

          if (provider.goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.savings_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No savings goals yet', style: TextStyle(color: Colors.grey, fontSize: 18)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _navigateToAddGoal(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Goal'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.goals.length,
            itemBuilder: (context, index) {
              final goal = provider.goals[index];
              return _buildGoalCard(context, goal);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddGoal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, SavingsGoal goal) {
    final progress = goal.insights.progressPercentage / 100;
    final color = goal.isFamilyGoal ? Colors.orange : AppColors.primaryStart;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToGoalDetail(context, goal),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (goal.isFamilyGoal)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Family Goal',
                              style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${goal.insights.progressPercentage}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyUtils.format(goal.currentAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Goal: ${CurrencyUtils.format(goal.targetAmount)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_month, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${goal.insights.daysRemaining} days left',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    '${CurrencyUtils.format(goal.insights.dailyNeeded)}/day needed',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddGoal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSavingsGoalScreen()),
    );
  }

  void _navigateToGoalDetail(BuildContext context, SavingsGoal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SavingsGoalDetailScreen(goal: goal)),
    );
  }
}
