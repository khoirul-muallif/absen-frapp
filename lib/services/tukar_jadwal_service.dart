// lib/services/tukar_jadwal_service.dart
import '../utils/constants.dart';
import '../models/tukar_jadwal_model.dart';
import 'api_client.dart';

class TukarJadwalService {
  final ApiClient _apiClient = ApiClient();

  Future<List<TukarJadwalItem>> riwayat({String? status}) async {
    try {
      final query = status != null ? '?status=$status' : '';
      final json = await _apiClient.get('${ApiConstants.tukarJadwal}$query');
      final records = json['data']['records'] as List;
      return records.map((e) => TukarJadwalItem.fromJson(e)).toList();
    } on ApiException {
      return [];
    }
  }

  Future<List<TukarJadwalItem>> menungguResponSaya() async {
    try {
      final json = await _apiClient.get(ApiConstants.tukarJadwalMenungguRespon);
      final records = json['data']['records'] as List;
      return records.map((e) => TukarJadwalItem.fromJson(e)).toList();
    } on ApiException {
      return [];
    }
  }

  // BELUM dipakai FE — nunggu jawaban soal sumber jadwal_id/jadwal_tujuan_id
  // (Gap 1). Signature disiapkan dulu biar form tinggal manggil begitu
  // picker-nya jelas.
  Future<Map<String, dynamic>> ajukan({
    required String mode, // 'tukar' | 'pindah'
    required int jadwalId,
    int? jadwalTujuanId,
    String? tanggalBaru,
    required String alasan,
  }) async {
    try {
      final json = await _apiClient.post(ApiConstants.tukarJadwal, body: {
        'mode': mode,
        'jadwal_id': jadwalId,
        'alasan': alasan,
        if (jadwalTujuanId != null) 'jadwal_tujuan_id': jadwalTujuanId,
        if (tanggalBaru != null) 'tanggal_baru': tanggalBaru,
      });
      return {'success': true, 'message': json['message'] ?? ''};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  Future<Map<String, dynamic>> responRekan(int id, bool setuju, {String? catatan}) async {
    try {
      final json = await _apiClient.post(
        ApiConstants.tukarJadwalResponRekan(id.toString()),
        body: {
          'setuju': setuju,
          if (catatan != null) 'catatan': catatan,
        },
      );
      return {'success': true, 'message': json['message'] ?? ''};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }

  Future<Map<String, dynamic>> batalkan(int id) async {
    try {
      final json = await _apiClient.delete('${ApiConstants.tukarJadwal}/$id');
      return {'success': true, 'message': json['message'] ?? ''};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    }
  }
}