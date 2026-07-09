class NotifikasiItem {
  final String id;
  final String judul;
  final String pesan;
  final String tipe;
  final bool sudahBaca;
  final String? dibacaAt;
  final String dibuatAt;

  NotifikasiItem({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.tipe,
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
      sudahBaca: json['sudah_baca'] ?? false,
      dibacaAt: json['dibaca_at'],
      dibuatAt: json['dibuat_at'] ?? '-',
    );
  }
}