import 'package:flutter/material.dart';
import '../services/absensi_service.dart';
import '../services/api_client.dart';
import '../models/riwayat_absen_model.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/status_badge.dart';
import 'tukar_jadwal/tukar_jadwal_list.dart';
import '../widgets/kartu_error.dart';

/// Shell bertab. Dua tab saja — Presensi dan Tukar Jadwal. Izin, Cuti,
/// Dinas, dan Lembur SENGAJA tidak ikut: keputusan 20 Nov 2026, mereka
/// tetap di layar terpisah lewat grid Beranda.
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => RiwayatScreenState();
}

class RiwayatScreenState extends State<RiwayatScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _tukarJadwalKey = GlobalKey<TukarJadwalListState>();
  final _presensiKey = GlobalKey<_PresensiTabState>();
  int _tabTerakhir = 0;

  /// Dipanggil MainScreen saat tab Riwayat dibuka. Tanpa ini datanya
  /// dimuat sekali di initState lalu ditahan wantKeepAlive selamanya —
  /// absen baru tidak muncul sampai ditarik untuk refresh.
  void segarkanTabAktif() {
    if (_tabController.index == 0) {
      _presensiKey.currentState?.muatUlang();
    } else {
      _tukarJadwalKey.currentState?.muatUlang(tampilkanSpinner: false);
    }
  }
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_saatTabBerganti);
  }

  /// Tanpa ini TukarJadwalList memuat sekali di initState lalu diam:
  /// menjawab pengajuan lewat notifikasi, lalu kembali ke tab ini, dan
  /// banner masih menyebut angka lama sampai ditarik untuk refresh.
  void _saatTabBerganti() {
    // Listener ini dipanggil berkali-kali selama animasi dan geseran.
    // Kerjakan sekali saja, setelah indeksnya benar-benar berpindah.
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == _tabTerakhir) return;
    _tabTerakhir = _tabController.index;

    if (_tabController.index == 1) {
      // Tanpa spinner: isinya sudah ada di layar, menggantinya dengan
      // spinner membuat tab berkedip kosong tiap kali dibuka.
      _tukarJadwalKey.currentState?.muatUlang(tampilkanSpinner: false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Presensi'),
            Tab(text: 'Tukar Jadwal'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PresensiTab(key: _presensiKey),
          TukarJadwalList(key: _tukarJadwalKey),
        ],
      ),
    );
  }
}

/// Isi RiwayatScreen yang lama, tanpa Scaffold dan AppBar-nya.
class _PresensiTab extends StatefulWidget {
  const _PresensiTab({super.key});

  @override
  State<_PresensiTab> createState() => _PresensiTabState();
}

class _PresensiTabState extends State<_PresensiTab>
    with AutomaticKeepAliveClientMixin {
  final AbsensiService _service = AbsensiService();
  late int _bulan;
  late int _tahun;

  bool _loading = true;
  String? _error;
  RekapAbsen? _rekap;
  List<RiwayatAbsenItem> _riwayat = [];

  /// Daftar harian sebulan penuh bisa 30 baris — layar jadi panjang dan
  /// rekap di atasnya ikut tertimbun saat digulir. Tampilkan sebagian
  /// dulu, sisanya dibuka kalau diminta.
  static const _batasAwal = 10;
  bool _tampilSemua = false;

  /// Tanpa ini, berpindah ke tab Tukar Jadwal lalu kembali membuang bulan
  /// yang sedang dilihat dan memuat ulang dari bulan berjalan.
  @override
  bool get wantKeepAlive => true;

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
      _tampilSemua = false;
    });
    _loadData();
  }

  /// Publik supaya RiwayatScreen bisa menyegarkan saat tabnya dibuka.
  /// Tanpa spinner: bulan yang sedang dilihat tidak boleh berkedip.
  Future<void> muatUlang() => _loadData(tampilkanSpinner: false);

  @override
  Widget build(BuildContext context) {
    super.build(context); // wajib untuk AutomaticKeepAliveClientMixin

    // Tidak ada data masa depan di backend, jadi maju melewati bulan
    // berjalan selalu menghasilkan layar kosong yang terlihat seperti bug.
    final sekarang = DateTime.now();
    final diBulanBerjalan = _bulan == sekarang.month && _tahun == sekarang.year;

    return RefreshIndicator(
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
                      onPressed: diBulanBerjalan ? null : () => _gantiBulan(1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_error != null)
                  KartuError(
                    pesan: _error!,
                    judul: 'Gagal memuat riwayat bulan ini',
                    onCobaLagi: _loadData,
                  )
                else ...[
                  if (_rekap != null) _RekapCard(rekap: _rekap!),
                  const SizedBox(height: 20),
                  const Text(
                    'Detail Harian',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_riwayat.isEmpty)
                    const KartuKosong(
                      ikon: Icons.event_note_outlined,
                      judul: 'Belum ada data absensi bulan ini',
                    )
                  else
                    ...(_tampilSemua
                            ? _riwayat
                            : _riwayat.take(_batasAwal))
                        .map((item) {
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
                  if (!_tampilSemua && _riwayat.length > _batasAwal)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () => setState(() => _tampilSemua = true),
                          icon: const Icon(Icons.expand_more, size: 18),
                          label: Text(
                            'Lihat semua (${_riwayat.length} hari)',
                          ),
                        ),
                      ),
                    ),
                ],
              ],
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _RekapItem(label: 'Tepat Waktu', value: rekap.tepatWaktu),
                _RekapItem(label: 'Terlambat', value: rekap.terlambat),
                // "Alpha" istilah administratif. Di kartu yang dibaca
                // karyawan sendiri, "Tidak Hadir" lebih jelas.
                _RekapItem(label: 'Tidak Hadir', value: rekap.alpha),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _RekapItem(label: 'Izin', value: rekap.izin),
                _RekapItem(label: 'Cuti', value: rekap.cuti),
                _RekapItem(label: 'Dinas', value: rekap.dinas),
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