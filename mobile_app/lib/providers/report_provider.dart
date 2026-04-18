import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _dailyReport;
  Map<String, dynamic>? _monthlyReport;
  Map<String, dynamic>? _yearlyReport;
  Map<String, dynamic>? _customReport;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get dailyReport => _dailyReport;
  Map<String, dynamic>? get monthlyReport => _monthlyReport;
  Map<String, dynamic>? get yearlyReport => _yearlyReport;
  Map<String, dynamic>? get customReport => _customReport;

  Future<void> fetchDailyReport(String date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getDailyReport(date);
      if (response['success']) {
        _dailyReport = response;
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMonthlyReport(int month, int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getMonthlyReport(month, year);
      if (response['success']) {
        _monthlyReport = response;
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchYearlyReport(int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getYearlyReport(year);
      if (response['success']) {
        _yearlyReport = response;
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCustomReport(String startDate, String endDate) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getCustomReport(startDate, endDate);
      if (response['success']) {
        _customReport = response;
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _dailyReport = null;
    _monthlyReport = null;
    _yearlyReport = null;
    _customReport = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
