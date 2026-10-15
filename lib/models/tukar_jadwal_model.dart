// lib/models/tukar_jadwal_model.dart
class JadwalRef {
  final String tanggal;
  final String? shift;
  final String? karyawan;

  JadwalRef({required this.tanggal, this.shift, this.karyawan});

  factory JadwalRef.fromJson(Map<String, dynamic> json) {
    return JadwalRef(
      tanggal: json['tanggal'] ?? '-',
      shift: json['shift'],
      karyawan: json['karyawan'],
    );
  }
}

class TukarJadwalItem {
  final int id;
  final String mode; // 'tukar' | 'pindah'
  final String status;
  final String alasan;
  final JadwalRef jadwalAsal;
  final JadwalRef? jadwalTujuan;
  final String? tanggalBaru;
  final String? catatanPenolakanRekan;
  final String? catatanApproval;
  final String diajukanAt;

  TukarJadwalItem({
    required this.id,
    required this.mode,
    required this.status,
    required this.alasan,
    required this.jadwalAsal,
    this.jadwalTujuan,
    this.tanggalBaru,
    this.catatanPenolakanRekan,
    this.catatanApproval,
    required this.diajukanAt,
  });

  factory TukarJadwalItem.fromJson(Map<String, dynamic> json) {
    return TukarJadwalItem(
      id: json['id'],
      mode: json['mode'] ?? 'tukar',
      status: json['status'] ?? '-',
      alasan: json['alasan'] ?? '-',
      jadwalAsal: JadwalRef.fromJson(json['jadwal_asal'] ?? {}),
      jadwalTujuan: json['jadwal_tujuan'] != null
          ? JadwalRef.fromJson(json['jadwal_tujuan'])
          : null,
      tanggalBaru: json['tanggal_baru'],
      catatanPenolakanRekan: json['catatan_penolakan_rekan'],
      catatanApproval: json['catatan_approval'],
      diajukanAt: json['diajukan_at'] ?? '-',
    );
  }
}