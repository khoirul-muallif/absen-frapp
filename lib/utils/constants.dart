class ApiConstants {
  // Ganti sesuai URL Laravel kamu.
  // Kalau testing dari HP fisik ke Laragon di PC yang sama,
  // JANGAN pakai localhost/127.0.0.1 — pakai IP lokal PC kamu (misal 192.168.1.x)
  static const String baseUrl = 'http://192.168.1.24:8001/api';

  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String me = '$baseUrl/auth/me';
}