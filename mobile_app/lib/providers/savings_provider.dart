import 'package:flutter/foundation.dart';
import '../models/savings_goal_model.dart';
import '../services/api_service.dart';

class SavingsProvider with ChangeNotifier {
  List<SavingsGoal> _goals = [];
  bool _isLoading = false;
  String? _error;

  List<SavingsGoal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchGoals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.getSavingsGoals();
      if (result['success'] == true) {
        final List<dynamic> data = result['data'] ?? [];
        _goals = data.map((json) => SavingsGoal.fromJson(json)).toList();
      } else {
        _error = result['message'] ?? 'Failed to fetch savings goals';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> createGoal({
    required String name,
    required double targetAmount,
    required DateTime deadline,
    required bool isFamilyGoal,
  }) async {
    try {
      final result = await ApiService.createSavingsGoal({
        'name': name,
        'targetAmount': targetAmount,
        'deadline': deadline.toIso8601String(),
        'isFamilyGoal': isFamilyGoal,
      });

      if (result['success'] == true) {
        await fetchGoals(); // Refresh list
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addContribution(String goalId, double amount, String note) async {
    try {
      final result = await ApiService.addSavingsContribution(goalId, amount, note);
      if (result['success'] == true) {
        // Find and update the goal locally to avoid full fetch if possible, 
        // but fetchGoals ensures insights are updated from backend
        await fetchGoals(); 
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteGoal(String goalId) async {
    try {
      final result = await ApiService.deleteSavingsGoal(goalId);
      if (result['success'] == true) {
        _goals.removeWhere((g) => g.id == goalId);
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  void clear() {
    _goals = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
