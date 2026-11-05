import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'absen/absen_menu_screen.dart';
import 'riwayat_screen.dart';
import 'notifikasi_screen.dart';
import 'izin/izin_screen.dart';
import 'lembur/lembur_screen.dart';
import 'dinas/dinas_screen.dart';
import 'cuti/cuti_screen.dart';
import 'tukar_jadwal/tukar_jadwal_screen.dart';
import '../services/tukar_jadwal_service.dart';
import 'jadwal/jadwal_screen.dart';
import '../services/absensi_service.dart';
import '../models/riwayat_absen_model.dart';
import '../utils/snackbar_helper.dart';
import '../services/notifikasi_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tukarJadwalService = TukarJadwalService();
  final _absensiService = AbsensiService();
  final _notifikasiService = NotifikasiService();
  int _menungguTukarJadwalCount = 0;
  int _notifBelumBaca = 0;

  RekapAbsen? _rekap;
  bool _loadingRekap = true;

  @override
  void initState() {
    super.initState();
    _loadMenungguTukarJadwalCount();
    _loadRekap();
    _loadNotifCount();
  }


  Future<void> _loadNotifCount() async {
    final count = await _notifikasiService.getJumlahBelumBaca();
    if (!mounted) return;
    setState(() => _notifBelumBaca = count);
  }

  Future<void> _loadMenungguTukarJadwalCount() async {
    final items = await _tukarJadwalService.menungguResponSaya();
    if (!mounted) return;
    setState(() => _menungguTukarJadwalCount = items.length);
  }

  Future<void> _loadRekap() async {
    final now = DateTime.now();
    final rekap = await _absensiService.getRekap(bulan: now.month, tahun: now.year);
    if (!mounted) return;
    setState(() {
      _rekap = rekap;
      _loadingRekap = false;
    });
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
                case 'ubah_password':
                  showAppSnackBar(
                    context,
                    'Fitur ini akan segera hadir',
                    type: AppSnackBarType.info,
                  );
                  break;
                case 'logout':
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
                      if (!_loadingRekap && _rekap != null) ...[
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '${_rekap!.persentaseTepatWaktu}%',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const Text('Tepat Waktu', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text('${_rekap!.totalHadir}',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                  const Text('Total Hadir', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '${_rekap!.terlambat}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: _rekap!.terlambat > 0 ? Colors.orange[800] : null,
                                    ),
                                  ),
                                  const Text('Terlambat', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '${_rekap!.alpha}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: _rekap!.alpha > 0 ? Colors.red[700] : null,
                                    ),
                                  ),
                                  const Text('Alpha', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _rekap!.bulan,
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ),
                      ],
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
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AbsenMenuScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.calendar_month,
                      label: 'Jadwal',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const JadwalScreen()),
                        );
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