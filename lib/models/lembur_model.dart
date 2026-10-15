// lib/models/lembur_model.dart
class LemburItem {
  final int id;
  final String tanggal;
  final String jamMulai;
  final String jamSelesai;
  final String? alasan;
  final String status;
  final String? catatanApproval;
  final String diajukanAt;

  LemburItem({
    required this.id,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    this.alasan,
    required this.status,
    this.catatanApproval,
    required this.diajukanAt,
  });

  factory LemburItem.fromJson(Map<String, dynamic> json) {
    return LemburItem(
      id: json['id'],
      tanggal: json['tanggal'] ?? '-',
      jamMulai: json['jam_mulai'] ?? '-',
      jamSelesai: json['jam_selesai'] ?? '-',
      alasan: json['alasan'],
      status: json['status'] ?? '-',
      catatanApproval: json['catatan_approval'],
      diajukanAt: json['diajukan_at'] ?? '-',
    );
  }
}