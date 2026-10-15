// lib/services/dinas_service.dart
import '../utils/constants.dart';
import '../models/dinas_model.dart';
import 'api_client.dart';

class DinasService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> ajukan({
    required String tanggalMulai,
    required String tanggalSelesai,
    required String tujuan,
    required String keperluan,
  }) async {
    try {
      final json = await _apiClient.post(ApiConstants.dinas, body: {
        'tanggal_mulai': tanggalMulai,
        'tanggal_selesai': tanggalSelesai,
        'tujuan': tujuan,
        'keperluan': keperluan,
      });
      return {'success': true, 'message': json['message'] ?? ''};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  Future<List<DinasItem>> riwayat({String? status}) async {
    try {
      final query = status != null ? '?status=$status' : '';
      final json = await _apiClient.get('${ApiConstants.dinas}$query');
      final records = json['data']['records'] as List;
      return records.map((e) => DinasItem.fromJson(e)).toList();
    } on ApiException {
      return [];
    }
  }

  Future<Map<String, dynamic>> batalkan(int id) async {
    try {
      final json = await _apiClient.delete('${ApiConstants.dinas}/$id');
      return {'success': true, 'message': json['message'] ?? ''};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }
}