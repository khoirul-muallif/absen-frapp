import 'package:flutter/material.dart';
import '../services/notifikasi_service.dart';
import '../models/notifikasi_model.dart';
import '../utils/snackbar_helper.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  final NotifikasiService _service = NotifikasiService();
  List<NotifikasiItem> _items = [];
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

    final result = await _service.getNotifikasi();
    if (!mounted) return;

    // getNotifikasi() sudah membungkus ApiException jadi success:false,
    // dan sejak 3d89e53 kegagalan koneksi ikut lewat sana. Sebelumnya
    // flag ini diabaikan dan items-nya yang kosong langsung dipakai,
    // jadi gagal konek tampil sebagai "Belum ada notifikasi".
    if (result['success'] != true) {
      const pesan = 'Tidak bisa memuat notifikasi. Periksa koneksi Anda.';
      if (!tampilkanSpinner && _items.isNotEmpty) {
        showAppSnackBar(context, pesan, type: AppSnackBarType.error);
        return;
      }
      setState(() {
        _error = pesan;
        _loading = false;
      });
      return;
    }

    setState(() {
      _items = (result['items'] as List).cast<NotifikasiItem>();
      _error = null;
      _loading = false;
    });
  }

  Future<void> _tandaiBaca(NotifikasiItem item) async {
    if (item.sudahBaca) return;

    final berhasil = await _service.tandaiBaca(item.id);
    if (!mounted) return;

    if (!berhasil) {
      showAppSnackBar(context, 'Gagal menandai notifikasi sebagai dibaca',
          type: AppSnackBarType.error);
      return;
    }

    // Muat ulang tanpa spinner layar penuh. Mengubah item di tempat tidak
    // bisa: NotifikasiItem.sudahBaca final.
    _loadData(tampilkanSpinner: false);
  }

  Future<void> _tandaiSemuaBaca() async {
    final berhasil = await _service.tandaiBacaSemua();
    if (!mounted) return;

    if (!berhasil) {
      showAppSnackBar(context, 'Gagal menandai semua notifikasi',
          type: AppSnackBarType.error);
      return;
    }

    _loadData(tampilkanSpinner: false);
  }

  Future<bool> _hapus(NotifikasiItem item) async {
    final berhasil = await _service.hapus(item.id);
    if (!mounted) return false;

    if (!berhasil) {
      showAppSnackBar(context, 'Gagal menghapus notifikasi',
          type: AppSnackBarType.error);
      return false;
    }

    setState(() => _items.removeWhere((e) => e.id == item.id));
    return true;
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
            onPressed: _tandaiSemuaBaca,
            child: const Text('Tandai semua dibaca'),
          ),
        ],
      ),
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
                                'Gagal memuat notifikasi',
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
                          Center(child: Text('Belum ada notifikasi')),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
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
                            confirmDismiss: (_) => _hapus(item),
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