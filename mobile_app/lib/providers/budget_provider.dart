import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BudgetProvider with ChangeNotifier {
  Map<String, dynamic>? _personalBudget;
  Map<String, dynamic>? _familyBudget; // For head view
  List<dynamic> _familyBreakdown = [];
  Map<String, dynamic>? _overspendingAnalysis;
  List<dynamic> _alertHistory = [];
  bool _isLoading = false;

  Map<String, dynamic>? get personalBudget => _personalBudget;
  Map<String, dynamic>? get familyBudget => _familyBudget;
  List<dynamic> get familyBreakdown => _familyBreakdown;
  Map<String, dynamic>? get overspendingAnalysis => _overspendingAnalysis;
  List<dynamic> get alertHistory => _alertHistory;
  bool get isLoading => _isLoading;

  Future<void> fetchPersonalBudget(int month, int year) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService.getPersonalBudget(month, year);
      if (result['success'] == true) {
        _personalBudget = result['data'];
      } else {
        _personalBudget = null;
      }
    } catch (e) {
      print('Error fetching personal budget: $e');
      _personalBudget = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFamilyBudget(int month, int year) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService.getFamilyBudget(month, year);
      if (result['success'] == true) {
        _familyBudget = result['data'];
        _familyBreakdown = result['breakdown'] ?? [];
      } else {
        _familyBudget = null;
        _familyBreakdown = [];
      }
    } catch (e) {
      print('Error fetching family budget: $e');
      _familyBudget = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOverspendingAnalysis() async {
    try {
      final result = await ApiService.getOverspendingAnalysis();
      if (result['success'] == true) {
        _overspendingAnalysis = result;
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching analysis: $e');
    }
  }

  Future<void> fetchAlertHistory() async {
    try {
      final result = await ApiService.getAlertHistory();
      if (result['success'] == true) {
        _alertHistory = result['alerts'];
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching alerts: $e');
    }
  }

  Future<Map<String, dynamic>> setBudget(Map<String, dynamic> data) async {
    try {
      final result = await ApiService.setBudget(data);
      if (result['success'] == true) {
        _personalBudget = result['data'];
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> setFamilyBudget(Map<String, dynamic> data) async {
    try {
      final result = await ApiService.setFamilyBudget(data);
      if (result['success'] == true) {
        _familyBudget = result['data'];
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deletePersonalBudget(String id) async {
    try {
      final result = await ApiService.deleteBudget(id);
      if (result['success'] == true) {
        _personalBudget = null;
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  void clear() {
    _personalBudget = null;
    _familyBudget = null;
    _familyBreakdown = [];
    _overspendingAnalysis = null;
    _alertHistory = [];
    notifyListeners();
  }
}
