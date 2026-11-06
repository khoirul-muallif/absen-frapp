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

  /// Varian yang TIDAK menelan error — untuk layar yang perlu membedakan
  /// gagal-request dari benar-benar-kosong (pola sayaDalamRentangOrThrow,
  /// 624b911).
  Future<List<DinasItem>> riwayatOrThrow({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final json = await _apiClient.get('${ApiConstants.dinas}$query');
    final records = json['data']['records'] as List;
    return records.map((e) => DinasItem.fromJson(e)).toList();
  }

  Future<List<DinasItem>> riwayat({String? status}) async {
    try {
      return await riwayatOrThrow(status: status);
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