import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BillsProvider with ChangeNotifier {
  List<dynamic> _bills = [];
  bool _isLoading = false;

  List<dynamic> get bills => _bills;
  bool get isLoading => _isLoading;

  Future<void> fetchBills() async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService.getBills();
      if (result['success'] == true) {
        _bills = result['bills'];
      }
    } catch (e) {
      print('Error fetching bills: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addBill(Map<String, dynamic> billData) async {
    try {
      final result = await ApiService.createBill(billData);
      if (result['success'] == true) {
        await fetchBills();
        return true;
      }
    } catch (e) {
      print('Error creating bill: $e');
    }
    return false;
  }

  void clear() {
    _bills = [];
    _isLoading = false;
    notifyListeners();
  }
}
