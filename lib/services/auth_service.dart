// lib/services/auth_service.dart
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final json = await _apiClient.post(
        ApiConstants.login,
        body: {'email': email, 'password': password},
      );

      final data = json['data'];
      final token = data['token'];
      final user = UserModel.fromJson(data['karyawan']);

      await _tokenStorage.saveToken(token);

      return {'success': true, 'user': user, 'token': token};
    } on ApiException catch (e) {
      String message = e.message;
      if (e.errors != null && e.errors!.isNotEmpty) {
        message = (e.errors!.values.first as List).first.toString();
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Tidak bisa terhubung ke server'};
    }
  }

  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse(ApiConstants.logout),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      }
    } catch (e) {
      // Offline dll, tetap lanjut hapus token lokal
    }

    await _tokenStorage.clearToken();
  }

  Future<String?> getToken() => _tokenStorage.getToken();

  Future<Map<String, dynamic>> getMe() async {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'Tidak ada token tersimpan'};
    }

    try {
      final json = await _apiClient.get(ApiConstants.me);
      final user = UserModel.fromJson(json['data']);
      return {'success': true, 'user': user};
    } on ApiException {
      await logout();
      return {'success': false, 'message': 'Sesi berakhir, silakan login ulang'};
    } catch (e) {
      return {'success': false, 'message': 'Tidak bisa terhubung ke server'};
    }
  }
}