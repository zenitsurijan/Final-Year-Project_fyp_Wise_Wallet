import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../utils/currency_utils.dart';

class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({super.key});

  @override
  _BudgetSetupScreenState createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  double totalBudget = 0;
  Map<String, double> categoryBudgets = {};
  String? _budgetId;

  bool isLoading = false;
  String selectedMonth = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);
    try {
      // 1. Fetch available categories
      final catResult = await ApiService.getCategories();
      if (catResult['success'] == true) {
        final List<dynamic> catsData = catResult['categories'];
        setState(() {
          for (var item in catsData) {
            final name = item['name'] ?? '';
            if (name != 'Income' && item['type'] == 'expense') { // Don't budget for income here
              categoryBudgets[name] = 0;
            }
          }
        });
      }

      // 2. Fetch existing budget
      final budgetResult = await ApiService.getPersonalBudget(
        DateTime.now().month, 
        DateTime.now().year
      );

      if (budgetResult['success'] == true) {
        final data = budgetResult['data'];
        setState(() {
          _budgetId = data['_id'];
          totalBudget = (data['total_budget'] as num).toDouble();
          if (data['categories'] != null && data['categories'].isNotEmpty) {
            for (var cat in data['categories']) {
              categoryBudgets[cat['category_name']] = (cat['budget_limit'] as num).toDouble();
            }
          }
        });
      }
    } catch (e) {
      print('Error initializing budget setup: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
  bool showCategoryAllocation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Monthly Budget'),
        actions: [
          TextButton(
            onPressed: isLoading ? null : saveBudget,
            child: const Text('Save', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                   // Month selector
                  const Text('Budget for', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(selectedMonth, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  // Total budget input
                  TextFormField(
                    initialValue: totalBudget > 0 ? totalBudget.toStringAsFixed(0) : '',
                    decoration: InputDecoration(
                      labelText: 'Total Monthly Budget',
                      prefixText: CurrencyUtils.symbol,
                      border: const OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    keyboardType: TextInputType.number,
                    validator: (val) => (val == null || double.tryParse(val) == null || double.parse(val) <= 0)
                        ? 'Enter valid amount'
                        : null,
                    onChanged: (val) {
                      setState(() {
                        totalBudget = double.tryParse(val) ?? 0;
                        if (showCategoryAllocation) {
                          _distributeBudget();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Toggle for Category Breakdown
                  SwitchListTile(
                    title: const Text('Specific Category Allocation', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Split your budget into specific categories'),
                    value: showCategoryAllocation,
                    onChanged: (val) {
                      setState(() {
                        showCategoryAllocation = val;
                        if (val) _distributeBudget();
                      });
                    },
                  ),

                  if (showCategoryAllocation) ...[
                    const Divider(height: 32),
                    const Text('Category Breakdown (Auto-Distributed)', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 16),
                    ...categoryBudgets.keys.map((category) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color: Colors.blue.shade50.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), 
                          side: BorderSide(color: Colors.blue.shade100)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              Text(
                                CurrencyUtils.format(categoryBudgets[category]!),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],

                  if (_budgetId != null) ...[
                    const SizedBox(height: 48),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : _deleteBudget,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Delete This Budget', 
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _deleteBudget() async {
    if (_budgetId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: const Text('Are you sure you want to remove your budget settings for this month? Your transactions will not be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);
    try {
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      final result = await budgetProvider.deletePersonalBudget(_budgetId!);
      
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Budget deleted successfully'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to delete budget');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => isLoading = true);

    try {
      List<Map<String, dynamic>> categories = [];
      if (showCategoryAllocation) {
        _distributeBudget();
        categories = categoryBudgets.entries
            .map((e) => {
                  'category_name': e.key,
                  'budget_limit': e.value,
                })
            .toList();
      }

      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      final result = await budgetProvider.setBudget({
        'month': selectedMonth,
        'categories': categories,
        'total_budget': totalBudget,
      });

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Budget saved successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to save budget');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _distributeBudget() {
    if (totalBudget <= 0 || categoryBudgets.isEmpty) {
      for (var key in categoryBudgets.keys) {
        categoryBudgets[key] = 0;
      }
      return;
    }

    final count = categoryBudgets.length;
    final amountPerCategory = totalBudget / count;
    
    for (var key in categoryBudgets.keys) {
      categoryBudgets[key] = amountPerCategory;
    }
  }
}
