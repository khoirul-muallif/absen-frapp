import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

/// Hasil percobaan auto-login saat splash. `false` yang lama menyatukan
/// "memang belum login" dengan "gagal konek padahal token masih sah" —
/// keduanya melempar user ke LoginScreen, di mana dia juga tidak bisa
/// login karena offline.
enum HasilAutoLogin { berhasil, belumLogin, gagalKoneksi }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email, password);

    _isLoading = false;

    if (result['success']) {
      _user = result['user'];
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<HasilAutoLogin> tryAutoLogin() async {
    final token = await _authService.getToken();
    if (token == null) return HasilAutoLogin.belumLogin;

    final result = await _authService.getMe();

    if (result['success'] == true) {
      _user = result['user'];
      notifyListeners();
      return HasilAutoLogin.berhasil;
    }

    // Token masih tersimpan dan belum dibuang getMe() — sesinya mungkin
    // masih sah, cuma tidak bisa diverifikasi sekarang.
    if (result['koneksi'] == true) return HasilAutoLogin.gagalKoneksi;

    return HasilAutoLogin.belumLogin;
  }
}