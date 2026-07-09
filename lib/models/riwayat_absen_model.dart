class RiwayatAbsenItem {
  final int id;
  final String tanggal;
  final String hari;
  final String shift;
  final String jamMasuk;
  final String waktuMasuk;
  final String waktuPulang;
  final String durasi;
  final String? terlambat;
  final String status;
  final String? keterangan;

  RiwayatAbsenItem({
    required this.id,
    required this.tanggal,
    required this.hari,
    required this.shift,
    required this.jamMasuk,
    required this.waktuMasuk,
    required this.waktuPulang,
    required this.durasi,
    this.terlambat,
    required this.status,
    this.keterangan,
  });

  factory RiwayatAbsenItem.fromJson(Map<String, dynamic> json) {
    return RiwayatAbsenItem(
      id: json['id'],
      tanggal: json['tanggal'] ?? '-',
      hari: json['hari'] ?? '-',
      shift: json['shift'] ?? '-',
      jamMasuk: json['jam_masuk'] ?? '-',
      waktuMasuk: json['waktu_masuk'] ?? '-',
      waktuPulang: json['waktu_pulang'] ?? '-',
      durasi: json['durasi'] ?? '-',
      terlambat: json['terlambat'],
      status: json['status'] ?? '-',
      keterangan: json['keterangan'],
    );
  }
}

class RekapAbsen {
  final String bulan;
  final int tepatWaktu;
  final int terlambat;
  final int alpha;
  final int izin;
  final int sakit;
  final int cuti;
  final int dinas;
  final int libur;
  final int totalHadir;
  final int persentaseTepatWaktu;

  RekapAbsen({
    required this.bulan,
    required this.tepatWaktu,
    required this.terlambat,
    required this.alpha,
    required this.izin,
    required this.sakit,
    required this.cuti,
    required this.dinas,
    required this.libur,
    required this.totalHadir,
    required this.persentaseTepatWaktu,
  });

  factory RekapAbsen.fromJson(Map<String, dynamic> json) {
    return RekapAbsen(
      bulan: json['bulan'] ?? '-',
      tepatWaktu: json['tepat_waktu'] ?? 0,
      terlambat: json['terlambat'] ?? 0,
      alpha: json['alpha'] ?? 0,
      izin: json['izin'] ?? 0,
      sakit: json['sakit'] ?? 0,
      cuti: json['cuti'] ?? 0,
      dinas: json['dinas'] ?? 0,
      libur: json['libur'] ?? 0,
      totalHadir: json['total_hadir'] ?? 0,
      persentaseTepatWaktu: json['persentase_tepat_waktu'] ?? 0,
    );
  }
}