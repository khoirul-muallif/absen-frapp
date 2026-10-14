// lib/services/notifikasi_service.dart
import '../utils/constants.dart';
import '../models/notifikasi_model.dart';
import 'api_client.dart';

class NotifikasiService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getNotifikasi({bool belumBacaSaja = false}) async {
    try {
      final json = await _apiClient.get(
        '${ApiConstants.notifikasi}?belum_baca=${belumBacaSaja ? 'true' : 'false'}',
      );
      final data = json['data'];
      final List items = data['records'] ?? [];

      return {
        'success': true,
        'totalBelumBaca': data['total_belum_baca'] ?? 0,
        'items': items.map((e) => NotifikasiItem.fromJson(e)).toList(),
      };
    } on ApiException {
      return {'success': false, 'totalBelumBaca': 0, 'items': <NotifikasiItem>[]};
    }
  }

  Future<int> getJumlahBelumBaca() async {
    try {
      final json = await _apiClient.get(ApiConstants.notifikasiJumlah);
      return json['data']['belum_baca'] ?? 0;
    } on ApiException {
      return 0;
    }
  }

  Future<bool> tandaiBaca(String id) async {
    try {
      await _apiClient.post('${ApiConstants.notifikasi}/$id/baca');
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> tandaiBacaSemua() async {
    try {
      await _apiClient.post(ApiConstants.notifikasiBacaSemua);
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> hapus(String id) async {
    try {
      await _apiClient.delete('${ApiConstants.notifikasi}/$id');
      return true;
    } on ApiException {
      return false;
    }
  }
}