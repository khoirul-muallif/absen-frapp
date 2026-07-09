import 'package:flutter/material.dart';
import '../services/notifikasi_service.dart';
import '../models/notifikasi_model.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  final NotifikasiService _service = NotifikasiService();
  List<NotifikasiItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final result = await _service.getNotifikasi();
    if (!mounted) return;
    setState(() {
      _items = result['items'];
      _loading = false;
    });
  }

  Future<void> _tandaiBaca(NotifikasiItem item) async {
    if (item.sudahBaca) return;
    await _service.tandaiBaca(item.id);
    _loadData();
  }

  Future<void> _hapus(NotifikasiItem item) async {
    await _service.hapus(item.id);
    _loadData();
  }

  IconData _iconForTipe(String tipe) {
    switch (tipe) {
      case 'peringatan':
        return Icons.warning_amber_rounded;
      case 'sukses':
        return Icons.check_circle_outline;
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () async {
              await _service.tandaiBacaSemua();
              _loadData();
            },
            child: const Text('Tandai semua dibaca'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('Belum ada notifikasi')),
                    ],
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _hapus(item),
                        child: ListTile(
                          leading: Icon(
                            _iconForTipe(item.tipe),
                            color: item.sudahBaca ? Colors.grey : Colors.teal,
                          ),
                          title: Text(
                            item.judul,
                            style: TextStyle(
                              fontWeight: item.sudahBaca
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text('${item.pesan}\n${item.dibuatAt}'),
                          isThreeLine: true,
                          trailing: item.sudahBaca
                              ? null
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.teal,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                          onTap: () => _tandaiBaca(item),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}