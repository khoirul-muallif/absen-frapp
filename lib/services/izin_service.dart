import '../utils/constants.dart';
import '../models/izin_model.dart';
import 'api_client.dart';

class IzinService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> ajukan({
    required String tanggal,
    required String jamKeluar,
    required String jamKembaliRencana,
    required String keperluan,
  }) async {
    try {
      final json = await _apiClient.post(ApiConstants.izin, body: {
        'tanggal': tanggal,
        'jam_keluar': jamKeluar,
        // Wajib sejak fase 88. Ini perkiraan yang diisi sebelum pergi,
        // bukan catatan setelah kembali.
        'jam_kembali_rencana': jamKembaliRencana,
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
  Future<List<IzinItem>> riwayatOrThrow({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final json = await _apiClient.get('${ApiConstants.izin}$query');
    final records = json['data']['records'] as List;
    return records.map((e) => IzinItem.fromJson(e)).toList();
  }

  Future<List<IzinItem>> riwayat({String? status}) async {
    try {
      return await riwayatOrThrow(status: status);
    } on ApiException {
      return [];
    }
  }

  /// Menandai karyawan sudah kembali. TANPA BODY — jamnya dari server
  /// (fase 88). Mengirim jam dari sini tidak akan berpengaruh apa pun.
  Future<Map<String, dynamic>> tandaiSudahKembali(int id) async {
    try {
      final json = await _apiClient.patch(
        ApiConstants.izinJamKembali(id.toString()),
      );
      return {
        'success': true,
        'message': json['message'] ?? '',
        'jamKembaliAktual': json['data']?['jam_kembali_aktual'],
      };
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