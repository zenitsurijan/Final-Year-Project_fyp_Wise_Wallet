import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/budget_provider.dart';
import '../../utils/currency_utils.dart';
import 'dart:convert';

class SetFamilyBudgetScreen extends StatefulWidget {
  const SetFamilyBudgetScreen({super.key});

  @override
  _SetFamilyBudgetScreenState createState() => _SetFamilyBudgetScreenState();
}

class _SetFamilyBudgetScreenState extends State<SetFamilyBudgetScreen> {
  final TextEditingController totalBudgetController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';

  // Simple category budgets - similar to personal for consistency
  final Map<String, TextEditingController> categoryControllers = {
    'Food': TextEditingController(text: '0'),
    'Transport': TextEditingController(text: '0'),
    'Entertainment': TextEditingController(text: '0'),
    'Bills': TextEditingController(text: '0'),
    'Shopping': TextEditingController(text: '0'),
    'Healthcare': TextEditingController(text: '0'),
    'Education': TextEditingController(text: '0'),
    'Others': TextEditingController(text: '0'),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingBudget();
    });
  }

  Future<void> _loadExistingBudget() async {
    setState(() => isLoading = true);
    try {
      final now = DateTime.now();
      final provider = Provider.of<BudgetProvider>(context, listen: false);
      await provider.fetchFamilyBudget(now.month, now.year);
      
      final budget = provider.familyBudget;
      if (budget != null) {
        totalBudgetController.text = (budget['total_budget'] ?? 0).toString();
        
        final categories = budget['categories'] as List<dynamic>? ?? [];
        for (var cat in categories) {
          final name = cat['category_name'];
          final limit = cat['budget_limit'];
          if (categoryControllers.containsKey(name)) {
            categoryControllers[name]!.text = (limit ?? 0).toString();
          }
        }
      }
    } catch (e) {
      print('Error loading family budget: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> saveBudget() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Get current month
      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Prepare categories
      List<Map<String, dynamic>> categories = [];
      categoryControllers.forEach((name, controller) {
        final amount = double.tryParse(controller.text) ?? 0;
        if (amount > 0) {
          categories.add({
            'category_name': name,
            'budget_limit': amount,
          });
        }
      });

      // Prepare request body
      final body = {
        'month': month,
        'total_budget': double.tryParse(totalBudgetController.text) ?? 0,
        'categories': categories,
      };

      print('Sending family budget data: ${jsonEncode(body)}');

      final provider = Provider.of<BudgetProvider>(context, listen: false);
      final response = await provider.setFamilyBudget(body);

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Family Budget saved successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Failed to save budget';
        });
      }
    } catch (e) {
      print('Error saving family budget: $e');
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Family Budget'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.indigo),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This budget applies to the entire family. Notifications will be sent to you when members spend.',
                            style: TextStyle(color: Colors.indigo),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Error message
                  if (errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
                    ),

                  // Total Budget
                  const Text('Total Monthly Family Budget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: totalBudgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: CurrencyUtils.symbol,
                      hintText: 'Enter total budget',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Categories
                  const Text('Category Budgets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  ...categoryControllers.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: entry.value,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixText: CurrencyUtils.symbol,
                              hintText: '0',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: saveBudget,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save Family Budget', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    totalBudgetController.dispose();
    categoryControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}
