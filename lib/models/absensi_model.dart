class AbsensiStatus {
  final bool sudahMasuk;
  final bool sudahPulang;
  final String? waktuMasuk;
  final String? waktuPulang;
  final String? status;

  AbsensiStatus({
    required this.sudahMasuk,
    required this.sudahPulang,
    this.waktuMasuk,
    this.waktuPulang,
    this.status,
  });

  factory AbsensiStatus.fromJson(Map<String, dynamic> json) {
    final absensi = json['absensi'];
    return AbsensiStatus(
      sudahMasuk: json['sudah_masuk'] ?? false,
      sudahPulang: json['sudah_pulang'] ?? false,
      waktuMasuk: absensi?['waktu_masuk'],
      waktuPulang: absensi?['waktu_pulang'],
      status: absensi?['status'],
    );
  }
}