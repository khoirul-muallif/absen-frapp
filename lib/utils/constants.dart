import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api';

  static String get login => '$baseUrl/auth/login';
  static String get logout => '$baseUrl/auth/logout';
  static String get me => '$baseUrl/auth/me';

  static String get notifikasi => '$baseUrl/notifikasi';
  static String get notifikasiJumlah => '$baseUrl/notifikasi/jumlah';
  static String get notifikasiBacaSemua => '$baseUrl/notifikasi/baca-semua';
}