// lib/services/instansi_storage.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Identitas instansi yang disimpan dari login terakhir, supaya
/// LoginScreen dan SplashScreen bisa menampilkannya SEBELUM ada yang
/// login — di dua layar itu aplikasi belum punya token maupun data user.
///
/// SENGAJA tidak dibersihkan saat logout, beda dari TokenStorage. Ini
/// bukan data rahasia (nama dan logo instansi terpampang di gedungnya),
/// dan menghapusnya berarti karyawan yang logout lalu login lagi kembali
/// melihat placeholder — padahal aplikasinya sudah pernah tahu. Jangan
/// "dirapikan" dengan menambahkannya ke AuthService.logout().
class InstansiStorage {
  static const _kunciNama = 'instansi_nama';
  static const _kunciLogo = 'instansi_logo';

  Future<void> simpan({required String nama, String? logo}) async {
    final prefs = await SharedPreferences.getInstance();
    if (nama.isNotEmpty) await prefs.setString(_kunciNama, nama);
    // Logo dihapus kalau instansi mencabutnya di panel, supaya layar
    // login tidak terus menunjuk file yang sudah tidak ada.
    if (logo != null && logo.isNotEmpty) {
      await prefs.setString(_kunciLogo, logo);
    } else {
      await prefs.remove(_kunciLogo);
    }
  }

  Future<({String? nama, String? logo})> baca() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      nama: prefs.getString(_kunciNama),
      logo: prefs.getString(_kunciLogo),
    );
  }
}