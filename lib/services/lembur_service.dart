// lib/services/lembur_service.dart
import '../utils/constants.dart';
import '../models/lembur_model.dart';
import 'api_client.dart';

class LemburService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> ajukan({
    required String tanggal,
    required String jamMulai,
    required String jamSelesai,
    String? alasan,
  }) async {
    try {
      final json = await _apiClient.post(ApiConstants.lembur, body: {
        'tanggal': tanggal,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        if (alasan != null && alasan.isNotEmpty) 'alasan': alasan,
      });
      return {'success': true, 'message': json['message'] ?? ''};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  Future<List<LemburItem>> riwayat({String? status}) async {
    try {
      final query = status != null ? '?status=$status' : '';
      final json = await _apiClient.get('${ApiConstants.lembur}$query');
      final records = json['data']['records'] as List;
      return records.map((e) => LemburItem.fromJson(e)).toList();
    } on ApiException {
      return [];
    }
  }

  Future<Map<String, dynamic>> batalkan(int id) async {
    try {
      final json = await _apiClient.delete('${ApiConstants.lembur}/$id');
      return {'success': true, 'message': json['message'] ?? ''};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }
}