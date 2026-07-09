import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';
import '../models/absensi_model.dart';
import '../models/riwayat_absen_model.dart';

class AbsensiService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  Future<AbsensiStatus?> getStatus() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/absensi/status'),
      headers: headers,
    );

    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['success'] == true) {
      return AbsensiStatus.fromJson(json['data']);
    }
    return null;
  }

  Future<List<RiwayatAbsenItem>> getRiwayat({required int bulan, required int tahun}) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/absensi/riwayat?bulan=$bulan&tahun=$tahun'),
      headers: headers,
    );

    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['success'] == true) {
      final records = json['data']['records'] as List;
      return records.map((e) => RiwayatAbsenItem.fromJson(e)).toList();
    }
    return [];
  }

  Future<RekapAbsen?> getRekap({required int bulan, required int tahun}) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/absensi/rekap?bulan=$bulan&tahun=$tahun'),
      headers: headers,
    );

    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['success'] == true) {
      return RekapAbsen.fromJson(json['data']);
    }
    return null;
  }

  Future<Map<String, dynamic>> validasiQr(String kode) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/instansi/qr/$kode'),
      headers: headers,
    );

    final json = jsonDecode(response.body);
    return {
      'success': json['success'] ?? false,
      'message': json['message'] ?? '',
      'data': json['data'],
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