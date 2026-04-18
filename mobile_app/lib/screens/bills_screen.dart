import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bills_provider.dart';
import '../utils/currency_utils.dart';

class BillsListScreen extends StatefulWidget {
  const BillsListScreen({super.key});

  @override
  State<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends State<BillsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BillsProvider>(context, listen: false).fetchBills();
    });
  }

  void _showAddBillDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String recurrence = 'monthly';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Recurring Bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Bill Name (e.g. Rent)'),
                ),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(labelText: 'Amount', prefixText: CurrencyUtils.symbol),
                  keyboardType: TextInputType.number,
                ),
                ListTile(
                  title: Text("Due Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                ),
                DropdownButtonFormField<String>(
                  value: recurrence,
                  items: ['none', 'weekly', 'monthly', 'yearly']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                      .toList(),
                  onChanged: (val) => setState(() => recurrence = val!),
                  decoration: const InputDecoration(labelText: 'Recurrence'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || amountController.text.isEmpty) return;
                
                final success = await Provider.of<BillsProvider>(context, listen: false).addBill({
                  'name': nameController.text,
                  'amount': double.parse(amountController.text),
                  'dueDate': selectedDate.toIso8601String(),
                  'recurrence': recurrence,
                });

                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Bill added successfully'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billsProvider = Provider.of<BillsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Bills')),
      body: billsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : billsProvider.bills.isEmpty
              ? const Center(child: Text('No bills added yet'))
              : ListView.builder(
                  itemCount: billsProvider.bills.length,
                  itemBuilder: (context, index) {
                    final bill = billsProvider.bills[index];
                    final dueDate = DateTime.parse(bill['dueDate']);
                    final isOverdue = dueDate.isBefore(DateTime.now()) && !bill['isPaid'];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isOverdue ? Colors.red : Colors.blue,
                          child: const Icon(Icons.receipt_long, color: Colors.white),
                        ),
                        title: Text(bill['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Due: ${DateFormat('MMM dd, yyyy').format(dueDate)} • ${bill['recurrence']}"),
                        trailing: Text(
                          CurrencyUtils.format((bill['amount'] as num).toDouble()),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isOverdue ? Colors.red : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBillDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
