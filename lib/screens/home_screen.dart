import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'absen/absen_flow_screen.dart';
import '../services/absensi_service.dart';
import 'absen/absen_pulang_flow_screen.dart';
import 'riwayat_screen.dart';
import 'notifikasi_screen.dart';
import 'izin/izin_screen.dart'; 
import 'lembur/lembur_screen.dart';
import 'dinas/dinas_screen.dart';
import 'cuti/cuti_screen.dart';
import 'tukar_jadwal/tukar_jadwal_screen.dart';
import '../services/tukar_jadwal_service.dart';
import '../utils/snackbar_helper.dart';
// tambahan import di atas
import 'package:geolocator/geolocator.dart';
import '../utils/lokasi_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tukarJadwalService = TukarJadwalService();
  int _menungguTukarJadwalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMenungguTukarJadwalCount();
  }

  Future<void> _loadMenungguTukarJadwalCount() async {
    final items = await _tukarJadwalService.menungguResponSaya();
    if (!mounted) return;
    setState(() => _menungguTukarJadwalCount = items.length);
  }
  
  Future<Position?> _ambilLokasiDenganLoading() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final hasil = await LokasiHelper.ambilLokasi();

    if (!mounted) return null;
    Navigator.of(context, rootNavigator: true).pop(); // tutup loading dialog

    if (!hasil.berhasil) {
      showAppSnackBar(context, hasil.error ?? 'Gagal mendapatkan lokasi',
          type: AppSnackBarType.error);
      return null;
    }

    return hasil.position;
  }

  Future<void> _handleAbsenMasuk() async {
    final status = await AbsensiService().getStatus();
    if (!mounted) return;

    if (status == null) {
      showAppSnackBar(context, 'Gagal memuat status absen', type: AppSnackBarType.error);
      return;
    }

    if (status.sudahMasuk && status.sudahPulang) {
      showAppSnackBar(context, 'Anda sudah absen masuk & pulang hari ini');
      return;
    }

    final posisi = await _ambilLokasiDenganLoading();
    if (posisi == null) return;

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AbsenFlowScreen(initialPosition: posisi)),
    );
  }

  Future<void> _handleAbsenPulang() async {
    final status = await AbsensiService().getStatus();
    if (!mounted) return;

    if (status == null) {
      showAppSnackBar(context, 'Gagal memuat status absen', type: AppSnackBarType.error);
      return;
    }

    if (!status.sudahMasuk) {
      showAppSnackBar(context, 'Anda belum absen masuk, tidak bisa absen pulang', type: AppSnackBarType.error);
      return;
    }

    if (status.sudahPulang) {
      showAppSnackBar(context, 'Anda sudah absen pulang');
      return;
    }

    final posisi = await _ambilLokasiDenganLoading();
    if (posisi == null) return;

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AbsenPulangFlowScreen(initialPosition: posisi)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kartu profil ringkas
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
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
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(user?.jabatan ?? '-'),
                            Text(
                              user?.instansiNama ?? '-',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Menu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Grid menu fitur
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _MenuItem(
                      icon: Icons.login,
                      label: 'Absen Masuk',
                      onTap: () => _handleAbsenMasuk(),
                    ),
                    _MenuItem(
                      icon: Icons.logout,
                      label: 'Absen Pulang',
                      onTap: () => _handleAbsenPulang(),
                    ),
                    _MenuItem(
                      icon: Icons.calendar_today,
                      label: 'Riwayat',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RiwayatScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.notifications,
                      label: 'Notifikasi',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotifikasiScreen()),
                        );
                      },  
                    ),
                    _MenuItem(
                      icon: Icons.event_busy,
                      label: 'Izin',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const IzinScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.more_time,
                      label: 'Lembur',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LemburScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.work_outline,
                      label: 'Dinas',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DinasScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.beach_access,
                      label: 'Cuti',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CutiScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.swap_horiz,
                      label: 'Tukar Jadwal',
                      badgeCount: _menungguTukarJadwalCount,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TukarJadwalScreen()),
                        );
                        _loadMenungguTukarJadwalCount();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              label: Text('$badgeCount'),
              isLabelVisible: badgeCount > 0,
              child: Icon(icon, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}