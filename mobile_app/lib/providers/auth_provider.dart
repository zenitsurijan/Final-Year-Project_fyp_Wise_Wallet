import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _token;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null;

  Future<void> _saveAuthData(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', json.encode(user));
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  Future<bool> tryAutoLogin() async {
    if (_isInitialized) return isAuthenticated;
    
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('auth_token')) {
      _isInitialized = true;
      return false;
    }

    _token = prefs.getString('auth_token');
    _user = json.decode(prefs.getString('user_data')!) as Map<String, dynamic>;
    
    ApiService.setToken(_token);
    _isInitialized = true;
    notifyListeners();
    return true;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final result = await ApiService.register(name, email, password);
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final result = await ApiService.login(email, password);
    if (result['success'] == true) {
      _token = result['token'];
      _user = result['user'];
      ApiService.setToken(_token);
      await _saveAuthData(_token!, _user!);
    }
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> verifyOTP(String email, String code) async {
    _isLoading = true;
    notifyListeners();
    final result = await ApiService.verifyOtp(email, code);
    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    ApiService.setToken(null);
    await _clearAuthData();
    notifyListeners();
  }
}
