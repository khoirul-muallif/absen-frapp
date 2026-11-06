import 'package:flutter/material.dart';
import '../services/absensi_service.dart';
import '../services/api_client.dart';
import '../models/riwayat_absen_model.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/status_badge.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final AbsensiService _service = AbsensiService();
  late int _bulan;
  late int _tahun;

  bool _loading = true;
  String? _error;
  RekapAbsen? _rekap;
  List<RiwayatAbsenItem> _riwayat = [];

  /// Penanda request terakhir yang diminta. Ganti bulan beruntun melepas
  /// beberapa request sekaligus dan urutan mendaratnya tidak dijamin —
  /// tanpa ini, hasil bulan lama bisa menimpa hasil bulan yang sedang
  /// ditampilkan di header.
  int _requestTerakhir = 0;

  final List<String> _namaBulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _bulan = now.month;
    _tahun = now.year;
    _loadData();
  }

  /// [tampilkanSpinner] false dipakai pull-to-refresh: RefreshIndicator
  /// sudah punya indikatornya sendiri, mengganti konten dengan spinner
  /// layar penuh cuma membuat layar berkedip kosong.
  Future<void> _loadData({bool tampilkanSpinner = true}) async {
    final idRequest = ++_requestTerakhir;

    if (tampilkanSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      // Future.wait, bukan record .wait: record melempar ParallelWaitError
      // yang membungkus penyebabnya, sedangkan Future.wait meneruskan
      // error aslinya apa adanya sehingga `on ApiException` tetap kena.
      final hasil = await Future.wait<dynamic>([
        _service.getRekapOrThrow(bulan: _bulan, tahun: _tahun),
        _service.getRiwayatOrThrow(bulan: _bulan, tahun: _tahun),
      ]);

      if (!mounted || idRequest != _requestTerakhir) return;
      setState(() {
        _rekap = hasil[0] as RekapAbsen;
        _riwayat = hasil[1] as List<RiwayatAbsenItem>;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || idRequest != _requestTerakhir) return;
      _tanganiGagal(e.message, tampilkanSpinner);
    } catch (_) {
      // Jaring pengaman. Sejak pakai varian OrThrow, error parsing model
      // tidak lagi ditelan service — tanpa ini spinner menggantung
      // selamanya, persis bug yang baru saja ditutup di ApiClient.
      if (!mounted || idRequest != _requestTerakhir) return;
      _tanganiGagal('Terjadi kesalahan saat memuat data.', tampilkanSpinner);
    }
  }

  void _tanganiGagal(String pesan, bool tampilkanSpinner) {
    // Refresh yang gagal sementara data lama masih ada: pertahankan datanya,
    // cukup beri tahu lewat snackbar. Membuang isi layar yang masih valid
    // adalah hukuman yang tidak sebanding untuk satu tarikan gagal.
    if (!tampilkanSpinner && _riwayat.isNotEmpty) {
      showAppSnackBar(context, pesan, type: AppSnackBarType.error);
      return;
    }
    // Tidak ada data lama yang bisa dipertahankan — kartu error sudah
    // menyampaikan pesan yang sama, snackbar di atasnya cuma duplikasi.
    setState(() {
      _error = pesan;
      _loading = false;
    });
  }

  void _gantiBulan(int delta) {
    setState(() {
      _bulan += delta;
      if (_bulan > 12) {
        _bulan = 1;
        _tahun++;
      } else if (_bulan < 1) {
        _bulan = 12;
        _tahun--;
      }
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Absensi')),
      body: RefreshIndicator(
        onRefresh: () => _loadData(tampilkanSpinner: false),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                // Tanpa ini RefreshIndicator mati saat konten lebih pendek
                // dari layar — justru di bulan kosong, saat orang paling
                // ingin menarik untuk memuat ulang.
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _gantiBulan(-1),
                      ),
                      Text(
                        '${_namaBulan[_bulan - 1]} $_tahun',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _gantiBulan(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_error != null)
                    _ErrorCard(pesan: _error!, onCobaLagi: _loadData)
                  else ...[
                    if (_rekap != null) _RekapCard(rekap: _rekap!),
                    const SizedBox(height: 20),
                    const Text(
                      'Detail Harian',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_riwayat.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                            child: Text('Belum ada data absensi bulan ini')),
                      )
                    else
                      ..._riwayat.map((item) {
                        final (_, warna) = statusDisplay(item.status);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: warna.withValues(alpha: 0.15),
                              child: Icon(Icons.circle, size: 12, color: warna),
                            ),
                            title: Text('${item.tanggal} • ${item.hari}'),
                            subtitle: Text(
                              '${item.shift} • Masuk: ${item.waktuMasuk} • Pulang: ${item.waktuPulang}'
                              '${item.terlambat != null ? '\nTerlambat ${item.terlambat}' : ''}',
                            ),
                            isThreeLine: item.terlambat != null,
                            trailing: StatusBadge(status: item.status),
                          ),
                        );
                      }),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String pesan;
  final VoidCallback onCobaLagi;
  const _ErrorCard({required this.pesan, required this.onCobaLagi});

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
              'Gagal memuat riwayat bulan ini',
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

class _RekapCard extends StatelessWidget {
  final RekapAbsen rekap;
  const _RekapCard({required this.rekap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _RekapItem(label: 'Tepat Waktu', value: rekap.tepatWaktu),
                _RekapItem(label: 'Terlambat', value: rekap.terlambat),
                _RekapItem(label: 'Alpha', value: rekap.alpha),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _RekapItem(label: 'Izin', value: rekap.izin),
                _RekapItem(label: 'Sakit', value: rekap.sakit),
                _RekapItem(label: 'Cuti', value: rekap.cuti),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Persentase Tepat Waktu: ${rekap.persentaseTepatWaktu}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _RekapItem extends StatelessWidget {
  final String label;
  final int value;
  const _RekapItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}