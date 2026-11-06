// lib/services/cuti_service.dart
import 'dart:io';
import '../utils/constants.dart';
import '../models/cuti_model.dart';
import '../models/cuti_kuota_model.dart';
import 'api_client.dart';

class CutiService {
  final ApiClient _apiClient = ApiClient();

  Future<List<CutiKuotaItem>> kuotaOrThrow({int? tahun}) async {
    final query = tahun != null ? '?tahun=$tahun' : '';
    final json = await _apiClient.get('${ApiConstants.cutiKuota}$query');
    final records = json['data']['records'] as List;
    return records.map((e) => CutiKuotaItem.fromJson(e)).toList();
  }

  Future<List<CutiKuotaItem>> kuota({int? tahun}) async {
    try {
      return await kuotaOrThrow(tahun: tahun);
    } on ApiException {
      return [];
    }
  }

  /// Varian yang TIDAK menelan error — untuk layar yang perlu membedakan
  /// gagal-request dari benar-benar-kosong (pola sayaDalamRentangOrThrow,
  /// 624b911).
  Future<List<CutiItem>> riwayatOrThrow({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final json = await _apiClient.get('${ApiConstants.cuti}$query');
    final records = json['data']['records'] as List;
    return records.map((e) => CutiItem.fromJson(e)).toList();
  }

  Future<List<CutiItem>> riwayat({String? status}) async {
    try {
      return await riwayatOrThrow(status: status);
    } on ApiException {
      return [];
    }
  }

  Future<Map<String, dynamic>> ajukan({
    required int jenisCutiId,
    required String tanggalMulai,
    required String tanggalSelesai,
    required String alasan,
    File? lampiran,
  }) async {
    try {
      final json = await _apiClient.postMultipart(
        ApiConstants.cuti,
        fields: {
          'jenis_cuti_id': jenisCutiId.toString(),
          'tanggal_mulai': tanggalMulai,
          'tanggal_selesai': tanggalSelesai,
          'alasan': alasan,
        },
        files: lampiran != null ? {'lampiran': lampiran} : {},
      );
      return {'success': true, 'message': json['message'] ?? ''};
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
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