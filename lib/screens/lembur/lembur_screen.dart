// lib/screens/lembur/lembur_screen.dart
import 'package:flutter/material.dart';
import '../../services/lembur_service.dart';
import '../../models/lembur_model.dart';
import 'lembur_form_screen.dart';
import '../../widgets/status_badge.dart';
import '../../utils/snackbar_helper.dart';


class LemburScreen extends StatefulWidget {
  const LemburScreen({super.key});

  @override
  State<LemburScreen> createState() => _LemburScreenState();
}

class _LemburScreenState extends State<LemburScreen> {
  final LemburService _service = LemburService();
  List<LemburItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final items = await _service.riwayat();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  // Sama seperti jam Izin: jam_mulai/jam_selesai Lembur juga dikirim mentah
  // dari DB ("08:00:00"), bukan H:i — lihat todo.md. Potong string, jangan
  // di-parse pakai DateTime.
  String _formatJam(String? raw) {
    if (raw == null) return '-';
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }


  Future<void> _batalkan(LemburItem item) async {
    final removedIndex = _items.indexWhere((e) => e.id == item.id);
    if (removedIndex == -1) return;

    setState(() => _items.removeAt(removedIndex));

    final result = await _service.batalkan(item.id);
    if (result['success'] != true) {
      if (mounted) {
        showAppSnackBar(context, result['message']);
      }
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lembur')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('Belum ada pengajuan lembur')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final bisaDibatalkan = item.status == 'pending';

                      final card = Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(item.tanggal),
                          subtitle: Text(
                            '${_formatJam(item.jamMulai)} - ${_formatJam(item.jamSelesai)}\n${item.alasan}'
                            '${item.catatanApproval != null ? '\nCatatan: ${item.catatanApproval}' : ''}',
                          ),
                          isThreeLine: true,
                          trailing: StatusBadge(status: item.status),
                        ),
                      );

                      if (!bisaDibatalkan) return card;

                      return Dismissible(
                        key: Key('lembur-${item.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _batalkan(item),
                        child: card,
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final submitted = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const LemburFormScreen()),
          );
          if (submitted == true) _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}