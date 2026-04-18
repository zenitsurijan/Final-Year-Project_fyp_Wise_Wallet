import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';
import '../utils/currency_utils.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  double _averageDailySpending = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMonthTransactions(_focusedDay);
    });
  }

  Future<void> _loadMonthTransactions(DateTime month) async {
    setState(() => _isLoading = true);
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    await provider.fetchTransactions(
      startDate: firstDay,
      endDate: lastDay,
      limit: 500,
    );
    _calculateAverageSpending(provider.transactions);
    setState(() => _isLoading = false);
  }

  void _calculateAverageSpending(List<Transaction> transactions) {
    final expenses = transactions.where((t) => t.type == 'expense');
    if (expenses.isEmpty) {
      _averageDailySpending = 50;
      return;
    }
    final dailyTotals = <String, double>{};
    for (final t in expenses) {
      final key = '${t.date.year}-${t.date.month}-${t.date.day}';
      dailyTotals[key] = (dailyTotals[key] ?? 0) + t.amount;
    }
    if (dailyTotals.isEmpty) {
      _averageDailySpending = 50;
      return;
    }
    final totalSpending = dailyTotals.values.fold(0.0, (sum, v) => sum + v);
    _averageDailySpending = totalSpending / dailyTotals.length;
  }

  Color _getDayColor(List<Transaction> transactions) {
    if (transactions.isEmpty) return Colors.transparent;
    double totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold(0, (sum, t) => sum + t.amount);
    if (totalExpense == 0) return Colors.green.withAlpha(80);
    final lowThreshold = _averageDailySpending * 0.5;
    final highThreshold = _averageDailySpending * 1.5;
    
    if (totalExpense < lowThreshold) return Colors.green.withAlpha(100);
    if (totalExpense < highThreshold) return Colors.yellow.withAlpha(100);
    return Colors.red.withAlpha(100);
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() => _focusedDay = focusedDay);
    _loadMonthTransactions(focusedDay);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.indigo.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.indigo.shade900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _focusedDay) {
      setState(() {
        _focusedDay = picked;
        _selectedDay = picked;
      });
      _loadMonthTransactions(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Transaction Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Select Month',
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to Today',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
              _loadMonthTransactions(DateTime.now());
            },
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildModernLegend(),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  rowHeight: 52,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  onPageChanged: _onPageChanged,
                  eventLoader: (day) {
                    return provider.getTransactionsForDate(day);
                  },
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Colors.indigo.shade300),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Colors.indigo.shade300),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13),
                    weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13),
                  ),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: const TextStyle(fontWeight: FontWeight.w500),
                    weekendTextStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                    todayDecoration: BoxDecoration(color: Colors.indigo.shade100, shape: BoxShape.circle),
                    todayTextStyle: TextStyle(color: Colors.indigo.shade900, fontWeight: FontWeight.bold),
                    selectedDecoration: const BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                    markerDecoration: const BoxDecoration(color: Colors.transparent),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return null;
                      final transactions = events.cast<Transaction>();
                      final dayColor = _getDayColor(transactions);
                      return Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.all(6.0),
                          decoration: BoxDecoration(
                            color: dayColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                    defaultBuilder: (context, date, focusedDay) {
                      final transactions = provider.getTransactionsForDate(date);
                      if (transactions.isEmpty) return null;
                      final dayColor = _getDayColor(transactions);
                      return Container(
                        margin: const EdgeInsets.all(5.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: dayColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '${date.day}',
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildTransactionList(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
          if (result == true) {
            _loadMonthTransactions(_focusedDay);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildModernLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('Daily Spending Legend', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildLegendChip('Low', Colors.green, '< ${CurrencyUtils.format((_averageDailySpending * 0.5))}'),
              _buildLegendChip('Moderate', Colors.amber.shade700, '${CurrencyUtils.format((_averageDailySpending * 0.5))} - ${CurrencyUtils.format((_averageDailySpending * 1.5))}'),
              _buildLegendChip('High', Colors.red, '> ${CurrencyUtils.format((_averageDailySpending * 1.5))}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip(String label, Color color, String range) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color.withAlpha(200), shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.withOpacity(0.9))),
              Text(range, style: TextStyle(fontSize: 9, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(TransactionProvider provider) {
    final transactions = provider.getTransactionsForDate(_selectedDay!);
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No transactions on ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    final income = transactions.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
    final expense = transactions.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.indigo.shade500, Colors.indigo.shade700]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.indigo.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryWhiteColumn('Income', '+ ${CurrencyUtils.format(income)}'),
                Container(width: 1, height: 30, color: Colors.white24),
                _buildSummaryWhiteColumn('Expense', '- ${CurrencyUtils.format(expense)}'),
                Container(width: 1, height: 30, color: Colors.white24),
                _buildSummaryWhiteColumn('Net', CurrencyUtils.format((income - expense))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final isIncome = transaction.type == 'income';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (isIncome ? Colors.green : Colors.red).withAlpha(30),
                      child: Icon(
                        isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(transaction.customCategory ?? transaction.category),
                    subtitle: transaction.description.isNotEmpty 
                        ? Text(transaction.description, maxLines: 1, overflow: TextOverflow.ellipsis)
                        : null,
                    trailing: Text(
                      '${isIncome ? '+' : '-'} ${CurrencyUtils.format(transaction.amount)}',
                      style: TextStyle(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddTransactionScreen(transaction: transaction)),
                      );
                      if (result == true) {
                        _loadMonthTransactions(_focusedDay);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryWhiteColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          value, 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
