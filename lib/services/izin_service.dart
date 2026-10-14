import '../utils/constants.dart';
import '../models/izin_model.dart';
import 'api_client.dart';

class IzinService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> ajukan({
    required String tanggal,
    required String jamKeluar,
    required String keperluan,
  }) async {
    try {
      final json = await _apiClient.post(ApiConstants.izin, body: {
        'tanggal': tanggal,
        'jam_keluar': jamKeluar,
        'keperluan': keperluan,
      });
      return {'success': true, 'message': json['message'] ?? ''};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  Future<List<IzinItem>> riwayat({String? status}) async {
    try {
      final query = status != null ? '?status=$status' : '';
      final json = await _apiClient.get('${ApiConstants.izin}$query');
      final records = json['data']['records'] as List;
      return records.map((e) => IzinItem.fromJson(e)).toList();
    } on ApiException {
      return [];
    }
  }

  Future<Map<String, dynamic>> isiJamKembali(int id, String jamKembali) async {
    try {
      final json = await _apiClient.patch(
        ApiConstants.izinJamKembali(id.toString()),
        body: {'jam_kembali': jamKembali},
      );
      return {'success': true, 'message': json['message'] ?? ''};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  Future<Map<String, dynamic>> batalkan(int id) async {
    try {
      final json = await _apiClient.delete('${ApiConstants.izin}/$id');
      return {'success': true, 'message': json['message'] ?? ''};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }
}