class IzinItem {
  final int id;
  final String tanggal;
  final String jamKeluar;
  final String? jamKembali;
  final String keperluan;
  final String status;
  final String? catatanApproval;
  final String diajukanAt;

  IzinItem({
    required this.id,
    required this.tanggal,
    required this.jamKeluar,
    this.jamKembali,
    required this.keperluan,
    required this.status,
    this.catatanApproval,
    required this.diajukanAt,
  });

  factory IzinItem.fromJson(Map<String, dynamic> json) {
    return IzinItem(
      id: json['id'],
      tanggal: json['tanggal'] ?? '-',
      jamKeluar: json['jam_keluar'] ?? '-',
      jamKembali: json['jam_kembali'],
      keperluan: json['keperluan'] ?? '-',
      status: json['status'] ?? '-',
      catatanApproval: json['catatan_approval'],
      diajukanAt: json['diajukan_at'] ?? '-',
    );
  }
}