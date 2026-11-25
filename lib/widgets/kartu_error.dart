import 'package:flutter/material.dart';

/// Kartu gagal-muat yang seragam. Sebelumnya disalin ke enam layar
/// dengan lima bentuk berbeda — ada yang pakai Colors.red[50], ada yang
/// errorContainer, ada yang cuma teks polos tanpa kartu.
///
/// Bentuk ini diambil dari _ErrorCard milik RiwayatScreen: satu-satunya
/// yang memakai warna tema, bukan Colors.red hardcode, jadi ikut berubah
/// kalau temanya diganti.
class KartuError extends StatelessWidget {
  final String pesan;
  final VoidCallback onCobaLagi;

  /// Judulnya menyebut APA yang gagal dimuat, bukan "Terjadi kesalahan".
  final String judul;

  const KartuError({
    super.key,
    required this.pesan,
    required this.onCobaLagi,
    this.judul = 'Gagal memuat data',
  });

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    return Card(
      color: skema.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.cloud_off, color: skema.onErrorContainer, size: 32),
            const SizedBox(height: 12),
            Text(
              judul,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: skema.onErrorContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: skema.onErrorContainer),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onCobaLagi,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keadaan kosong yang seragam: ikon, judul, dan satu kalimat penjelas.
///
/// Dipakai juga untuk "pencarian tidak ketemu" — yang penting keduanya
/// DIBEDAKAN. Pesan "Belum ada data" saat user baru mengetik kata kunci
/// membuat seolah seluruh modulnya kosong (lihat InformasiScreen).
class KartuKosong extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String? penjelasan;

  const KartuKosong({
    super.key,
    required this.ikon,
    required this.judul,
    this.penjelasan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(ikon, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            judul,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
          ),
          if (penjelasan != null) ...[
            const SizedBox(height: 6),
            Text(
              penjelasan!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}