import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService;
  final String _baseUrl = const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000');

  ApiService(this._authService);

  Future<List<dynamic>> getLoans() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/loans'),
        headers: _authService.authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Session expired');
      }
      throw Exception('Failed to load loans');
    } catch (e) {
      if (kDebugMode) print('Get loans error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createLoan(String borrowerName, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/loans'),
        headers: _authService.authHeaders,
        body: json.encode({
          'borrower_name': borrowerName,
          'loan_amount': amount,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Session expired');
      }
      throw Exception('Failed to create loan');
    } catch (e) {
      if (kDebugMode) print('Create loan error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadAgreement(int loanId, PlatformFile file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload-agreement?loan_id=$loanId'),
      );
      
      request.headers.addAll(_authService.authHeaders);
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Session expired');
      } else if (response.statusCode == 413) {
        throw Exception('File too large (max 50MB)');
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        throw Exception(data['detail'] ?? 'Invalid file');
      }
      throw Exception('Upload failed');
    } catch (e) {
      if (kDebugMode) print('Upload agreement error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadFinancials(int loanId, PlatformFile file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload-financials?loan_id=$loanId'),
      );
      
      request.headers.addAll(_authService.authHeaders);
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Session expired');
      } else if (response.statusCode == 413) {
        throw Exception('File too large (max 50MB)');
      }
      throw Exception('Upload failed');
    } catch (e) {
      if (kDebugMode) print('Upload financials error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getAuditLogs() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/logs'),
        headers: _authService.authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Session expired');
      }
      throw Exception('Failed to load logs');
    } catch (e) {
      if (kDebugMode) print('Get logs error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> runSimulation(Map<String, double> changes) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/simulate'),
        headers: _authService.authHeaders,
        body: json.encode(changes),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Session expired');
      }
      throw Exception('Simulation failed');
    } catch (e) {
      if (kDebugMode) print('Simulation error: $e');
      rethrow;
    }
  }
}
