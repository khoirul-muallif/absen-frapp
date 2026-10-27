// lib/screens/dinas/dinas_screen.dart
import 'package:flutter/material.dart';
import '../../services/dinas_service.dart';
import '../../models/dinas_model.dart';
import 'dinas_form_screen.dart';
import '../../widgets/status_badge.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/swipe_hint.dart';

class DinasScreen extends StatefulWidget {
  const DinasScreen({super.key});

  @override
  State<DinasScreen> createState() => _DinasScreenState();
}

class _DinasScreenState extends State<DinasScreen> {
  final DinasService _service = DinasService();
  List<DinasItem> _items = [];
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



  Future<void> _batalkan(DinasItem item) async {
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
      appBar: AppBar(title: const Text('Dinas')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 100),
                      Center(child: Text('Belum ada pengajuan dinas')),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ListTile(
                              title: Text('${item.tanggalMulai} s/d ${item.tanggalSelesai}'),
                              subtitle: Text(
                                '${item.tujuan}\n${item.keperluan}'
                                '${item.catatanApproval != null ? '\nCatatan: ${item.catatanApproval}' : ''}',
                              ),
                              isThreeLine: true,
                              trailing: StatusBadge(status: item.status),
                            ),
                            if (bisaDibatalkan) const SwipeHint(),
                          ],
                        ),
                      );

                      if (!bisaDibatalkan) return card;

                      return Dismissible(
                        key: Key('dinas-${item.id}'),
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
            MaterialPageRoute(builder: (_) => const DinasFormScreen()),
          );
          if (submitted == true) _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}