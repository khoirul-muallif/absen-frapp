// lib/screens/cuti/cuti_screen.dart
import 'package:flutter/material.dart';
import '../../services/cuti_service.dart';
import '../../models/cuti_model.dart';
import 'cuti_form_screen.dart';
import '../../widgets/status_badge.dart';
import '../../utils/snackbar_helper.dart';

class CutiScreen extends StatefulWidget {
  const CutiScreen({super.key});

  @override
  State<CutiScreen> createState() => _CutiScreenState();
}

class _CutiScreenState extends State<CutiScreen> {
  final CutiService _service = CutiService();
  List<CutiItem> _items = [];
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


  Future<void> _batalkan(CutiItem item) async {
    final removedIndex = _items.indexWhere((e) => e.id == item.id);
    if (removedIndex == -1) return;

    setState(() => _items.removeAt(removedIndex));

    final result = await _service.batalkan(item.id);
    if (result['success'] != true) {
      if (mounted) {
        showAppSnackBar(context, result['message'], type: AppSnackBarType.error);
      }
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuti')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('Belum ada pengajuan cuti')),
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
                          title: Text('${item.jenisCuti} (${item.jumlahHari} hari)'),
                          subtitle: Text(
                            '${item.tanggalMulai} s/d ${item.tanggalSelesai}\n${item.alasan}'
                            '${item.catatanApproval != null ? '\nCatatan: ${item.catatanApproval}' : ''}',
                          ),
                          isThreeLine: true,
                          trailing: StatusBadge(status: item.status),
                        ),
                      );

                      if (!bisaDibatalkan) return card;

                      return Dismissible(
                        key: Key('cuti-${item.id}'),
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
            MaterialPageRoute(builder: (_) => const CutiFormScreen()),
          );
          if (submitted == true) _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}