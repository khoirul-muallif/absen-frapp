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
                      icon: Icons.fingerprint,
                      label: 'Absen',
                      onTap: () async {
                        final status = await AbsensiService().getStatus();

                        if (!context.mounted) return;

                        if (status == null) {
                          showAppSnackBar(context, 'Gagal memuat status absen');
                          return;
                        }

                        if (!status.sudahMasuk) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AbsenFlowScreen()),
                          );
                        } else if (!status.sudahPulang) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AbsenPulangFlowScreen()),
                          );
                        } else {
                          showAppSnackBar(context, 'Anda sudah absen masuk & pulang hari ini');
                        }
                      },
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