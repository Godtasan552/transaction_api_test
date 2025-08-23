import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'jwt_storage.dart';

class ApiService extends GetxController {
  static const String baseUrl = 'https://transactions-cs.vercel.app/api';
  String get version => "1.2.0";

  Future<http.Response> _handleResponse(Future<http.Response> Function() apiCall) async {
    final response = await apiCall();
    if (response.statusCode == 401 || response.statusCode == 403) {
      await logout();
      throw Exception('Token expired. User logged out.');
    }
    return response;
  }

  Future<http.Response> get(String endpoint) async {
    final token = await JwtStorage.getToken();
    return _handleResponse(() => http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'app_version': version,
      },
    ));
  }
    Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
      final token = await JwtStorage.getToken();
      return _handleResponse(() => http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'app_version': version,
        },
        body: json.encode(body),
      ));
    }

    Future<http.Response> delete(String endpoint) async {
      final token = await JwtStorage.getToken();
      return _handleResponse(() => http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'app_version': version,
        },
      ));
    }

  Future<http.Response> post(String endpoint, dynamic data, {bool withAuth = true}) async {
    final token = withAuth ? await JwtStorage.getToken() : null;
    return _handleResponse(() => http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        if (withAuth) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'app_version': version,
      },
      body: json.encode(data),
    ));
  }

  // put, delete ... (เหมือนกัน)
  Future<bool> logout() async {
    await JwtStorage.deleteToken();
    Get.offAllNamed('/login');
    return true;
  }
}