// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;
  final int statusCode;
  ApiException(this.message, this.statusCode, {this.errors});
}

class ApiClient {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {'Accept': 'application/json'};
    if (withAuth) {
      final token = await _authService.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(String url) async {
    final res = await http.get(Uri.parse(url), headers: await _headers());
    return _handle(res);
  }

  Future<Map<String, dynamic>> post(String url, {Map<String, dynamic>? body}) async {
    final res = await http.post(
      Uri.parse(url),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> delete(String url) async {
    final res = await http.delete(Uri.parse(url), headers: await _headers());
    return _handle(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    final json = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 401) {
      _authService.logout(); // bersihkan token lokal, biar splash/guard arahkan ke login
      throw ApiException(json['message'] ?? 'Sesi berakhir, silakan login ulang', 401);
    }

    if (json['success'] != true) {
      throw ApiException(
        json['message'] ?? 'Terjadi kesalahan',
        res.statusCode,
        errors: json['errors'],
      );
    }

    return json;
  }
}