import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/category_model.dart' as cat_model;
import '../services/api_service.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _summary = {};
  List<String> _categories = [];
  List<String> _customCategories = [];

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get summary => _summary;
  List<String> get categories => _categories;
  List<String> get customCategories => _customCategories;

  Future<void> fetchTransactions({
    String? type,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    bool? hasReceipt,
    String? search,
    double? minAmount,
    double? maxAmount,
    int page = 1,
    int limit = 20,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.getTransactions(
        type: type,
        category: category,
        startDate: startDate,
        endDate: endDate,
        hasReceipt: hasReceipt,
        search: search,
        minAmount: minAmount,
        maxAmount: maxAmount,
        page: page,
        limit: limit,
      );

      if (result['success'] == true) {
        final List<dynamic> data = result['transactions'] ?? [];
        _transactions = data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        _error = result['message'] ?? 'Failed to fetch transactions';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Separate list for Home Screen to avoid conflict with main list
  List<Transaction> _recentTransactions = [];
  List<Transaction> get recentTransactions => _recentTransactions;

  Future<void> fetchRecentTransactions() async {
    try {
      final result = await ApiService.getTransactions(page: 1, limit: 5);
      if (result['success'] == true) {
        final List<dynamic> data = result['transactions'] ?? [];
        _recentTransactions = data.map((json) => Transaction.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching recent transactions: $e');
    }
  }

  Future<Map<String, dynamic>> uploadReceipt(List<int> bytes, String filename) async {
    try {
      return await ApiService.uploadImage(bytes, filename);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createTransaction(Transaction transaction) async {
    try {
      final result = await ApiService.createTransaction(transaction.toJson());
      if (result['success'] == true) {
        final newTransaction = Transaction.fromJson(result['transaction']);
        _transactions.insert(0, newTransaction);
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateTransaction(String id, Map<String, dynamic> data) async {
    try {
      final result = await ApiService.updateTransaction(id, data);
      if (result['success'] == true) {
        final index = _transactions.indexWhere((t) => t.id == id);
        if (index != -1) {
          _transactions[index] = Transaction.fromJson(result['transaction']);
          notifyListeners();
        }
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteTransaction(String id) async {
    try {
      final result = await ApiService.deleteTransaction(id);
      if (result['success'] == true) {
        _transactions.removeWhere((t) => t.id == id);
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> fetchSummary({DateTime? startDate, DateTime? endDate}) async {
    try {
      final result = await ApiService.getTransactionSummary(
        startDate: startDate,
        endDate: endDate,
      );
      if (result['success'] == true) {
        _summary = result['summary'] ?? {};
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> _loadCategoriesData() async {
    try {
      final result = await ApiService.getCategories();
      if (result['success'] == true) {
        final List<dynamic> catList = result['categories'] ?? [];
        final List<cat_model.Category> cats = catList.map((c) => cat_model.Category.fromJson(c)).toList();
        
        _categories = cats.map((c) => c.name).toList().cast<String>();
        _customCategories = cats.where((c) => !c.isDefault).map((c) => c.name).toList().cast<String>();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> fetchCategories() async {
    await _loadCategoriesData();
  }

  List<Transaction> getTransactionsForDate(DateTime date) {
    return _transactions.where((t) =>
      t.date.year == date.year &&
      t.date.month == date.month &&
      t.date.day == date.day
    ).toList();
  }

  void clear() {
    _transactions = [];
    _recentTransactions = [];
    _summary = {};
    _error = null;
    _categories = [];
    _customCategories = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
