// lib/models/cuti_kuota_model.dart
class CutiKuotaItem {
  final int jenisCutiId;
  final String nama;
  final int? semester;
  final bool potongKuota;
  final bool perluLampiran;
  final int kuota;
  final int terpakai;
  final int sisa;

  CutiKuotaItem({
    required this.jenisCutiId,
    required this.nama,
    this.semester,
    required this.potongKuota,
    required this.perluLampiran,
    required this.kuota,
    required this.terpakai,
    required this.sisa,
  });

  factory CutiKuotaItem.fromJson(Map<String, dynamic> json) {
    return CutiKuotaItem(
      jenisCutiId: json['jenis_cuti_id'],
      nama: json['nama'] ?? '-',
      semester: json['semester'],
      potongKuota: json['potong_kuota'] ?? false,
      perluLampiran: json['perlu_lampiran'] ?? false,
      kuota: json['kuota'] ?? 0,
      terpakai: json['terpakai'] ?? 0,
      sisa: json['sisa'] ?? 0,
    );
  }
}