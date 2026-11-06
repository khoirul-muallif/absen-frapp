// lib/screens/tukar_jadwal/menunggu_respon_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/tukar_jadwal_service.dart';
import '../../models/tukar_jadwal_model.dart';
import '../../utils/snackbar_helper.dart';

class MenungguResponScreen extends StatefulWidget {
  const MenungguResponScreen({super.key});

  @override
  State<MenungguResponScreen> createState() => _MenungguResponScreenState();
}

class _MenungguResponScreenState extends State<MenungguResponScreen> {
  final _service = TukarJadwalService();
  List<TukarJadwalItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool tampilkanSpinner = true}) async {
    if (tampilkanSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final items = await _service.menungguResponSayaOrThrow();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _respon(TukarJadwalItem item, bool setuju) async {
    String? catatan;
    if (!setuju) {
      catatan = await _tanyaAlasanTolak();
      if (catatan == null) return; // dialog dibatalkan
    }

    final result = await _service.responRekan(item.id, setuju, catatan: catatan);
    if (!mounted) return;

    if (result['success'] == true) {
      showAppSnackBar(context, result['message'], type: AppSnackBarType.success);
      _loadData();
    } else {
      showAppSnackBar(context, result['message'] ?? 'Gagal merespon',
          type: AppSnackBarType.error);
    }
  }

  /// Controller-nya dimiliki State, bukan dibuat di dalam builder dialog —
  /// di sana tidak ada tempat untuk dispose()-nya.
  Future<String?> _tanyaAlasanTolak() async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Alasan menolak (opsional)'),
          content: TextField(controller: controller, maxLines: 2),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Tolak'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menunggu Respon Saya')),
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
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 100),
                          Center(
                              child: Text(
                                  'Tidak ada pengajuan yang menunggu respon Anda')),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.jadwalAsal.karyawan} mengajukan tukar jadwal',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Jadwal dia: ${item.jadwalAsal.tanggal} (${item.jadwalAsal.shift ?? '-'})\n'
                                    'Jadwal Anda: ${item.jadwalTujuan?.tanggal ?? '-'} (${item.jadwalTujuan?.shift ?? '-'})',
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Alasan: ${item.alasan}'),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _respon(item, false),
                                          child: const Text('Tolak'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _respon(item, true),
                                          child: const Text('Setuju'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}