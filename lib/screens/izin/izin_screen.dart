import 'package:flutter/material.dart';
import '../../services/izin_service.dart';
import '../../models/izin_model.dart';
import 'izin_form_screen.dart';
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

  /// id izin yang sedang dikirim ke server. Tombol "Saya sudah kembali"
  /// dikunci selama itu — tombol yang bisa ditekan dua kali menghasilkan
  /// penolakan 422 yang terlihat seperti kegagalan padahal yang pertama
  /// berhasil (pelajaran d7db39e).
  int? _menandaiId;

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

  /// Tidak ada picker. Jamnya dari server (fase 88) — satu-satunya cara
  /// mencatat jam kembali adalah benar-benar menekan tombol saat kembali.
  Future<void> _tandaiSudahKembali(IzinItem item) async {
    setState(() => _menandaiId = item.id);

    final result = await _service.tandaiSudahKembali(item.id);
    if (!mounted) return;
    setState(() => _menandaiId = null);

    if (result['success'] == true) {
      showAppSnackBar(context, result['message'], type: AppSnackBarType.success);
      _loadData(tampilkanSpinner: false);
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
                ? _kartuError()
                : _items.isEmpty
                    ? _kosong()
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => _kartu(_items[i]),
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

  Widget _kartu(IzinItem item) {
    final skema = Theme.of(context).colorScheme;
    final berjalan = item.masihBerjalan;
    final sedangKirim = _menandaiId == item.id;

    final card = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.tanggal,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Penanda keadaan, BUKAN status approval. Izin auto-approve
                // sejak keputusan RS 8 Okt, jadi badge "Disetujui" hampir
                // selalu sama dan tidak memberi tahu apa pun. Yang benar-
                // benar menentukan apa yang bisa dilakukan adalah sudah
                // kembali atau belum.
                _penanda(
                  berjalan ? 'Sedang izin' : 'Sudah kembali',
                  berjalan ? skema.primary : Colors.grey.shade600,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _baris(Icons.logout, 'Keluar', _formatJam(item.jamKeluar)),
            _baris(
              Icons.schedule,
              'Rencana kembali',
              _formatJam(item.jamKembaliRencana),
            ),
            if (!berjalan)
              _baris(
                Icons.login,
                'Kembali',
                _formatJam(item.jamKembaliAktual),
              ),
            const SizedBox(height: 8),
            Text(item.keperluan, style: const TextStyle(fontSize: 13)),
            if (item.catatanApproval != null) ...[
              const SizedBox(height: 4),
              Text(
                'Catatan: ${item.catatanApproval}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
            if (berjalan) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      sedangKirim ? null : () => _tandaiSudahKembali(item),
                  icon: sedangKirim
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login, size: 18),
                  label: Text(
                    sedangKirim ? 'Mencatat...' : 'Saya sudah kembali',
                  ),
                ),
              ),
              const SwipeHint(),
            ],
          ],
        ),
      ),
    );

    // Dasar pembatalan sama dengan backend: belum tercatat kembali.
    if (!berjalan) return card;

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
  }

  Widget _baris(IconData ikon, String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(ikon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          const Spacer(),
          Text(
            nilai,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _penanda(String teks, Color warna) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: warna),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        teks,
        style: TextStyle(
            color: warna, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }

  Widget _kosong() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 100),
        Center(child: Text('Belum ada pengajuan izin')),
      ],
    );
  }

  Widget _kartuError() {
    return ListView(
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
    );
  }
}