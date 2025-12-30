import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  Future<Map<String, dynamic>> uploadAgreement(String filePath, List<int> bytes) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload-agreement'));
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filePath.split('/').last,
      contentType: MediaType('application', 'pdf'),
    ));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    return json.decode(responseData);
  }

  Future<Map<String, dynamic>> uploadFinancials(String filePath, List<int> bytes) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload-financials'));
    request.files.add(http.MultipartFile.fromBytes(
       'file',
      bytes,
      filename: filePath.split('/').last,
       contentType: MediaType('application', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
    ));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    return json.decode(responseData);
  }
}
