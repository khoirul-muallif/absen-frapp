// lib/services/auth_service.dart
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'token_storage.dart';
import 'instansi_storage.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();
  final InstansiStorage _instansiStorage = InstansiStorage();

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final json = await _apiClient.post(
        ApiConstants.login,
        // Backend pindah dari `email` ke `username` (fase 79, 9 Nov 2026).
        // Mengirim `email` dijawab 422 `username: required` — tidak ada
        // satu pun karyawan yang bisa masuk.
        body: {'username': username, 'password': password},
      );

      final data = json['data'];
      final token = data['token'];
      final user = UserModel.fromJson(data['karyawan']);

      await _tokenStorage.saveToken(token);
      // Identitas instansi disimpan supaya LoginScreen dan SplashScreen
      // bisa menampilkannya sebelum login berikutnya.
      await _instansiStorage.simpan(
        nama: user.instansiNama,
        logo: user.instansiLogo,
      );
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

    /// Ganti password sendiri. Mengembalikan `errors` per field (bukan satu
  /// pesan gabungan seperti login) karena endpoint ini punya dua field
  /// yang bisa ditolak terpisah — `password_lama` dan `password`.
  Future<Map<String, dynamic>> ubahPassword({
    required String passwordLama,
    required String passwordBaru,
  }) async {
    try {
      final json = await _apiClient.post(
        ApiConstants.ubahPassword,
        body: {
          'password_lama': passwordLama,
          'password': passwordBaru,
          'password_confirmation': passwordBaru,
        },
      );

      return {
        'success': true,
        'message': json['message'] ?? 'Password berhasil diubah.',
      };
    } on ApiException catch (e) {
      return {
        'success': false,
        'message': e.message,
        'errors': e.errors,
      };
    } catch (e) {
      return {'success': false, 'message': 'Tidak bisa terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'Tidak ada token tersimpan'};
    }

    try {
      final json = await _apiClient.get(ApiConstants.me);
      final user = UserModel.fromJson(json['data']);
      return {'success': true, 'user': user};
    } on ApiException catch (e) {
      // Hanya buang sesi kalau server benar-benar menolak tokennya. Sejak
      // 3d89e53 kegagalan koneksi JUGA datang sebagai ApiException, dan
      // sebelum perbaikan ini membuka aplikasi tanpa sinyal menghapus
      // token — user harus login ulang padahal sesinya masih sah.
      if (e.isKoneksi) {
        return {'success': false, 'koneksi': true, 'message': e.message};
      }
      await logout();
      return {'success': false, 'message': 'Sesi berakhir, silakan login ulang'};
    } catch (e) {
      return {'success': false, 'message': 'Tidak bisa terhubung ke server'};
    }
  }
}