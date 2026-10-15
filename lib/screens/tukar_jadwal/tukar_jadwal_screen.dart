// lib/screens/tukar_jadwal/tukar_jadwal_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/tukar_jadwal_service.dart';
import '../../models/tukar_jadwal_model.dart';
import 'menunggu_respon_screen.dart';

class TukarJadwalScreen extends StatefulWidget {
  const TukarJadwalScreen({super.key});

  @override
  State<TukarJadwalScreen> createState() => _TukarJadwalScreenState();
}

class _TukarJadwalScreenState extends State<TukarJadwalScreen> {
  final _service = TukarJadwalService();
  List<TukarJadwalItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final items = await _service.riwayat();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
      case 'ditolak_rekan':
        return Colors.red;
      case 'menunggu_rekan':
        return Colors.orange;
      default: // menunggu_admin
        return Colors.grey;
    }
  }

  Future<void> _batalkan(TukarJadwalItem item) async {
    final removedIndex = _items.indexWhere((e) => e.id == item.id);
    if (removedIndex == -1) return;

    setState(() => _items.removeAt(removedIndex));

    final result = await _service.batalkan(item.id);
    if (result['success'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // CATATAN: response riwayat() gak kirim ID pengaju/tujuan, cuma nama.
    // Deteksi "ini pengajuan saya sendiri" pakai cocokin nama -- rawan kalau
    // ada 2 karyawan nama sama persis. Lihat Gap 2 di pembahasan sesi ini.
    final namaSaya = context.read<AuthProvider>().user?.nama;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tukar Jadwal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Menunggu Respon Saya',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MenungguResponScreen()),
              );
              _loadData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('Belum ada pengajuan tukar/pindah jadwal')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final sayaPengaju = item.jadwalAsal.karyawan == namaSaya;
                      final bisaDibatalkan = sayaPengaju &&
                          (item.status == 'menunggu_rekan' || item.status == 'menunggu_admin');

                      final subtitle = item.mode == 'pindah'
                          ? '${item.jadwalAsal.tanggal} → ${item.tanggalBaru ?? '-'}'
                          : '${item.jadwalAsal.karyawan} (${item.jadwalAsal.tanggal}) ⇄ '
                              '${item.jadwalTujuan?.karyawan ?? '-'} (${item.jadwalTujuan?.tanggal ?? '-'})';

                      final card = Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(item.mode == 'pindah' ? 'Pindah Jadwal' : 'Tukar Jadwal'),
                          subtitle: Text(
                            '$subtitle\n${item.alasan}'
                            '${item.catatanPenolakanRekan != null ? '\nDitolak rekan: ${item.catatanPenolakanRekan}' : ''}'
                            '${item.catatanApproval != null ? '\nCatatan admin: ${item.catatanApproval}' : ''}',
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            item.status,
                            style: TextStyle(
                              color: _statusColor(item.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );

                      if (!bisaDibatalkan) return card;

                      return Dismissible(
                        key: Key('tukar-${item.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _batalkan(item),
                        child: card,
                      );
                    },
                  ),
      ),
      // Belum ada FloatingActionButton "Ajukan" -- nunggu jawaban Gap 1.
    );
  }
}