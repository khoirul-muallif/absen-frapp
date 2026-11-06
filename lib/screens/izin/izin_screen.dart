import 'package:flutter/material.dart';
import '../../services/izin_service.dart';
import '../../models/izin_model.dart';
import 'izin_form_screen.dart';
import '../../widgets/status_badge.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/swipe_hint.dart';
import '../../services/api_client.dart';


class IzinScreen extends StatefulWidget {
  const IzinScreen({super.key});

  @override
  State<IzinScreen> createState() => _IzinScreenState();
}

class _IzinScreenState extends State<IzinScreen> {
  final IzinService _service = IzinService();
  List<IzinItem> _items = [];
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
      final items = await _service.riwayatOrThrow();
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

  // Backend kirim jam Izin mentah dari DB ("08:00:00"), beda dari respons
  // lain yang sudah H:i (lihat todo.md backend). Cukup potong string,
  // jangan parse pakai DateTime.
  String _formatJam(String? raw) {
    if (raw == null) return '-';
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }

  /// Mengembalikan true kalau pembatalan berhasil — dipakai confirmDismiss.
  /// Bukan optimistis: Flutter mensyaratkan widget yang sudah di-dismiss
  /// lenyap dari tree, jadi memunculkannya kembali (lewat _loadData, yang
  /// mengembalikan item dengan Key yang sama) melempar "A dismissed
  /// Dismissible widget is still part of the tree". Sudah terbukti di
  /// device pada layar Tukar Jadwal.
  Future<bool> _batalkan(IzinItem item) async {
    final result = await _service.batalkan(item.id);
    if (!mounted) return false;

    if (result['success'] != true) {
      showAppSnackBar(context, result['message'], type: AppSnackBarType.error);
      return false;
    }

    setState(() => _items.removeWhere((e) => e.id == item.id));
    return true;
  }

  Future<void> _isiJamKembali(IzinItem item) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
  if (picked == null) return;

    final jamKembali =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

    final result = await _service.isiJamKembali(item.id, jamKembali);
    if (!mounted) return;

    if (result['success'] == true) {
      _loadData();
    } else {
      showAppSnackBar(context, result['message'], type: AppSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Izin')),
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
                                'Gagal memuat pengajuan izin',
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
                          Center(child: Text('Belum ada pengajuan izin')),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final bisaDibatalkan = item.jamKembali == null;

                          final card = Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ListTile(
                                  title: Text(item.tanggal),
                                  subtitle: Text(
                                    '${_formatJam(item.jamKeluar)} - ${_formatJam(item.jamKembali)}\n${item.keperluan}'
                                    '${item.catatanApproval != null ? '\nCatatan: ${item.catatanApproval}' : ''}',
                                  ),
                                  isThreeLine: true,
                                  trailing: StatusBadge(status: item.status),
                                  onTap: item.jamKembali == null
                                      ? () => _isiJamKembali(item)
                                      : null,
                                ),
                                if (bisaDibatalkan) const SwipeHint(),
                              ],
                            ),
                          );

                          if (!bisaDibatalkan) return card;

                          return Dismissible(
                            key: Key('izin-${item.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) => _batalkan(item),
                            child: card,
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final submitted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const IzinFormScreen()),
          );
          if (submitted == true) _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}