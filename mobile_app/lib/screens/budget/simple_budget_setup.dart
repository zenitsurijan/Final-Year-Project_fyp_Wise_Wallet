import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/currency_utils.dart';
import 'dart:convert';

class SimpleBudgetSetup extends StatefulWidget {
  const SimpleBudgetSetup({super.key});

  @override
  _SimpleBudgetSetupState createState() => _SimpleBudgetSetupState();
}

class _SimpleBudgetSetupState extends State<SimpleBudgetSetup> {
  final TextEditingController totalBudgetController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';

  // Simple category budgets
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

      print('Sending budget data: ${jsonEncode(body)}'); // Debug log

      // Using ApiService for consistency and safe header/token handling
      final response = await ApiService.setBudget(body);

      if (response['success'] == true) {
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
        setState(() {
          errorMessage = response['message'] ?? 'Failed to save budget';
        });
      }
    } catch (e) {
      print('Error saving budget: $e'); // Debug log
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
        title: const Text('Set Budget'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const Text('Total Monthly Budget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save Budget', style: TextStyle(fontSize: 18)),
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
