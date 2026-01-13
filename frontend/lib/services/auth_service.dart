import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final String _baseUrl = const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000');

  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;

  Future<void> init() async {
    _token = await _storage.read(key: 'jwt');
    final userData = await _storage.read(key: 'user');
    if (userData != null) {
      _user = json.decode(userData);
    }
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        await _storage.write(key: 'jwt', value: _token);
        await _fetchUserData();
        return null; // Success
      } else if (response.statusCode == 401) {
        return 'Invalid email or password';
      } else if (response.statusCode == 429) {
        return 'Too many attempts. Please try again later.';
      }
      return 'Server error (${response.statusCode})';
    } catch (e) {
      if (kDebugMode) print('Login error: $e');
      return 'Server unreachable. Check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return null; // Success
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        return data['detail'] ?? 'Registration failed';
      } else if (response.statusCode == 422) {
        return 'Password must contain uppercase, lowercase, and digit';
      }
      return 'Registration failed';
    } catch (e) {
      if (kDebugMode) print('Register error: $e');
      return 'Server unreachable. Check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserData() async {
    if (_token == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/me'),
        headers: authHeaders,
      );
      
      if (response.statusCode == 200) {
        _user = json.decode(response.body);
        await _storage.write(key: 'user', value: json.encode(_user));
      }
    } catch (e) {
      if (kDebugMode) print('Fetch user error: $e');
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.delete(key: 'jwt');
    await _storage.delete(key: 'user');
    notifyListeners();
  }

  Map<String, String> get authHeaders => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };
}
