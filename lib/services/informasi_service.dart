import '../utils/constants.dart';
import '../models/informasi_model.dart';
import 'api_client.dart';

class InformasiService {
  final ApiClient _apiClient = ApiClient();

  /// Melempar ApiException. Beda dari NotifikasiService yang menelan
  /// error jadi list kosong: di sini daftar kosong karena belum ada
  /// pengumuman dan daftar kosong karena jaringan mati harus bisa
  /// dibedakan — yang pertama wajar, yang kedua perlu tombol Coba Lagi.
  Future<InformasiHalaman> daftar({int halaman = 1, String q = ''}) async {
    final params = <String>['page=$halaman'];
    if (q.trim().isNotEmpty) {
      params.add('q=${Uri.encodeQueryComponent(q.trim())}');
    }
    final json = await _apiClient.get('${ApiConstants.informasi}?${params.join('&')}');
    return InformasiHalaman.fromJson(json['data']);
  }

  /// Backend pakai findOrFail DI DALAM scope aktif(), jadi pengumuman
  /// yang dinonaktifkan admin sementara daftarnya terbuka akan 404 saat
  /// dibuka. Pemanggil perlu membedakannya dari kegagalan lain.
  Future<InformasiDetail> detail(int id) async {
    final json = await _apiClient.get('${ApiConstants.informasi}/$id');
    return InformasiDetail.fromJson(json['data']);
  }
}