import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../utils/currency_utils.dart';
import 'package:intl/intl.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchAllTransactions();
    });
  }

  void _showRevokeDialog(BuildContext context, String txId, String category, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Transaction?'),
        content: Text('This will permanently delete the $category transaction of ${CurrencyUtils.format(amount)}. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await Provider.of<AdminProvider>(context, listen: false).revokeTransaction(txId);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction successfully revoked')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm Revoke', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final allTransactions = adminProvider.transactions;
    
    final filteredTransactions = allTransactions.where((tx) {
      final category = (tx['category'] ?? '').toLowerCase();
      final userName = (tx['userId']?['name'] ?? '').toLowerCase();
      return category.contains(_searchQuery.toLowerCase()) || userName.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaction Monitor'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by category or user name...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryStart),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: adminProvider.isLoading && allTransactions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
                  width: double.infinity,
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredTransactions.length} Global Transactions',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const Icon(Icons.filter_list_rounded, size: 16, color: AppColors.primaryStart),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = filteredTransactions[index];
                      final isIncome = tx['type'] == 'income';
                      final date = DateTime.parse(tx['date'] ?? DateTime.now().toIso8601String());
                      final amountColor = isIncome ? Colors.green : Colors.red;
                      
                      return CustomCard(
                        margin: const EdgeInsets.only(bottom: AppSpacing.m),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: amountColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                color: amountColor,
                                size: 24,
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    tx['category'] ?? 'General',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Text(
                                  '${isIncome ? '+' : '-'} ${CurrencyUtils.format((tx['amount'] ?? 0.0).toDouble())}',
                                  style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              '${DateFormat('MMM dd, yyyy').format(date)} • ${tx['userId']?['name'] ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            children: [
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.m),
                                child: Column(
                                  children: [
                                    _buildInfoRow('User Email:', tx['userId']?['email'] ?? 'N/A'),
                                    _buildInfoRow('Note:', tx['note'] ?? 'No notes provided'),
                                    _buildInfoRow('Transaction ID:', tx['_id'] ?? 'N/A'),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {},
                                            icon: const Icon(Icons.info_outline, size: 16),
                                            label: const Text('View Detail'),
                                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _showRevokeDialog(
                                              context, 
                                              tx['_id'], 
                                              tx['category'] ?? 'General', 
                                              (tx['amount'] ?? 0.0).toDouble()
                                            ),
                                            icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.white),
                                            label: const Text('Revoke', style: TextStyle(color: Colors.white)),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
