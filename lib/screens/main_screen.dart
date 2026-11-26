import 'package:flutter/material.dart';
import '../services/tukar_jadwal_service.dart';
import 'home_screen.dart';
import 'riwayat_screen.dart';
import 'informasi/informasi_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'profil/ubah_password_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _tukarJadwalService = TukarJadwalService();
  final _riwayatKey = GlobalKey<RiwayatScreenState>();
  final _informasiKey = GlobalKey<InformasiScreenState>();

  int _index = 0;

  /// Badge di tab Riwayat. Satu-satunya hal yang memberi tahu karyawan
  /// ada rekan menunggu jawabannya TANPA dia mencari — notifikasi hilang
  /// setelah diklik, dan banner di dalam tab baru terlihat kalau tabnya
  /// sudah dibuka. Tanpa ini, pengajuan macet di menunggu_rekan karena
  /// yang dituju tidak pernah tahu (5 kasus tercatat 9 Nov 2026).
  int _menungguTukarJadwal = 0;

  // `const` dibuang. Dengan const, ketiga layar dievaluasi saat compile dan
  // tidak pernah dibangun ulang — perubahan tidak terlihat sampai restart
  // penuh, bukan hot reload. Sempat bikin bingung 20 Nov 2026.
  late final _tabs = [
    const HomeScreen(),
    RiwayatScreen(key: _riwayatKey),
    InformasiScreen(key: _informasiKey),
  ];

  @override
  void initState() {
    super.initState();
    _muatJumlahMenunggu();
    _periksaHarusGantiPassword();
  }
  
  /// Diarahkan SETELAH frame pertama, bukan di initState langsung —
  /// Navigator belum siap saat initState berjalan.
  ///
  /// Boleh ditutup: keputusan 26 Nov 2026, flag ini mengarahkan bukan
  /// memaksa. Tapi flagnya tetap true sampai password benar-benar
  /// diganti, jadi peringatan ini muncul lagi tiap aplikasi dibuka.
  void _periksaHarusGantiPassword() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      if (user?.harusGantiPassword != true) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const UbahPasswordScreen(karenaReset: true),
        ),
      );
    });
  }
  Future<void> _muatJumlahMenunggu() async {
    // Gagal diam-diam, jangan melempar. Dipanggil dari initState tanpa
    // await, jadi lemparan di sini jadi unhandled async error — dan
    // badge gagal memberi tahu justru saat jaringan bermasalah.
    try {
      final items = await _tukarJadwalService.menungguResponSaya();
      if (!mounted) return;
      setState(() => _menungguTukarJadwal = items.length);
    } catch (_) {
      // Biarkan angka sebelumnya. Badge yang usang lebih baik daripada
      // badge yang mendadak 0 dan membuat karyawan mengira sudah beres.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);

          // Menjawab pengajuan terjadi di dalam tab Riwayat, jadi angkanya
          // perlu disegarkan saat keluar dari sana — bukan saat masuk.
          if (i != 1) _muatJumlahMenunggu();

          // WAJIB, bukan sekadar penyegar: sejak pemuatan awal dibuang
          // dari initState, inilah satu-satunya yang memuat kedua tab
          // ini. IndexedStack membangun ketiganya sekaligus, jadi memuat
          // di initState berarti request untuk layar yang mungkin tidak
          // pernah dilihat.
          if (i == 1) _riwayatKey.currentState?.segarkanTabAktif();
          if (i == 2) _informasiKey.currentState?.muatSaatDibuka();
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: _menungguTukarJadwal,
              isLabelVisible: _menungguTukarJadwal > 0,
              // Tanpa offset, badge menimpa ikon karena NavigationDestination
              // membungkusnya dalam pil indikator yang sempit.
              offset: const Offset(6, -6),
              child: const Icon(Icons.history),
            ),
            label: 'Riwayat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Informasi',
          ),
        ],
      ),
    );
  }
}