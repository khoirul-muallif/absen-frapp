// lib/services/api_client.dart
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;
  final int statusCode;

  /// true kalau request tidak pernah sampai ke server (timeout, tidak ada
  /// internet, socket putus). Bedanya dengan error biasa: ini layak dikasih
  /// tombol "Coba Lagi", bukan pesan validasi.
  final bool isKoneksi;

  ApiException(this.message, this.statusCode, {this.errors}) : isKoneksi = false;

  ApiException.koneksi(this.message)
      : statusCode = 0,
        errors = null,
        isKoneksi = true;
}

class ApiClient {
  final TokenStorage _tokenStorage = TokenStorage();

  /// 10 detik, sama dengan nilai yang sudah diuji di device untuk
  /// JadwalScreen (624b911). Upload foto absen dikasih jatah jauh lebih
  /// panjang — kirim JPEG lewat data seluler di dalam gedung bisa lama,
  /// dan gagal di sini artinya user harus mengulang seluruh flow wajah.
  static const Duration _batasWaktu = Duration(seconds: 10);
  static const Duration _batasWaktuUpload = Duration(seconds: 45);

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {'Accept': 'application/json'};
    if (withAuth) {
      final token = await _tokenStorage.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Pembungkus semua request: memberi batas waktu dan menerjemahkan
  /// kegagalan level koneksi jadi ApiException, supaya pemanggil yang
  /// sudah menangkap ApiException tidak perlu diubah.
  Future<Map<String, dynamic>> _kirim(
    Future<Map<String, dynamic>> Function() request,
    Duration batas,
  ) async {
    try {
      return await request().timeout(batas);
    } on ApiException {
      rethrow; // error dari _handle (401, validasi, dst) — biarkan apa adanya
    } on TimeoutException {
      throw ApiException.koneksi(
        'Server tidak merespons. Periksa koneksi Anda lalu coba lagi.',
      );
    } on SocketException {
      throw ApiException.koneksi(
        'Tidak dapat terhubung. Pastikan perangkat tersambung ke internet.',
      );
    } on http.ClientException {
      throw ApiException.koneksi('Koneksi ke server terputus.');
    }
  }

  Future<Map<String, dynamic>> get(String url) {
    return _kirim(() async {
      final res = await http.get(Uri.parse(url), headers: await _headers());
      return _handle(res);
    }, _batasWaktu);
  }

  Future<Map<String, dynamic>> post(String url, {Map<String, dynamic>? body}) {
    return _kirim(() async {
      final res = await http.post(
        Uri.parse(url),
        headers: {...await _headers(), 'Content-Type': 'application/json'},
        body: body != null ? jsonEncode(body) : null,
      );
      return _handle(res);
    }, _batasWaktu);
  }

  Future<Map<String, dynamic>> patch(String url, {Map<String, dynamic>? body}) {
    return _kirim(() async {
      final res = await http.patch(
        Uri.parse(url),
        headers: {...await _headers(), 'Content-Type': 'application/json'},
        body: body != null ? jsonEncode(body) : null,
      );
      return _handle(res);
    }, _batasWaktu);
  }

  Future<Map<String, dynamic>> delete(String url) {
    return _kirim(() async {
      final res = await http.delete(Uri.parse(url), headers: await _headers());
      return _handle(res);
    }, _batasWaktu);
  }

  Future<Map<String, dynamic>> postMultipart(
    String url, {
    required Map<String, String> fields,
    required Map<String, File> files,
  }) {
    return _kirim(() async {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(await _headers());
      request.fields.addAll(fields);
      for (final entry in files.entries) {
        request.files
            .add(await http.MultipartFile.fromPath(entry.key, entry.value.path));
      }
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      return _handle(res);
    }, _batasWaktuUpload);
  }

  Map<String, dynamic> _handle(http.Response res) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      // Body bukan JSON — halaman error HTML Laravel, 404 dari URL salah,
      // atau respons proxy. Tanpa ini FormatException lolos sebagai error
      // tak tertangkap, karena semua service cuma catch ApiException.
      throw ApiException(
        'Server mengirim respons yang tidak dikenali (kode ${res.statusCode}).',
        res.statusCode,
      );
    }

    if (res.statusCode == 401) {
      // Cuma bersihkan token lokal (bukan AuthService.logout() penuh —
      // itu juga manggil endpoint logout ke server pakai token yang
      // sudah invalid, percuma). Splash/guard yang arahkan ke login.
      _tokenStorage.clearToken();
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