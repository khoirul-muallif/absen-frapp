// lib/screens/tukar_jadwal/tukar_jadwal_screen.dart
import 'package:flutter/material.dart';
import 'tukar_jadwal_form_screen.dart';
import 'tukar_jadwal_list.dart';

/// Tetap ada sebagai layar yang bisa di-push — notifikasi mengarah ke sini
/// untuk aksi selain 'diajukan'. Menu di Beranda dicabut; isinya sekarang
/// juga tampil sebagai tab di RiwayatScreen.
class TukarJadwalScreen extends StatefulWidget {
  const TukarJadwalScreen({super.key});

  @override
  State<TukarJadwalScreen> createState() => _TukarJadwalScreenState();
}

class _TukarJadwalScreenState extends State<TukarJadwalScreen> {
  final _listKey = GlobalKey<TukarJadwalListState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tukar Jadwal')),
      body: TukarJadwalList(key: _listKey),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TukarJadwalFormScreen()),
          );
          _listKey.currentState?.muatUlang(tampilkanSpinner: false);
        },
        tooltip: 'Ajukan Tukar/Pindah Jadwal',
        child: const Icon(Icons.add),
      ),
    );
  }
}