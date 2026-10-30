// lib/utils/lokasi_helper.dart
import 'package:geolocator/geolocator.dart';
import 'permission_helper.dart';

class LokasiResult {
  final Position? position;
  final String? error;

  LokasiResult.sukses(this.position) : error = null;
  LokasiResult.gagal(this.error) : position = null;

  bool get berhasil => position != null;
}

/// Logic ambil lokasi + izin lokasi + izin kamera, dipakai bareng oleh
/// StepLokasi (fallback di dalam flow) dan HomeScreen (auto-lokasi
/// sebelum masuk flow). Satu sumber kebenaran supaya pesan error & urutan
/// cek izinnya gak menyimpang antar dua pemanggil.
class LokasiHelper {
  static Future<LokasiResult> ambilLokasi() async {
    try {
      final granted = await PermissionHelper.requestLocation();
      if (!granted) {
        return LokasiResult.gagal('Izin lokasi ditolak. Aktifkan di pengaturan HP.');
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LokasiResult.gagal('GPS tidak aktif. Aktifkan GPS terlebih dahulu.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final cameraGranted = await PermissionHelper.requestCamera();
      if (!cameraGranted) {
        return LokasiResult.gagal('Izin kamera diperlukan untuk langkah selanjutnya.');
      }

      return LokasiResult.sukses(position);
    } catch (e) {
      return LokasiResult.gagal('Gagal mendapatkan lokasi: $e');
    }
  }
}