import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL'];
    if (url == null || url.isEmpty) {
      throw StateError(
        'API_BASE_URL tidak ditemukan di .env — pastikan file .env ada '
        'dan flutter_dotenv.load() sudah dipanggil sebelum app jalan.',
      );
    }
    return url;
  }

  static String get login => '$baseUrl/auth/login';
  static String get logout => '$baseUrl/auth/logout';
  static String get me => '$baseUrl/auth/me';

  static String get notifikasi => '$baseUrl/notifikasi';
  static String get notifikasiJumlah => '$baseUrl/notifikasi/jumlah';
  static String get notifikasiBacaSemua => '$baseUrl/notifikasi/baca-semua';

  static String get izin => '$baseUrl/izin';
  static String izinJamKembali(String id) => '$baseUrl/izin/$id/jam-kembali';
}