class JadwalItem {
  final int jadwalId;
  final String tanggal; // format 'd M Y' dari backend, tampilkan apa adanya
  final String jenis;
  final String? shift;
  final bool bisaDiajukan;
  final int? karyawanId;
  final String? karyawanNama;

  JadwalItem({
    required this.jadwalId,
    required this.tanggal,
    required this.jenis,
    this.shift,
    required this.bisaDiajukan,
    this.karyawanId,
    this.karyawanNama,
  });

  factory JadwalItem.fromJson(Map<String, dynamic> json) {
    return JadwalItem(
      jadwalId: json['jadwal_id'],
      tanggal: json['tanggal'] ?? '-',
      jenis: json['jenis'] ?? '-',
      shift: json['shift'],
      bisaDiajukan: json['bisa_diajukan'] ?? true,
      karyawanId: json['karyawan_id'],
      karyawanNama: json['karyawan_nama'],
    );
  }
}