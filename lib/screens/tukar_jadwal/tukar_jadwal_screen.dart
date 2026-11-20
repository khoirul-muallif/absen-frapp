// lib/screens/tukar_jadwal/tukar_jadwal_screen.dart
import 'package:flutter/material.dart';
import 'tukar_jadwal_list.dart';

/// Layar ini sekarang HANYA dibuka dari notifikasi (aksi selain
/// 'diajukan'). Menu Beranda dicabut, dan isinya juga tampil sebagai tab
/// di RiwayatScreen.
///
/// Tidak punya FAB: pengajuan baru dibuat dari JadwalScreen, dengan
/// tanggal yang sudah terpilih di kalender.
class TukarJadwalScreen extends StatelessWidget {
  const TukarJadwalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tukar Jadwal')),
      body: const TukarJadwalList(),
    );
  }
}