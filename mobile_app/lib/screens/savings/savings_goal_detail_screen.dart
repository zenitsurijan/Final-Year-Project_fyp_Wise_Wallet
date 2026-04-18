import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/savings_provider.dart';
import '../../models/savings_goal_model.dart';
import '../../utils/currency_utils.dart';
import '../../theme/app_theme.dart';

class SavingsGoalDetailScreen extends StatelessWidget {
  final SavingsGoal goal;

  const SavingsGoalDetailScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = goal.insights.progressPercentage / 100;
    final color = goal.isFamilyGoal ? Colors.orange : AppColors.primaryStart;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Circular Progress
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 15,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200, width: 1),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${goal.insights.progressPercentage}%',
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color),
                      ),
                      const Text('Saved', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Motivation Message
            Card(
              color: color.withOpacity(0.05),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.tips_and_updates, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        goal.insights.motivation,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildStatTile('Current', CurrencyUtils.format(goal.currentAmount), color),
                _buildStatTile('Target', CurrencyUtils.format(goal.targetAmount), Colors.black87),
                _buildStatTile('Needed', CurrencyUtils.format(goal.insights.amountNeeded), Colors.redAccent),
                _buildStatTile('Days Left', '${goal.insights.daysRemaining}', Colors.blueGrey),
              ],
            ),
            const SizedBox(height: 32),

            // Saving Recommendations
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Savings Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            _buildRecommendationItem(Icons.today, 'Daily', CurrencyUtils.format(goal.insights.dailyNeeded), color),
            _buildRecommendationItem(Icons.calendar_view_week, 'Weekly', CurrencyUtils.format(goal.insights.weeklyNeeded), color),
            _buildRecommendationItem(Icons.calendar_month, 'Monthly', CurrencyUtils.format(goal.insights.monthlyNeeded), color),

            const SizedBox(height: 32),

            // Contribution History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Contribution History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _showContributionDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (goal.contributions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No contributions yet', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: goal.contributions.length,
                itemBuilder: (context, index) {
                  final contribution = goal.contributions.reversed.toList()[index];
                  return ListTile(
                    dense: true,
                    leading: const CircleAvatar(child: Icon(Icons.download, size: 16)),
                    title: Text(CurrencyUtils.format(contribution.amount)),
                    subtitle: Text(contribution.note.isNotEmpty ? contribution.note : 'No note'),
                    trailing: Text(
                      '${contribution.date.day}/${contribution.date.month}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: FilledButton(
          onPressed: () => _showContributionDialog(context),
          style: FilledButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text('Add Contribution'),
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(IconData icon, String cycle, String amount, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(cycle),
        trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  void _showContributionDialog(BuildContext context) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Contribution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount', prefixText: CurrencyUtils.symbol),
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                final result = await Provider.of<SavingsProvider>(context, listen: false)
                    .addContribution(goal.id, amount, noteController.text);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (result['success'] == true) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contribution added!')));
                     // The provider will refresh the list, so we might need to pop and show the new detail if wanted, 
                     // but for now, the UI will reflect changes if it's observing the provider.
                     // Since this is a StatelessWidget using a passed goal, it won't update automatically 
                     // unless we pop back to the list and re-enter, or make it observe.
                     Navigator.of(context).pop(); 
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final result = await Provider.of<SavingsProvider>(context, listen: false).deleteGoal(goal.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (result['success'] == true) {
                  Navigator.pop(context); // Go back to list
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
