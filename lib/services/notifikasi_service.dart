import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/notifikasi_model.dart';
import 'auth_service.dart';

class NotifikasiService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, dynamic>> getNotifikasi({bool belumBacaSaja = false}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse(
        '${ApiConstants.notifikasi}?belum_baca=${belumBacaSaja ? 'true' : 'false'}');

    final response = await http.get(uri, headers: headers);
    final json = jsonDecode(response.body);

    if (response.statusCode == 200 && json['success'] == true) {
      final data = json['data'];
      // Karena Laravel pakai paginate(), array asli ada di data.notifikasi.data
      final List items = data['notifikasi']['data'] ?? [];

      return {
        'success': true,
        'totalBelumBaca': data['total_belum_baca'] ?? 0,
        'items': items.map((e) => NotifikasiItem.fromJson(e)).toList(),
      };
    }

    return {'success': false, 'totalBelumBaca': 0, 'items': <NotifikasiItem>[]};
  }

  Future<int> getJumlahBelumBaca() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse(ApiConstants.notifikasiJumlah),
      headers: headers,
    );

    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['success'] == true) {
      return json['data']['belum_baca'] ?? 0;
    }
    return 0;
  }

  Future<bool> tandaiBaca(String id) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('${ApiConstants.notifikasi}/$id/baca'),
      headers: headers,
    );
    final json = jsonDecode(response.body);
    return json['success'] == true;
  }

  Future<bool> tandaiBacaSemua() async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse(ApiConstants.notifikasiBacaSemua),
      headers: headers,
    );
    final json = jsonDecode(response.body);
    return json['success'] == true;
  }

  Future<bool> hapus(String id) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('${ApiConstants.notifikasi}/$id'),
      headers: headers,
    );
    final json = jsonDecode(response.body);
    return json['success'] == true;
  }
}