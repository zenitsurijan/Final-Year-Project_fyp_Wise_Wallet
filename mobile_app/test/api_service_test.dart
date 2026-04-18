import 'package:flutter_test/flutter_test.dart';

// Mock class to simulate ApiService without network calls
class MockApiService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    if (email == 'ram@gmail.com' && password == 'Test@123') {
      return {
        'success': true,
        'token': 'mock_jwt_token',
        'user': {'name': 'Ram Sharma', 'email': 'ram@gmail.com'}
      };
    }
    return {'success': false, 'message': 'Invalid credentials'};
  }

  static Future<Map<String, dynamic>> getTransactions() async {
    return {
      'success': true,
      'transactions': [
        {'id': '1', 'type': 'expense', 'amount': 500, 'category': 'Food'},
        {'id': '2', 'type': 'income', 'amount': 15000, 'category': 'Salary'}
      ]
    };
  }
}

void main() {
  group('Mock API Service Unit Tests', () {
    test('Login should succeed with valid credentials', () async {
      final result = await MockApiService.login('ram@gmail.com', 'Test@123');
      expect(result['success'], isTrue);
      expect(result['token'], equals('mock_jwt_token'));
    });

    test('Login should fail with invalid credentials', () async {
      final result = await MockApiService.login('wrong@gmail.com', 'password');
      expect(result['success'], isFalse);
    });

    test('GetTransactions should return list of transactions', () async {
      final result = await MockApiService.getTransactions();
      expect(result['success'], isTrue);
      expect(result['transactions'], isA<List>());
      expect(result['transactions'].length, equals(2));
    });
  });
}
