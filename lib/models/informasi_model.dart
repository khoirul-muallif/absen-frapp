class InformasiItem {
  final int id;
  final String judul;
  final String ringkasan;
  final String tanggalTerbit;

  InformasiItem({
    required this.id,
    required this.judul,
    required this.ringkasan,
    required this.tanggalTerbit,
  });

  factory InformasiItem.fromJson(Map<String, dynamic> json) {
    return InformasiItem(
      id: json['id'],
      judul: json['judul'] ?? '-',
      // Accessor di model backend, Str::limit 150 karakter.
      ringkasan: json['ringkasan'] ?? '',
      // Format 'd M Y' (mis. "23 Nov 2026"), aman ditampilkan mentah.
      tanggalTerbit: json['tanggal_terbit'] ?? '-',
    );
  }
}

/// Satu halaman hasil. `index()` mengirim info paging di akar `data`,
/// jadi FE tidak perlu menebak "masih ada lagi?" dari jumlah record.
class InformasiHalaman {
  final List<InformasiItem> records;
  final int total;
  final int halamanSekarang;
  final int totalHalaman;

  InformasiHalaman({
    required this.records,
    required this.total,
    required this.halamanSekarang,
    required this.totalHalaman,
  });

  bool get adaLagi => halamanSekarang < totalHalaman;

  factory InformasiHalaman.fromJson(Map<String, dynamic> json) {
    final List list = json['records'] ?? [];
    return InformasiHalaman(
      records: list.map((e) => InformasiItem.fromJson(e)).toList(),
      total: json['total'] ?? 0,
      halamanSekarang: json['halaman_sekarang'] ?? 1,
      totalHalaman: json['total_halaman'] ?? 1,
    );
  }
}

/// Dipisah dari InformasiItem karena endpoint detail mengirim `isi`
/// penuh dan TIDAK mengirim `ringkasan` — list dan detail memang
/// berbeda bentuk, bukan subset satu sama lain.
class InformasiDetail {
  final int id;
  final String judul;
  final String isi;
  final String tanggalTerbit;

  InformasiDetail({
    required this.id,
    required this.judul,
    required this.isi,
    required this.tanggalTerbit,
  });

  factory InformasiDetail.fromJson(Map<String, dynamic> json) {
    return InformasiDetail(
      id: json['id'],
      judul: json['judul'] ?? '-',
      isi: json['isi'] ?? '',
      tanggalTerbit: json['tanggal_terbit'] ?? '-',
    );
  }
}