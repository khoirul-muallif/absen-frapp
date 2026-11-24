import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/section_card.dart';

/// Read-only. Tidak ada endpoint untuk mengubah data karyawan dari
/// aplikasi, dan menampilkannya sebagai field bergaya input akan
/// menjanjikan sesuatu yang tidak bisa dilakukan.
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: user == null
          ? const Center(child: Text('Data profil tidak tersedia'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _KartuIdentitas(user: user),
                const SizedBox(height: 16),
                // Dikelompokkan per tema. Sepuluh baris berderet tanpa
                // jeda sulit dipindai — mata tidak punya titik istirahat.
                ..._section('Data Diri', Icons.person_outline, [
                  ('Nama Lengkap', user.nama),
                  ('NIP', user.nip),
                ]),
                ..._section('Akun', Icons.lock_outline, [
                  ('Username', user.username),
                  ('Email', user.email),
                ]),
                ..._section('Kepegawaian', Icons.work_outline, [
                  ('Jabatan', user.jabatan),
                  ('Unit Kerja', user.unitKerja),
                  ('Status Pegawai', _kapital(user.statusPegawai)),
                  ('Tipe Jadwal',
                      user.tipeJadwal == 'umum' ? 'Umum' : 'Rotasi'),
                  ('Bergabung Sejak', user.tanggalBergabung),
                  ('Instansi', user.instansiNama),
                ]),
              ],
            ),
    );
  }

  /// Nilai mentah dari DB huruf kecil semua ('tetap', 'kontrak').
  String _kapital(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  /// Baris yang nilainya kosong DILEWATI, bukan ditampilkan sebagai "-".
  /// ~110 dari 150 karyawan RS tidak punya email (backend fase 81).
  ///
  /// Section yang SELURUH barisnya kosong tidak ditampilkan sama sekali
  /// — kartu berjudul tanpa isi sama membingungkannya dengan baris
  /// kosong yang justru mau dihindari.
  List<Widget> _section(
      String judul, IconData ikon, List<(String, String?)> data) {
    final terisi = data
        .where((d) => d.$2 != null && d.$2!.isNotEmpty)
        .map((d) => _BarisInfo(label: d.$1, nilai: d.$2!))
        .toList();

    if (terisi.isEmpty) return [];
    return [SectionCard(title: judul, icon: ikon, children: terisi)];
  }
}

class _KartuIdentitas extends StatelessWidget {
  final UserModel user;
  const _KartuIdentitas({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: user.fotoProfil != null
                      ? NetworkImage(user.fotoProfil!)
                      : null,
                  child: user.fotoProfil == null
                      ? const Icon(Icons.person, size: 32)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nama,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.jabatan,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (user.tanggalBergabung != null) ...[
              const Divider(height: 28),
              Row(
                children: [
                  Icon(Icons.badge_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Bergabung sejak ${user.tanggalBergabung}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarisInfo extends StatelessWidget {
  final String label;
  final String nilai;
  const _BarisInfo({required this.label, required this.nilai});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(nilai, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}