class IzinItem {
  final int id;
  final String tanggal;
  final String jamKeluar;

  /// Perkiraan yang diisi karyawan SEBELUM pergi. Wajib sejak fase 88,
  /// jadi praktis selalu terisi — kecuali baris lama atau entri admin
  /// lewat Filament, karena itu tetap nullable di sini.
  final String? jamKembaliRencana;

  /// Diisi server dengan now() saat karyawan menandai sudah kembali.
  /// Null berarti izinnya masih berjalan — dan itu yang menentukan
  /// apa yang bisa dilakukan di layar, bukan `status`.
  final String? jamKembaliAktual;

  final String keperluan;
  final String status;
  final String? catatanApproval;
  final String diajukanAt;

  IzinItem({
    required this.id,
    required this.tanggal,
    required this.jamKeluar,
    this.jamKembaliRencana,
    this.jamKembaliAktual,
    required this.keperluan,
    required this.status,
    this.catatanApproval,
    required this.diajukanAt,
  });

  /// Izin yang belum ditandai kembali. Dasar untuk tombol "Saya sudah
  /// kembali" DAN untuk boleh-tidaknya dibatalkan — sama persis dengan
  /// guard di backend, yang memakai jam_kembali_aktual.
  bool get masihBerjalan => jamKembaliAktual == null;

  factory IzinItem.fromJson(Map<String, dynamic> json) {
    return IzinItem(
      id: json['id'],
      tanggal: json['tanggal'] ?? '-',
      jamKeluar: json['jam_keluar'] ?? '-',
      jamKembaliRencana: json['jam_kembali_rencana'],
      jamKembaliAktual: json['jam_kembali_aktual'],
      keperluan: json['keperluan'] ?? '-',
      status: json['status'] ?? '-',
      catatanApproval: json['catatan_approval'],
      diajukanAt: json['diajukan_at'] ?? '-',
    );
  }
}