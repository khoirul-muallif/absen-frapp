// lib/models/dinas_model.dart
class DinasItem {
  final int id;
  final String tanggalMulai;
  final String tanggalSelesai;
  final String tujuan;
  final String keperluan;
  final String status;
  final String? catatanApproval;
  final String diajukanAt;

  DinasItem({
    required this.id,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.tujuan,
    required this.keperluan,
    required this.status,
    this.catatanApproval,
    required this.diajukanAt,
  });

  factory DinasItem.fromJson(Map<String, dynamic> json) {
    return DinasItem(
      id: json['id'],
      tanggalMulai: json['tanggal_mulai'] ?? '-',
      tanggalSelesai: json['tanggal_selesai'] ?? '-',
      tujuan: json['tujuan'] ?? '-',
      keperluan: json['keperluan'] ?? '-',
      status: json['status'] ?? '-',
      catatanApproval: json['catatan_approval'],
      diajukanAt: json['diajukan_at'] ?? '-',
    );
  }
}