import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'absen/absen_menu_screen.dart';
import 'notifikasi_screen.dart';
import 'izin/izin_screen.dart';
import 'lembur/lembur_screen.dart';
import 'dinas/dinas_screen.dart';
import 'cuti/cuti_screen.dart';
import 'jadwal/jadwal_screen.dart';
import '../services/absensi_service.dart';
import '../models/riwayat_absen_model.dart';
import '../services/notifikasi_service.dart';
import 'profil/ubah_password_screen.dart';
import '../widgets/logo_instansi.dart';
import 'profil/profil_screen.dart';
import '../services/informasi_service.dart';
import '../models/informasi_model.dart';
import 'informasi/informasi_detail_screen.dart';
import '../widgets/dialog_konfirmasi.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _absensiService = AbsensiService();
  final _notifikasiService = NotifikasiService();
  int _notifBelumBaca = 0;

  RekapAbsen? _rekap;
  bool _loadingRekap = true;

  final _informasiService = InformasiService();
  List<InformasiItem> _informasiTerbaru = [];

  @override
  void initState() {
    super.initState();
    _loadRekap();
    _loadNotifCount();
    _loadInformasi();
  }

    /// Dua pengumuman terbaru sebagai pengisi ruang bawah. Gagal diam-diam
  /// dan tidak menampilkan apa pun kalau kosong — bagian ini pelengkap,
  /// bukan isi utama Beranda.
  Future<void> _loadInformasi() async {
    try {
      final hasil = await _informasiService.daftar(halaman: 1);
      if (!mounted) return;
      setState(() => _informasiTerbaru = hasil.records.take(2).toList());
    } catch (_) {
      // Biarkan kosong.
    }
  }

  Future<void> _loadNotifCount() async {
    final count = await _notifikasiService.getJumlahBelumBaca();
    if (!mounted) return;
    setState(() => _notifBelumBaca = count);
  }

  Future<void> _loadRekap() async {
    final now = DateTime.now();
    final rekap = await _absensiService.getRekap(
      bulan: now.month,
      tahun: now.year,
    );
    if (!mounted) return;
    setState(() {
      _rekap = rekap;
      _loadingRekap = false;
    });
  }

  Future<void> _refresh() async {
    await Future.wait([_loadRekap(), _loadNotifCount(), _loadInformasi()]);
  }
  

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      // Latar hijau menyambung sampai ke belakang status bar — tanpa ini
      // ada garis abu-abu di atas yang memotong lengkungannya.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Row(
          children: [
            LogoInstansi(url: user?.instansiLogo, ukuran: 28),
            const SizedBox(width: 10),
            const Text('Beranda'),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge.count(
              count: _notifBelumBaca,
              isLabelVisible: _notifBelumBaca > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotifikasiScreen()),
              );
              _loadNotifCount();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) async {
              switch (value) {
                case 'profil':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfilScreen()),
                  );
                  break;
                case 'ubah_password':
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const UbahPasswordScreen(),
                    ),
                  );
                  break;
                case 'logout':
                  final keluar = await konfirmasi(
                    context,
                    judul: 'Keluar dari aplikasi?',
                    pesan: 'Anda perlu memasukkan username dan password '
                        'lagi untuk masuk.',
                    labelAksi: 'Keluar',
                  );
                  if (!keluar || !context.mounted) break;

                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profil',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Profil'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'ubah_password',
                child: ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Ubah Password'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Keluar', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // Stack mengambil tinggi dari Column di atasnya, jadi lengkungan
            // hijau cukup dilukis di belakang tanpa menghitung tinggi kartu.
            Stack(
              children: [
                Container(
                  height: 220,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                ),
                Column(
                  children: [
                    // Ruang untuk AppBar yang sekarang transparan di atas
                    // latar hijau.
                    SizedBox(height: MediaQuery.of(context).padding.top + 64),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _KartuProfil(
                        user: user,
                        rekap: _rekap,
                        loading: _loadingRekap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Menu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                padding: EdgeInsets.zero,

                // Di dalam ListView, jadi gridnya tidak boleh menggulir
                // sendiri — biarkan ListView yang mengurus gulirannya.
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                // Tinggi sel menyesuaikan isinya (lingkaran 52 + jarak 8
                // + label). Rasio di bawah 1 bikin sel lebih tinggi dari
                // isi, dan ikonnya mengambang di ruang kosong.
                childAspectRatio: 1.3,
                children: [
                  _MenuItem(
                    icon: Icons.fingerprint,
                    label: 'Absen',
                    warna: AppColors.primary,
                    // Disegarkan saat kembali: absen mengubah rekap DAN
                    // bisa memicu notifikasi terlambat, tapi Beranda di
                    // belakangnya tidak tahu apa-apa. Sebelumnya angka
                    // tetap 0 sampai ditarik untuk refresh, jadi terasa
                    // seperti absennya tidak tercatat.
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AbsenMenuScreen(),
                        ),
                      );
                      if (!context.mounted) return;
                      _refresh();
                    },
                  ),
                  _MenuItem(
                    icon: Icons.calendar_month,
                    label: 'Jadwal',
                    warna: const Color(0xFF3B82F6),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const JadwalScreen()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.event_busy,
                    label: 'Izin',
                    warna: const Color(0xFFF59E0B),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const IzinScreen()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.more_time,
                    label: 'Lembur',
                    warna: const Color(0xFF8B5CF6),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LemburScreen()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.work_outline,
                    label: 'Dinas',
                    warna: const Color(0xFF0EA5E9),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DinasScreen()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.beach_access,
                    label: 'Cuti',
                    warna: const Color(0xFFEC4899),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CutiScreen()),
                    ),
                  ),
                ],
              ),
            ),
            if (_informasiTerbaru.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  'Informasi Terbaru',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ..._informasiTerbaru.map(
                (item) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InformasiDetailScreen(
                            id: item.id,
                            judulAwal: item.judul,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.campaign_outlined,
                                  size: 20, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.judul,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.tanggalTerbit,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                size: 20, color: Colors.grey[500]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _KartuProfil extends StatelessWidget {
  final dynamic user;
  final RekapAbsen? rekap;
  final bool loading;

  const _KartuProfil({
    required this.user,
    required this.rekap,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: user?.fotoProfil != null
                      ? NetworkImage(user!.fotoProfil!)
                      : null,
                  child: user?.fotoProfil == null
                      ? const Icon(Icons.person, size: 28)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.nama ?? '-',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.jabatan ?? '-',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!loading && rekap != null) ...[
              const Divider(height: 28),
              Row(
                children: [
                  _RingKehadiran(persen: rekap!.persentaseTepatWaktu),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        _AngkaRekap(
                          label: 'Total Hadir',
                          nilai: rekap!.totalHadir,
                        ),
                        const SizedBox(height: 8),
                        _AngkaRekap(
                          label: 'Terlambat',
                          nilai: rekap!.terlambat,
                          warna: rekap!.terlambat > 0
                              ? Colors.orange[800]
                              : null,
                        ),
                        const SizedBox(height: 8),
                        _AngkaRekap(
                          label: 'Tidak Hadir',
                          nilai: rekap!.alpha,
                          warna: rekap!.alpha > 0 ? Colors.red[700] : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  rekap!.bulan,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Persentase tepat waktu sebagai cincin. Satu angka yang paling sering
/// ditanya karyawan, jadi diberi bobot visual paling besar.
class _RingKehadiran extends StatelessWidget {
  final int persen;
  const _RingKehadiran({required this.persen});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: CircularProgressIndicator(
              value: persen / 100,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$persen%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'tepat\nwaktu',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AngkaRekap extends StatelessWidget {
  final String label;
  final int nilai;
  final Color? warna;

  const _AngkaRekap({required this.label, required this.nilai, this.warna});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ),
        Text(
          '$nilai',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: warna,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color warna;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.warna,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: warna),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}