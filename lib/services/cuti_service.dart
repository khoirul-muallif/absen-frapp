// lib/services/cuti_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/cuti_model.dart';
import '../models/cuti_kuota_model.dart';
import 'api_client.dart';
import 'token_storage.dart';

class CutiService {
  final ApiClient _apiClient = ApiClient();
  final TokenStorage _tokenStorage = TokenStorage();

  Future<List<CutiKuotaItem>> kuota({int? tahun}) async {
    try {
      final query = tahun != null ? '?tahun=$tahun' : '';
      final json = await _apiClient.get('${ApiConstants.cutiKuota}$query');
      final records = json['data']['records'] as List;
      return records.map((e) => CutiKuotaItem.fromJson(e)).toList();
    } on ApiException {
      return [];
    }
  }

  Future<List<CutiItem>> riwayat({String? status}) async {
    try {
      final query = status != null ? '?status=$status' : '';
      final json = await _apiClient.get('${ApiConstants.cuti}$query');
      final records = json['data']['records'] as List;
      return records.map((e) => CutiItem.fromJson(e)).toList();
    } on ApiException {
      return [];
    }
  }

  // Multipart manual -- ApiClient belum support file upload (sama kondisi
  // dengan _absenMultipart di absensi_service.dart).
  Future<Map<String, dynamic>> ajukan({
    required int jenisCutiId,
    required String tanggalMulai,
    required String tanggalSelesai,
    required String alasan,
    File? lampiran,
  }) async {
    try {
      final token = await _tokenStorage.getToken();
      final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.cuti))
        ..headers['Accept'] = 'application/json'
        ..fields['jenis_cuti_id'] = jenisCutiId.toString()
        ..fields['tanggal_mulai'] = tanggalMulai
        ..fields['tanggal_selesai'] = tanggalSelesai
        ..fields['alasan'] = alasan;

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (lampiran != null) {
        request.files.add(await http.MultipartFile.fromPath('lampiran', lampiran.path));
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      final json = jsonDecode(res.body) as Map<String, dynamic>;

      if (json['success'] != true) {
        return {'success': false, 'message': json['message'] ?? 'Gagal mengajukan cuti'};
      }
      return {'success': true, 'message': json['message'] ?? ''};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> batalkan(int id) async {
    try {
      final json = await _apiClient.delete('${ApiConstants.cuti}/$id');
      return {'success': true, 'message': json['message'] ?? ''};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }
}