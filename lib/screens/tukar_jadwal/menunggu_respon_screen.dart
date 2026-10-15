// lib/screens/tukar_jadwal/menunggu_respon_screen.dart
import 'package:flutter/material.dart';
import '../../services/tukar_jadwal_service.dart';
import '../../models/tukar_jadwal_model.dart';

class MenungguResponScreen extends StatefulWidget {
  const MenungguResponScreen({super.key});

  @override
  State<MenungguResponScreen> createState() => _MenungguResponScreenState();
}

class _MenungguResponScreenState extends State<MenungguResponScreen> {
  final _service = TukarJadwalService();
  List<TukarJadwalItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final items = await _service.menungguResponSaya();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _respon(TukarJadwalItem item, bool setuju) async {
    String? catatan;
    if (!setuju) {
      catatan = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
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
          );
        },
      );
      if (catatan == null) return; // dialog dibatalkan
    }

    final result = await _service.responRekan(item.id, setuju, catatan: catatan);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal merespon')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menunggu Respon Saya')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('Tidak ada pengajuan yang menunggu respon Anda')),
                    ],
                  )
                : ListView.builder(
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
                                style: const TextStyle(fontWeight: FontWeight.w600),
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