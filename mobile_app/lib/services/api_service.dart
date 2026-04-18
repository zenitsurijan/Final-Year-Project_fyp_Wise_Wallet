import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Add this import

import 'package:flutter/foundation.dart';

class ApiService {
  // --- Configure your Base URL here ---
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5002/api';
    } else {
      // For Android Emulator, use http://10.0.2.2:5002/api
      // For Physical Device, use your computer's Local IP (e.g., http://192.168.1.5:5002/api)
      return 'http://192.168.100.190:5002/api';
    }
  }
  
  static String get savingsUrl => '$baseUrl/savings';
  static String get reportsUrl => '$baseUrl/reports';
  static String get notificationsUrl => '$baseUrl/notifications';
  static String get billsUrl => '$baseUrl/bills';

  static String? _token;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // Auth
  static Future<Map<String, dynamic>> register(String name, String email, String password, {String? role, String? familyId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'familyId': familyId,
        }),
      ).timeout(const Duration(seconds: 30));
      return _decodeResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Registration failed: ${e.toString().contains('SocketException') ? 'Server unreachable' : e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 30));
      return _decodeResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Login failed: ${e.toString().contains('SocketException') ? 'Server unreachable. Check IP/Address.' : e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      ).timeout(const Duration(seconds: 30));
      return _decodeResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Verification failed: ${e.toString().contains('SocketException') ? 'Server unreachable' : e.toString()}'};
    }
  }

  // Transactions
  static Future<Map<String, dynamic>> getTransactions({
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
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (type != null) queryParams['type'] = type;
    if (category != null) queryParams['category'] = category;
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
    if (hasReceipt != null) queryParams['hasReceipt'] = hasReceipt.toString();
    if (search != null) queryParams['search'] = search;
    if (minAmount != null) queryParams['minAmount'] = minAmount.toString();
    if (maxAmount != null) queryParams['maxAmount'] = maxAmount.toString();

    final uri = Uri.parse('$baseUrl/transactions').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateTransaction(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteTransaction(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getTransactionSummary({DateTime? startDate, DateTime? endDate}) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

    final uri = Uri.parse('$baseUrl/transactions/summary').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions/categories'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> addCategory(String name, String icon, String type) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/categories'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'icon': icon,
        'type': type,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteCategory(String category) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/categories/$category'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // Image Upload
  static Future<Map<String, dynamic>> uploadImage(List<int> bytes, String filename) async {
    final uri = Uri.parse('$baseUrl/transactions/upload');
    var request = http.MultipartRequest('POST', uri);
    
    // For multipart requests, we should NOT add application/json content-type
    final headers = Map<String, String>.from(_headers);
    headers.remove('Content-Type');
    headers['Accept'] = 'application/json';
    
    request.headers.addAll(headers);
    
    final mimeType = filename.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    
    request.files.add(http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: filename,
      contentType: MediaType.parse(mimeType),
    ));

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    return jsonDecode(responseBody);
  }

  // Get image with auth headers
  static Future<http.Response> getImageWithAuth(String imageId) async {
    return await http.get(
      Uri.parse('$baseUrl/transactions/image/$imageId'),
      headers: _headers,
    );
  }

  static dynamic _decodeResponse(http.Response response) {
    if (response.body.trim().startsWith('<')) {
      return {'success': false, 'message': 'Server error: Received HTML instead of JSON (Check if server is running)'};
    }
    try {
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to parse server response'};
    }
  }

  // Reports
  static Future<Map<String, dynamic>> getDailyReport(String date) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/daily?date=$date'),
      headers: _headers,
    );
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getMonthlyReport(int month, int year) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/monthly?month=$month&year=$year'),
      headers: _headers,
    );
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getYearlyReport(int year) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/yearly?year=$year'),
      headers: _headers,
    );
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> getCustomReport(String startDate, String endDate) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/custom?startDate=$startDate&endDate=$endDate'),
      headers: _headers,
    );
    return _decodeResponse(response);
  }

  // Budget
  static Future<Map<String, dynamic>> setBudget(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/budget'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getPersonalBudget(int month, int year) async {
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    final response = await http.get(
      Uri.parse('$baseUrl/budget/$monthStr'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteBudget(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/budget/$id'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // Family Budget
  static Future<Map<String, dynamic>> setFamilyBudget(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/budget/family/set'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getFamilyBudget(int month, int year) async {
    final uri = Uri.parse('$baseUrl/budget/family').replace(queryParameters: {
      'month': month.toString(),
      'year': year.toString(),
    });
    final response = await http.get(uri, headers: _headers);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getBudgetStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/budget/status'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // Alerts & Analysis
  static Future<Map<String, dynamic>> getAlertHistory({int months = 3}) async {
    // Note: Backend ignores 'months' param for now, limit 20
    final response = await http.get(Uri.parse('$baseUrl/budget/alerts'), headers: _headers);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getOverspendingAnalysis() async {
    final response = await http.get(
      Uri.parse('$baseUrl/budget/overspending'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // Savings Goals
  static Future<Map<String, dynamic>> getSavingsGoals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/savings'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createSavingsGoal(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/savings'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> addSavingsContribution(String goalId, double amount, String note) async {
    final response = await http.post(
      Uri.parse('$baseUrl/savings/$goalId/contribute'),
      headers: _headers,
      body: jsonEncode({
        'amount': amount,
        'note': note,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteSavingsGoal(String goalId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/savings/$goalId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // Family
  static Future<Map<String, dynamic>> createFamily(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/family/create'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> joinFamily(String inviteCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/family/join'),
      headers: _headers,
      body: jsonEncode({'inviteCode': inviteCode}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getFamilyDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/family/dashboard'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getFamilyMembers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/family/members'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> removeFamilyMember(String memberId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/family/members/$memberId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> transferFamilyHead(String newHeadId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/family/transfer-head'),
      headers: _headers,
      body: jsonEncode({'newHeadId': newHeadId}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> sendFamilyInvite(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/family/invite'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getMemberReport(String memberId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/family/member-report/$memberId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateFamilySettings(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/family/settings'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> leaveFamily() async {
    final response = await http.post(
      Uri.parse('$baseUrl/family/leave'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteFamily() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/family'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // --- Notifications ---
  static Future<void> updateFcmToken(String fcmToken) async {
    final response = await http.post(
      Uri.parse('$notificationsUrl/token'),
      headers: _headers,
      body: jsonEncode({'fcmToken': fcmToken}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update FCM token');
    }
  }

  static Future<Map<String, dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse(notificationsUrl),
      headers: _headers,
    );
    return _decodeResponse(response);
  }

  // --- Bills ---
  static Future<Map<String, dynamic>> getBills() async {
    final response = await http.get(
      Uri.parse(billsUrl),
      headers: _headers,
    );
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> createBill(Map<String, dynamic> billData) async {
    final response = await http.post(
      Uri.parse(billsUrl),
      headers: _headers,
      body: jsonEncode(billData),
    );
    return _decodeResponse(response);
  }

  // --- Admin APIs ---

  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/stats'), headers: _headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAdminUsers({int page = 1}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/users?page=$page'), headers: _headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAdminTransactions({int page = 1}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/transactions?page=$page'), headers: _headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAdminAnalytics({String timeframe = 'last30days'}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/analytics?timeframe=$timeframe'), headers: _headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAdminLogs({int page = 1}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/logs?page=$page'), headers: _headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateUserRole(String userId, String role) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/role'),
        headers: _headers,
        body: jsonEncode({'role': role}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> toggleUserStatus(String userId, bool isActive) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/status'),
        headers: _headers,
        body: jsonEncode({'isActive': isActive}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteTransactionAdmin(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/admin/transactions/$id'), headers: _headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAdminUserDetails(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/users/$userId'), headers: _headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
