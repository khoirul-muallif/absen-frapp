// lib/services/absensi_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';
import 'dart:convert';
import 'api_client.dart';
import '../models/absensi_model.dart';
import '../models/riwayat_absen_model.dart';

class AbsensiService {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService(); // dipakai khusus utk header multipart di bawah

  Future<AbsensiStatus?> getStatus() async {
    try {
      final json = await _apiClient.get('${ApiConstants.baseUrl}/absensi/status');
      return AbsensiStatus.fromJson(json['data']);
    } on ApiException {
      return null;
    }
  }

  Future<List<RiwayatAbsenItem>> getRiwayat({required int bulan, required int tahun}) async {
    try {
      final json = await _apiClient.get(
        '${ApiConstants.baseUrl}/absensi/riwayat?bulan=$bulan&tahun=$tahun',
      );
      final records = json['data']['records'] as List;
      return records.map((e) => RiwayatAbsenItem.fromJson(e)).toList();
    } on ApiException {
      return [];
    }
  }

  Future<RekapAbsen?> getRekap({required int bulan, required int tahun}) async {
    try {
      final json = await _apiClient.get(
        '${ApiConstants.baseUrl}/absensi/rekap?bulan=$bulan&tahun=$tahun',
      );
      return RekapAbsen.fromJson(json['data']);
    } on ApiException {
      return null;
    }
  }

  Future<Map<String, dynamic>> validasiQr(String kode) async {
    try {
      final json = await _apiClient.get('${ApiConstants.baseUrl}/instansi/qr/$kode');
      return {
        'success': true,
        'message': json['message'] ?? '',
        'data': json['data'],
      };
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message, 'data': null};
    }
  }

  // --- Di bawah ini TIDAK dimigrasi ke ApiClient ---
  // ApiClient.post() cuma support JSON body; endpoint masuk/pulang butuh
  // multipart/form-data (file foto), jadi tetap pakai http.MultipartRequest
  // manual seperti sebelumnya.

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, dynamic>> absenMasuk({
    required double latitude,
    required double longitude,
    required String kodeQr,
    required File fotoMasuk,
  }) async {
    return _absenMultipart(
      endpoint: '${ApiConstants.baseUrl}/absensi/masuk',
      latitude: latitude,
      longitude: longitude,
      foto: fotoMasuk,
      fotoFieldName: 'foto_masuk',
      extraFields: {'kode_qr': kodeQr},
    );
  }

  Future<Map<String, dynamic>> absenPulang({
    required double latitude,
    required double longitude,
    required File fotoPulang,
  }) async {
    return _absenMultipart(
      endpoint: '${ApiConstants.baseUrl}/absensi/pulang',
      latitude: latitude,
      longitude: longitude,
      foto: fotoPulang,
      fotoFieldName: 'foto_pulang',
      extraFields: {},
    );
  }

  Future<Map<String, dynamic>> _absenMultipart({
    required String endpoint,
    required double latitude,
    required double longitude,
    required File foto,
    required String fotoFieldName,
    required Map<String, String> extraFields,
  }) async {
    try {
      final headers = await _authHeaders();
      final request = http.MultipartRequest('POST', Uri.parse(endpoint));
      request.headers.addAll(headers);

      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields.addAll(extraFields);

      request.files.add(
        await http.MultipartFile.fromPath(fotoFieldName, foto.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final json = jsonDecode(response.body);

      return {
        'success': json['success'] ?? false,
        'message': json['message'] ?? '',
        'data': json['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }
}