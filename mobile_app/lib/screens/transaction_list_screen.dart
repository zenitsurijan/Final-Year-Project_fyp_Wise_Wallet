import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';
import '../widgets/authenticated_image.dart';
import '../utils/currency_utils.dart';

import '../theme/app_theme.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/custom_card.dart';
import '../widgets/loading_shimmer.dart';
import '../utils/icon_mapping.dart';

class TransactionListScreen extends StatefulWidget {
  final String? filterType;
  final bool? hasReceipt;

  const TransactionListScreen({super.key, this.filterType, this.hasReceipt});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _searchController = TextEditingController();
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;
  bool _showFilterPanel = false;

  final List<String> _allCategories = [
    'Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 
    'Health', 'Education', 'Salary', 'Freelance', 'Investment', 'Gift', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    double? minAmount;
    double? maxAmount;
    
    if (_minAmountController.text.isNotEmpty) {
      minAmount = double.tryParse(_minAmountController.text);
    }
    if (_maxAmountController.text.isNotEmpty) {
      maxAmount = double.tryParse(_maxAmountController.text);
    }

    await Provider.of<TransactionProvider>(context, listen: false).fetchTransactions(
      type: widget.filterType,
      hasReceipt: widget.hasReceipt,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      startDate: _startDate,
      endDate: _endDate,
      category: _selectedCategory,
      minAmount: minAmount,
      maxAmount: maxAmount,
    );
  }

  void _applyFilters() {
    _loadTransactions();
    setState(() => _showFilterPanel = false);
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedCategory = null;
      _minAmountController.clear();
      _maxAmountController.clear();
      _searchController.clear();
    });
    _loadTransactions();
  }

  bool get _hasActiveFilters => _startDate != null || _selectedCategory != null || _minAmountController.text.isNotEmpty || _maxAmountController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.filterType != null ? '${widget.filterType!.toUpperCase()} History' : 'Transactions'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: _hasActiveFilters ? AppColors.accent : null),
            onPressed: () => setState(() => _showFilterPanel = !_showFilterPanel),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.large),
                boxShadow: AppShadows.small,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(icon: const Icon(Icons.close), onPressed: () { _searchController.clear(); _loadTransactions(); }) 
                    : null,
                ),
                onChanged: (_) => _loadTransactions(),
              ),
            ),
          ),

          if (_showFilterPanel) _buildFilterSection(),

          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.transactions.isEmpty) {
                  return ListView.builder(
                    itemCount: 5,
                    itemBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: 4),
                      child: LoadingShimmer.listTile(),
                    ),
                  );
                }

                if (provider.transactions.isEmpty) {
                  return const Center(child: Text("No transactions found."));
                }

                // Group by Date logic
                final grouped = _groupTransactions(provider.transactions);

                return RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final item = grouped[index];
                      if (item is String) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      final t = item as Transaction;
                      return TransactionTile(
                        title: t.description.isNotEmpty ? t.description : t.category,
                        category: t.category,
                        amount: t.amount,
                        date: t.date,
                        icon: IconMapping.getIconData(t.category),
                        categoryColor: _getCategoryColor(t.category),
                        isExpense: t.type == 'expense',
                        onTap: () => _showTransactionDetails(t),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add-transaction');
          if (result == true) {
            _loadTransactions();
          }
        },
        backgroundColor: AppColors.primaryStart,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<dynamic> _groupTransactions(List<Transaction> transactions) {
    final List<dynamic> result = [];
    String? lastDate;
    for (var t in transactions) {
      final dateStr = "${t.date.day}/${t.date.month}/${t.date.year}";
      if (dateStr != lastDate) {
        result.add(dateStr == "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}" ? "Today" : dateStr);
        lastDate = dateStr;
      }
      result.add(t);
    }
    return result;
  }

  Color _getCategoryColor(String category) {
    // Simple logic or mapping
    if (category.toLowerCase().contains('food')) return Colors.orange;
    if (category.toLowerCase().contains('health')) return Colors.red;
    if (category.toLowerCase().contains('transport')) return Colors.blue;
    if (category.toLowerCase().contains('shopping')) return Colors.purple;
    return AppColors.primaryStart;
  }

  Widget _buildFilterSection() {
    return CustomCard(
      margin: const EdgeInsets.only(left: AppSpacing.l, right: AppSpacing.l, bottom: AppSpacing.l),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category', border: InputBorder.none),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ..._allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
              ),
              IconButton(
                onPressed: _clearFilters,
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
              ),
              ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryStart),
                child: const Text("Apply", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(Transaction t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: AppSpacing.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.description.isNotEmpty ? t.description : t.category, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                  "${t.type == 'income' ? '+' : '-'} ${CurrencyUtils.format(t.amount)}",
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: t.type == 'income' ? AppColors.income : AppColors.expense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(IconMapping.getIconData(t.category), color: AppColors.primaryStart),
              title: Text(t.category),
              subtitle: Text("${t.date.day}/${t.date.month}/${t.date.year}"),
            ),
            if (t.description.isNotEmpty) ...[
              const Divider(),
              const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(t.description, style: const TextStyle(color: AppColors.textSecondary)),
            ],
            if (t.receiptImageId != null) ...[
              const SizedBox(height: AppSpacing.m),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: AuthenticatedImage(imageId: t.receiptImageId!, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context); // Close modal
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddTransactionScreen(transaction: t)),
                      );
                      if (result == true) {
                         _loadTransactions();
                      }
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text("Edit"),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDelete(t),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error.withOpacity(0.1), foregroundColor: AppColors.error, elevation: 0),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Delete"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Transaction t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Transaction"),
        content: const Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      await Provider.of<TransactionProvider>(context, listen: false).deleteTransaction(t.id!);
      Navigator.pop(context);
      _loadTransactions();
    }
  }
}

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewReceipt;

  const _TransactionCard({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
    required this.onViewReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(
            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
          ),
        ),
        title: Text(
          transaction.customCategory ?? transaction.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}${transaction.description.isNotEmpty ? ' • ${transaction.description}' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (transaction.receiptImageId != null)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.receipt, size: 16, color: Colors.grey),
              ),
            Text(
              '${isIncome ? '+' : '-'} ${CurrencyUtils.format(transaction.amount)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                if (transaction.receiptImageId != null)
                  const PopupMenuItem(value: 'view_receipt', child: Row(children: [Icon(Icons.receipt), SizedBox(width: 8), Text('View Receipt')])),
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
              ],
              onSelected: (value) {
                if (value == 'view_receipt') onViewReceipt();
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
