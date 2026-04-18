import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class FamilyProvider with ChangeNotifier {
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _members = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get dashboardData => _dashboardData;
  List<dynamic> get members => _members;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) print('FamilyProvider: Fetching dashboard...');
      final result = await ApiService.getFamilyDashboard();
      if (kDebugMode) print('FamilyProvider: Dashboard response: $result');
      
      if (result['success'] == true) {
        _dashboardData = Map<String, dynamic>.from(result['data']);
        _error = null;
      } else {
        _error = result['message'];
        _dashboardData = null;
        if (kDebugMode) print('FamilyProvider: API Error: $_error');
      }
    } catch (e) {
      if (kDebugMode) print('FamilyProvider: Critical Error in fetchDashboard: $e');
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMembers() async {
    try {
      final result = await ApiService.getFamilyMembers();
      if (result['success'] == true) {
        _members = result['data'];
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching family members: $e');
    }
  }

  Future<Map<String, dynamic>> createFamily(String name) async {
    try {
      final result = await ApiService.createFamily(name);
      if (result['success'] == true) {
        await fetchDashboard();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> joinFamily(String code) async {
    try {
      final result = await ApiService.joinFamily(code);
      if (result['success'] == true) {
        await fetchDashboard();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> removeMember(String memberId) async {
    try {
      final result = await ApiService.removeFamilyMember(memberId);
      if (result['success'] == true) {
        _members.removeWhere((m) => m['_id'] == memberId);
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> transferHeadRole(String newHeadId) async {
    try {
      final result = await ApiService.transferFamilyHead(newHeadId);
      if (result['success'] == true) {
        await fetchDashboard();
        await fetchMembers();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendInvite(String email) async {
    try {
      final result = await ApiService.sendFamilyInvite(email);
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchMemberReport(String memberId) async {
    try {
      return await ApiService.getMemberReport(memberId);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> leaveFamily() async {
    _isLoading = true;
    notifyListeners();
    final result = await ApiService.leaveFamily();
    if (result['success'] == true) {
      _dashboardData = null;
      _members = [];
    }
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> deleteFamily() async {
    _isLoading = true;
    notifyListeners();
    final result = await ApiService.deleteFamily();
    if (result['success'] == true) {
      _dashboardData = null;
      _members = [];
    }
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> updateSettings({String? name, Map<String, dynamic>? settings}) async {
    try {
      final result = await ApiService.updateFamilySettings({
        if (name != null) 'name': name,
        if (settings != null) 'settings': settings,
      });
      if (result['success'] == true) {
        await fetchDashboard();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  void clear() {
    _dashboardData = null;
    _members = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
