// lib/services/absensi_service.dart
import 'dart:io';
import '../utils/constants.dart';
import 'api_client.dart';
import '../models/absensi_model.dart';
import '../models/riwayat_absen_model.dart';

class AbsensiService {
  final ApiClient _apiClient = ApiClient();

  Future<AbsensiStatus?> getStatus() async {
    try {
      final json = await _apiClient.get('${ApiConstants.baseUrl}/absensi/status');
      return AbsensiStatus.fromJson(json['data']);
    } on ApiException {
      return null;
    }
  }

  /// Varian yang TIDAK menelan error — untuk layar yang perlu membedakan
  /// gagal-request dari benar-benar-kosong. Pola sama dengan
  /// JadwalService.sayaDalamRentangOrThrow() (624b911).
  Future<List<RiwayatAbsenItem>> getRiwayatOrThrow({
    required int bulan,
    required int tahun,
  }) async {
    final json = await _apiClient.get(
      '${ApiConstants.baseUrl}/absensi/riwayat?bulan=$bulan&tahun=$tahun',
    );
    final records = json['data']['records'] as List;
    return records.map((e) => RiwayatAbsenItem.fromJson(e)).toList();
  }

  Future<RekapAbsen> getRekapOrThrow({
    required int bulan,
    required int tahun,
  }) async {
    final json = await _apiClient.get(
      '${ApiConstants.baseUrl}/absensi/rekap?bulan=$bulan&tahun=$tahun',
    );
    return RekapAbsen.fromJson(json['data']);
  }

  /// Menelan error jadi list kosong. Dipertahankan untuk pemanggil yang
  /// memang tidak punya cara menampilkan kegagalan (mis. ringkasan di
  /// Beranda) — jangan dipakai di layar yang punya state error sendiri.
  Future<List<RiwayatAbsenItem>> getRiwayat({
    required int bulan,
    required int tahun,
  }) async {
    try {
      return await getRiwayatOrThrow(bulan: bulan, tahun: tahun);
    } on ApiException {
      return [];
    }
  }

  Future<RekapAbsen?> getRekap({required int bulan, required int tahun}) async {
    try {
      return await getRekapOrThrow(bulan: bulan, tahun: tahun);
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
      final json = await _apiClient.postMultipart(
        endpoint,
        fields: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          ...extraFields,
        },
        files: {fotoFieldName: foto},
      );
      return {
        'success': true,
        'message': json['message'] ?? '',
        'data': json['data'],
      };
    } on ApiException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }
}