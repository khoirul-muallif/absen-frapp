import 'package:flutter/material.dart';
import '../services/tukar_jadwal_service.dart';
import 'home_screen.dart';
import 'riwayat_screen.dart';
import 'informasi_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _tukarJadwalService = TukarJadwalService();
  int _index = 0;

  /// Badge di tab Riwayat. Satu-satunya hal yang memberi tahu karyawan
  /// ada rekan menunggu jawabannya TANPA dia mencari — notifikasi hilang
  /// setelah diklik, dan banner di dalam tab baru terlihat kalau tabnya
  /// sudah dibuka. Tanpa ini, pengajuan macet di menunggu_rekan karena
  /// yang dituju tidak pernah tahu (5 kasus tercatat 9 Nov 2026).
  int _menungguTukarJadwal = 0;

  // const dibuang: _tabs lama `static const` berarti ketiga layar dibangun
  // sekali dan tidak pernah diganti, yang bikin hot reload tidak terlihat.
  final _tabs = const [
    HomeScreen(),
    RiwayatScreen(),
    InformasiScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _muatJumlahMenunggu();
  }

  Future<void> _muatJumlahMenunggu() async {
    final items = await _tukarJadwalService.menungguResponSaya();
    if (!mounted) return;
    setState(() => _menungguTukarJadwal = items.length);
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