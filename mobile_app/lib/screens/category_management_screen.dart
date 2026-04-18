import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/category_model.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  bool _isLoading = true;
  List<Category> _categories = [];
  String _selectedType = 'expense';
  final _controller = TextEditingController();

  // Default categories from backend logic, we can't delete these
  final List<String> _defaultCategories = [
    'Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Education', 'Income'
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getCategories();
      if (result['success'] == true) {
        final List<dynamic> catList = result['categories'] ?? [];
        setState(() {
          _categories = catList.map((c) => Category.fromJson(c)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addCategory() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    if (_categories.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category already exists')));
      return;
    }

    try {
      final result = await ApiService.addCategory(name, 'category', _selectedType);
      if (result['success'] == true) {
        _controller.clear();
        _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category added')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to add')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteCategory(String category) async {
    // Only allow ensuring delete confirming dialogue
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "$category"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await ApiService.deleteCategory(category);
      if (result['success'] == true) {
        _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category deleted')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to delete')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Separate custom from default for UI
    final customCategories = _categories.where((c) => !c.isDefault).toList();
    final defaultCategories = _categories.where((c) => c.isDefault).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Categories')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Expense')),
                      ButtonSegment(value: 'income', label: Text('Income')),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (val) => setState(() => _selectedType = val.first),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            labelText: 'New Category Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _addCategory,
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (customCategories.isNotEmpty) ...[
                        const Text('Custom Categories',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        const SizedBox(height: 8),
                        ...customCategories.map((cat) => Card(
                              child: ListTile(
                                title: Text(cat.name),
                                subtitle: Text(cat.type.toUpperCase(), style: const TextStyle(fontSize: 12)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteCategory(cat.name),
                                ),
                              ),
                            )),
                        const SizedBox(height: 24),
                      ],
                      const Text('Default Categories (Cannot Delete)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      ...defaultCategories.map((cat) => Card(
                            color: Colors.grey.shade50,
                            child: ListTile(
                              title: Text(cat.name, style: TextStyle(color: Colors.grey.shade700)),
                              subtitle: Text(cat.type.toUpperCase(), style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                              leading: const Icon(Icons.lock, size: 16, color: Colors.grey),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
