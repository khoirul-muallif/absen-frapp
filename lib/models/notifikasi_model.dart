class NotifikasiItem {
  final String id;
  final String judul;
  final String pesan;
  final String tipe;

  /// Hanya terisi untuk `tipe: 'tukar_jadwal'` — ketujuh notifikasinya
  /// memakai tipe yang SAMA, jadi `aksi` satu-satunya yang membedakan
  /// "disetujui admin" dari "ditolak admin". Null untuk tipe lain.
  /// Nilai: diajukan, disetujui_rekan, ditolak_rekan, approved, rejected,
  /// dibatalkan_admin, dibatalkan_pengaju.
  final String? aksi;

  final bool sudahBaca;
  final String? dibacaAt;
  final String dibuatAt;

  NotifikasiItem({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.tipe,
    this.aksi,
    required this.sudahBaca,
    this.dibacaAt,
    required this.dibuatAt,
  });

  factory NotifikasiItem.fromJson(Map<String, dynamic> json) {
    return NotifikasiItem(
      id: json['id'],
      judul: json['judul'] ?? '-',
      pesan: json['pesan'] ?? '-',
      tipe: json['tipe'] ?? 'info',
      // `aksi` tidak diratakan ke akar oleh NotifikasiController — cuma
      // judul, pesan, dan tipe yang diangkat. Sisanya tetap di dalam `data`,
      // yang ikut dikirim utuh.
      aksi: json['data']?['aksi'],
      sudahBaca: json['sudah_baca'] ?? false,
      dibacaAt: json['dibaca_at'],
      dibuatAt: json['dibuat_at'] ?? '-',
    );
  }

  /// Baris TukarJadwal untuk aksi ini SUDAH DIHAPUS di backend (keputusan
  /// 9 Nov 2026: id tetap dikirim demi konsistensi bentuk data). Kalau
  /// notifikasi nanti bisa di-tap untuk membuka detail, yang ini harus
  /// dikecualikan — jangan sampai 404 jadi crash.
  bool get detailSudahTidakAda => aksi == 'dibatalkan_pengaju';
}