import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/user_model.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Accept': 'application/json'},
        body: {'email': email, 'password': password},
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        final data = json['data'];
        final token = data['token'];
        final user = UserModel.fromJson(data['karyawan']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        return {'success': true, 'user': user, 'token': token};
      } else {
        // Laravel validation error biasanya ada di json['errors']
        String message = json['message'] ?? 'Login gagal';
        if (json['errors'] != null) {
          final errors = json['errors'] as Map<String, dynamic>;
          message = errors.values.first[0];
        }
        return {'success': false, 'message': message};
      }
    } catch (e) {
      return {'success': false, 'message': 'Tidak bisa terhubung ke server'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}