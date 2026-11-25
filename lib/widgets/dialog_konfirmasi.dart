import 'package:flutter/material.dart';

/// Konfirmasi untuk aksi yang TIDAK bisa dibatalkan sendiri.
///
/// Sengaja tidak dipakai untuk submit pengajuan: pengajuan masih bisa
/// dibatalkan selama belum diproses, jadi salah kirim tidak berakibat
/// apa-apa. Dialog di tiap submit cuma menambah satu ketukan yang
/// lama-lama ditekan tanpa dibaca — dan saat itulah dialog kehilangan
/// gunanya.
///
/// Mengembalikan true kalau user menekan tombol aksinya.
Future<bool> konfirmasi(
  BuildContext context, {
  required String judul,
  required String pesan,
  required String labelAksi,
  bool merusak = true,
}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(judul),
      content: Text(pesan),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          // child: const Text('Batal'),
          child: const Text('Tidak'),
          // child: const Text('Kembali'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor:
                merusak ? Theme.of(dialogContext).colorScheme.error : null,
          ),
          child: Text(labelAksi),
        ),
      ],
    ),
  );

  // Dialog ditutup dengan tombol back atau ketukan di luar → null, dan
  // itu BUKAN persetujuan.
  return hasil ?? false;
}