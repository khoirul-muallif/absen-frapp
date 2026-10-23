import '../utils/constants.dart';
import '../models/jadwal_model.dart';
import 'api_client.dart';

class JadwalService {
  final ApiClient _apiClient = ApiClient();

  /// Jadwal milik sendiri pada satu tanggal (dipakai buat ambil jadwal_id
  /// dari tanggal yang dipilih di DatePicker form TukarJadwal). Null kalau
  /// tidak ada baris Jadwal di tanggal itu.
  Future<JadwalItem?> sayaPadaTanggal(String tanggal) async {
    try {
      final json = await _apiClient.get(ApiConstants.jadwalSaya(tanggal, tanggal));
      final records = json['data']['records'] as List;
      if (records.isEmpty) return null;
      return JadwalItem.fromJson(records.first);
    } on ApiException {
      return null;
    }
  }

  /// Jadwal rekan satu unit_kerja+instansi pada satu tanggal -- sumber
  /// pilihan jadwal_tujuan_id untuk mode tukar.
  Future<List<JadwalItem>> rekanPadaTanggal(String tanggal) async {
    try {
      final json = await _apiClient.get(ApiConstants.jadwalRekan(tanggal));
      final records = json['data']['records'] as List;
      return records.map((e) => JadwalItem.fromJson(e)).toList();
    } on ApiException {
      return [];
    }
  }
}