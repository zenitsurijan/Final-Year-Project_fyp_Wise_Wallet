import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminProvider with ChangeNotifier {
  bool _isLoading = false;
  Map<String, dynamic> _stats = {};
  List<dynamic> _users = [];
  List<dynamic> _transactions = [];
  Map<String, dynamic> _analytics = {};
  List<dynamic> _systemLogs = [];

  bool get isLoading => _isLoading;
  Map<String, dynamic> get stats => _stats;
  List<dynamic> get users => _users;
  List<dynamic> get transactions => _transactions;
  Map<String, dynamic> get analytics => _analytics;
  List<dynamic> get systemLogs => _systemLogs;

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService.getAdminStats();
      if (result['success'] == true) {
        _stats = result['stats'] ?? {};
      }
    } catch (e) {
      print('Error fetching admin stats: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllUsers({int page = 1}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService.getAdminUsers(page: page);
      if (result['success'] == true) {
        _users = result['users'] ?? [];
      }
    } catch (e) {
      print('Error fetching admin users: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllTransactions({int page = 1}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService.getAdminTransactions(page: page);
      if (result['success'] == true) {
        _transactions = result['transactions'] ?? [];
      }
    } catch (e) {
      print('Error fetching admin transactions: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAnalytics({String timeframe = 'last30days'}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService.getAdminAnalytics(timeframe: timeframe);
      if (result['success'] == true) {
        _analytics = result['analytics'] ?? {};
      }
    } catch (e) {
      print('Error fetching admin analytics: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSystemLogs({int page = 1}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService.getAdminLogs(page: page);
      if (result['success'] == true) {
        _systemLogs = result['logs'] ?? [];
      }
    } catch (e) {
      print('Error fetching system logs: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateUserRole(String userId, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService.updateUserRole(userId, role);
      if (result['success'] == true) {
        final index = _users.indexWhere((u) => u['_id'] == userId);
        if (index != -1) {
          _users[index]['role'] = role;
        }
        await fetchDashboardStats(); // Refresh stats
        return true;
      }
    } catch (e) {
      print('Error updating user role: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService.toggleUserStatus(userId, isActive);
      if (result['success'] == true) {
        final index = _users.indexWhere((u) => u['_id'] == userId);
        if (index != -1) {
          _users[index]['isActive'] = isActive;
        }
        return true;
      }
    } catch (e) {
      print('Error toggling user status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> revokeTransaction(String txId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService.deleteTransactionAdmin(txId);
      if (result['success'] == true) {
        _transactions.removeWhere((tx) => tx['_id'] == txId);
        await fetchDashboardStats(); // Refresh stats
        return true;
      }
    } catch (e) {
      print('Error revoking transaction: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }
}
