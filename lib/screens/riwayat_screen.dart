import 'package:flutter/material.dart';
import '../services/absensi_service.dart';
import '../models/riwayat_absen_model.dart';

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
  RekapAbsen? _rekap;
  List<RiwayatAbsenItem> _riwayat = [];

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

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final rekap = await _service.getRekap(bulan: _bulan, tahun: _tahun);
    final riwayat = await _service.getRiwayat(bulan: _bulan, tahun: _tahun);

    if (!mounted) return;
    setState(() {
      _rekap = rekap;
      _riwayat = riwayat;
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

  Color _statusColor(String status) {
    switch (status) {
      case 'tepat_waktu':
        return Colors.green;
      case 'terlambat':
        return Colors.orange;
      case 'alpha':
        return Colors.red;
      case 'izin':
      case 'sakit':
      case 'cuti':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Absensi')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Navigasi bulan
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

                  // Kartu rekap ringkas
                  if (_rekap != null) _RekapCard(rekap: _rekap!),

                  const SizedBox(height: 20),
                  const Text(
                    'Detail Harian',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (_riwayat.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('Belum ada data absensi bulan ini')),
                    )
                  else
                    ..._riwayat.map((item) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _statusColor(item.status).withOpacity(0.15),
                              child: Icon(Icons.circle,
                                  size: 12, color: _statusColor(item.status)),
                            ),
                            title: Text('${item.tanggal} • ${item.hari}'),
                            subtitle: Text(
                              '${item.shift} • Masuk: ${item.waktuMasuk} • Pulang: ${item.waktuPulang}'
                              '${item.terlambat != null ? '\nTerlambat ${item.terlambat}' : ''}',
                            ),
                            isThreeLine: item.terlambat != null,
                            trailing: Text(
                              item.status.replaceAll('_', ' '),
                              style: TextStyle(
                                fontSize: 12,
                                color: _statusColor(item.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )),
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