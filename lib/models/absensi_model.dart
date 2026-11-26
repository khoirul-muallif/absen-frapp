class AbsensiStatus {
  final bool sudahMasuk;
  final bool sudahPulang;
  final String? waktuMasuk;
  final String? waktuPulang;
  final String? status;

  /// true kalau baris yang dikembalikan status() BUKAN hari ini —
  /// sesi terbuka dari kemarin yang belum ditutup (fase 90).
  final bool sesiKemarin;

  /// Tanggal baris yang dikembalikan, untuk ditampilkan.
  final String? tanggal;

  AbsensiStatus({
    required this.sudahMasuk,
    required this.sudahPulang,
    this.waktuMasuk,
    this.waktuPulang,
    this.status,
    this.sesiKemarin = false,
    this.tanggal,
  });

  factory AbsensiStatus.fromJson(Map<String, dynamic> json) {
    final absensi = json['absensi'];
    return AbsensiStatus(
      sudahMasuk: json['sudah_masuk'] ?? false,
      sudahPulang: json['sudah_pulang'] ?? false,
      waktuMasuk: absensi?['waktu_masuk'],
      waktuPulang: absensi?['waktu_pulang'],
      status: absensi?['status'],
      // sesi_kemarin ada di AKAR data, tanggal ada di dalam absensi —
      // sesuai bentuk response backend.
      sesiKemarin: json['sesi_kemarin'] ?? false,
      tanggal: absensi?['tanggal'],
    );
  }
}