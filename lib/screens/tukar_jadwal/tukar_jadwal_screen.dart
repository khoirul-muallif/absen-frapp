// lib/screens/tukar_jadwal/tukar_jadwal_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/tukar_jadwal_service.dart';
import '../../models/tukar_jadwal_model.dart';
import 'menunggu_respon_screen.dart';
import '../../widgets/status_badge.dart';
import 'tukar_jadwal_form_screen.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/swipe_hint.dart';
import '../../services/api_client.dart';


class TukarJadwalScreen extends StatefulWidget {
  const TukarJadwalScreen({super.key});

  @override
  State<TukarJadwalScreen> createState() => _TukarJadwalScreenState();
}

class _TukarJadwalScreenState extends State<TukarJadwalScreen> {
  final _service = TukarJadwalService();
  List<TukarJadwalItem> _items = [];
  bool _loading = true;
  String? _error;
  int _menungguCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// [tampilkanSpinner] false dipakai pull-to-refresh: RefreshIndicator
  /// sudah punya indikatornya sendiri.
  Future<void> _loadData({bool tampilkanSpinner = true}) async {
    if (tampilkanSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      // Dua request independen; sebelumnya dijalankan berurutan lewat dua
      // pemanggilan terpisah di initState, jadi koneksi buruk berarti dua
      // kali timeout berturut-turut.
      final hasil = await Future.wait([
        _service.riwayatOrThrow(),
        _service.menungguResponSayaOrThrow(),
      ]);

      if (!mounted) return;
      setState(() {
        _items = hasil[0];
        _menungguCount = hasil[1].length;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      _tanganiGagal(e.message, tampilkanSpinner);
    } catch (_) {
      if (!mounted) return;
      _tanganiGagal('Terjadi kesalahan saat memuat data.', tampilkanSpinner);
    }
  }

  void _tanganiGagal(String pesan, bool tampilkanSpinner) {
    if (!tampilkanSpinner && _items.isNotEmpty) {
      showAppSnackBar(context, pesan, type: AppSnackBarType.error);
      return;
    }
    setState(() {
      _error = pesan;
      _loading = false;
    });
  }

  /// Mengembalikan true kalau pembatalan berhasil — dipakai confirmDismiss
  /// untuk memutuskan kartunya jadi hilang atau tidak.
  ///
  /// Bukan optimistis (hapus dulu, kembalikan kalau gagal): Flutter
  /// mensyaratkan widget yang sudah di-dismiss lenyap dari tree, jadi
  /// menyisipkannya kembali dengan Key yang sama melempar "A dismissed
  /// Dismissible widget is still part of the tree".
  Future<bool> _batalkan(TukarJadwalItem item) async {
    final result = await _service.batalkan(item.id);
    if (!mounted) return false;

    if (result['success'] != true) {
      showAppSnackBar(context, result['message'], type: AppSnackBarType.error);
      return false;
    }

    setState(() => _items.removeWhere((e) => e.id == item.id));
    return true;
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
            icon: Badge(
              label: Text('$_menungguCount'),
              isLabelVisible: _menungguCount > 0,
              child: const Icon(Icons.notifications_active_outlined),
            ),
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
        onRefresh: () => _loadData(tampilkanSpinner: false),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 60),
                      Card(
                        color: Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(Icons.cloud_off, color: Colors.red[700]),
                              const SizedBox(height: 12),
                              const Text(
                                'Gagal memuat pengajuan',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _loadData,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        // Tanpa ini pull-to-refresh mati saat daftar kosong,
                        // justru ketika orang paling ingin menariknya.
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 100),
                          Center(
                              child: Text(
                                  'Belum ada pengajuan tukar/pindah jadwal')),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final sayaPengaju =
                              item.jadwalAsal.karyawan == namaSaya;
                          final bisaDibatalkan = sayaPengaju &&
                              (item.status == 'menunggu_rekan' ||
                                  item.status == 'menunggu_admin');

                          final subtitle = item.mode == 'pindah'
                              ? '${item.jadwalAsal.tanggal} → ${item.tanggalBaru ?? '-'}'
                              : '${item.jadwalAsal.karyawan} (${item.jadwalAsal.tanggal}) ⇄ '
                                  '${item.jadwalTujuan?.karyawan ?? '-'} (${item.jadwalTujuan?.tanggal ?? '-'})';

                          final card = Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ListTile(
                                  title: Text(item.mode == 'pindah'
                                      ? 'Pindah Jadwal'
                                      : 'Tukar Jadwal'),
                                  subtitle: Text(
                                    '$subtitle\n${item.alasan}'
                                    '${item.catatanPenolakanRekan != null ? '\nDitolak rekan: ${item.catatanPenolakanRekan}' : ''}'
                                    '${item.catatanApproval != null ? '\nCatatan admin: ${item.catatanApproval}' : ''}',
                                  ),
                                  isThreeLine: true,
                                  trailing: StatusBadge(status: item.status),
                                ),
                                if (bisaDibatalkan) const SwipeHint(),
                              ],
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
                            confirmDismiss: (_) => _batalkan(item),
                            child: card,
                          );
                        },
                      ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TukarJadwalFormScreen()),
          );
          _loadData();
        },
        tooltip: 'Ajukan Tukar/Pindah Jadwal',
        child: const Icon(Icons.add),
      ),
    );
  }
}