// lib/models/cuti_model.dart
class CutiItem {
  final int id;
  final String jenisCuti;
  final String tanggalMulai;
  final String tanggalSelesai;
  final int jumlahHari;
  final String alasan;
  final String status;
  final String? catatanApproval;
  final String diajukanAt;

  CutiItem({
    required this.id,
    required this.jenisCuti,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.jumlahHari,
    required this.alasan,
    required this.status,
    this.catatanApproval,
    required this.diajukanAt,
  });

  factory CutiItem.fromJson(Map<String, dynamic> json) {
    return CutiItem(
      id: json['id'],
      jenisCuti: json['jenis_cuti'] ?? '-',
      tanggalMulai: json['tanggal_mulai'] ?? '-',
      tanggalSelesai: json['tanggal_selesai'] ?? '-',
      jumlahHari: json['jumlah_hari'] ?? 0,
      alasan: json['alasan'] ?? '-',
      status: json['status'] ?? '-',
      catatanApproval: json['catatan_approval'],
      diajukanAt: json['diajukan_at'] ?? '-',
    );
  }
}