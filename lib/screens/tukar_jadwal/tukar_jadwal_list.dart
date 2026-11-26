// lib/screens/tukar_jadwal/tukar_jadwal_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/tukar_jadwal_service.dart';
import '../../models/tukar_jadwal_model.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/swipe_hint.dart';
import 'menunggu_respon_screen.dart';
import '../../widgets/dialog_konfirmasi.dart';
import '../../widgets/kartu_error.dart';

/// Isi TukarJadwalScreen tanpa Scaffold, supaya bisa dipakai DUA tempat:
/// sebagai tab di RiwayatScreen, dan sebagai layar yang di-push dari
/// notifikasi (aksi selain 'diajukan').
class TukarJadwalList extends StatefulWidget {
  const TukarJadwalList({super.key});

  @override
  State<TukarJadwalList> createState() => TukarJadwalListState();
}

class TukarJadwalListState extends State<TukarJadwalList> {
  final _service = TukarJadwalService();
  List<TukarJadwalItem> _items = [];
  bool _loading = true;
  String? _error;
  int _menungguCount = 0;

  @override
  void initState() {
    super.initState();
    muatUlang();
  }

  /// Publik supaya pemanggil (mis. setelah kembali dari form) bisa menyegarkan.
  Future<void> muatUlang({bool tampilkanSpinner = true}) => _loadData(
        tampilkanSpinner: tampilkanSpinner,
      );

  Future<void> _loadData({bool tampilkanSpinner = true}) async {
    if (tampilkanSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final hasil = await Future.wait([
        _service.riwayatOrThrow(),
        _service.menungguResponSayaOrThrow(),
      ]);

      if (!mounted) return;
      setState(() {
        _items = hasil[0];
        _menungguCount = hasil[1].length;
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

  Future<bool> _batalkan(TukarJadwalItem item) async {
    final lanjut = await konfirmasi(
      context,
      judul: 'Hapus pengajuan?',
      // Rekan yang sudah dikirimi permintaan tidak diberi tahu
      // pembatalannya lewat layar ini — notifikasinya dari backend.
      pesan: item.mode == 'pindah'
          ? 'Pengajuan pindah jadwal ${item.jadwalAsal.tanggal} akan '
              'dihapus permanen.'
          : 'Pengajuan tukar jadwal dengan '
              '${item.jadwalTujuan?.karyawan ?? 'rekan'} akan dihapus '
              'permanen.',
      labelAksi: 'Hapus Pengajuan',
    );
    if (!lanjut || !mounted) return false;

    final result = await _service.batalkan(item.id);
    if (!mounted) return false;

    if (result['success'] != true) {
      showAppSnackBar(context, result['message'], type: AppSnackBarType.error);
      return false;
    }

    setState(() => _items.removeWhere((e) => e.id == item.id));
    return true;
  }

  Future<void> _bukaMenungguRespon() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MenungguResponScreen()),
    );
    if (!mounted) return;
    _loadData(tampilkanSpinner: false);
  }

  @override
  Widget build(BuildContext context) {
    final idSaya = context.read<AuthProvider>().user?.id;

    return RefreshIndicator(
      onRefresh: () => _loadData(tampilkanSpinner: false),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (_menungguCount > 0) _bannerMenunggu(),
                if (_error != null)
                  _kartuError()
                else if (_items.isEmpty)
                  const KartuKosong(
                    ikon: Icons.swap_horiz,
                    judul: 'Belum ada pengajuan tukar/pindah jadwal',
                    penjelasan:
                        'Ajukan dari layar Jadwal dengan memilih tanggal '
                        'kerja Anda.',
                  )
                else
                  ..._items.map((item) => _kartuPengajuan(item, idSaya)),
              ],
            ),
    );
  }

  /// Pengganti ikon lonceng yang dicabut. Banner yang menyebut angkanya lebih
  /// sulit diabaikan daripada ikon kecil, dan tidak perlu diajarkan artinya.
  ///
  /// INI JALUR KEDUA, dan itu bukan kemewahan: notifikasi bisa dihapus dengan
  /// satu geseran, dan setelah terhapus tidak ada jalan lagi ke tombol
  /// Setuju/Tolak — rekan menunggu jawaban yang tidak akan pernah datang.
  /// Lihat 5 pengajuan macet di `menunggu_rekan` yang tercatat 9 Nov 2026.
  Widget _bannerMenunggu() {
    final skema = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: skema.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _bukaMenungguRespon,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.pending_actions, color: skema.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_menungguCount pengajuan menunggu jawaban Anda',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: skema.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ketuk untuk menyetujui atau menolak',
                      style: TextStyle(
                        fontSize: 12,
                        color: skema.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: skema.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kartuError() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: KartuError(
        pesan: _error!,
        judul: 'Gagal memuat pengajuan',
        onCobaLagi: _loadData,
      ),
    );
  }

  Widget _kartuPengajuan(TukarJadwalItem item, int? idSaya) {
    // Dibandingkan lewat ID, bukan nama. Versi lama memakai nama karena
    // dikira response riwayat() tidak mengirim id — padahal
    // formatTukarJadwal() sudah mengirim karyawan_id sejak lama, dan
    // komentar lamanya tidak pernah dikoreksi. Dengan nama, dua karyawan
    // bernama sama persis bisa saling membatalkan pengajuan.
    final sayaPengaju = idSaya != null &&
        item.jadwalAsal.karyawanId == idSaya;
    final bisaDibatalkan = sayaPengaju &&
        (item.status == 'menunggu_rekan' || item.status == 'menunggu_admin');

    final subtitle = item.mode == 'pindah'
        ? '${item.jadwalAsal.tanggal} → ${item.tanggalBaru ?? '-'}'
        : '${item.jadwalAsal.karyawan} (${item.jadwalAsal.tanggal}) ⇄ '
            '${item.jadwalTujuan?.karyawan ?? '-'} (${item.jadwalTujuan?.tanggal ?? '-'})';

    final card = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
                item.mode == 'pindah' ? 'Pindah Jadwal' : 'Tukar Jadwal'),
            subtitle: Text(
              '$subtitle\n${item.alasan}'
              '${item.catatanPenolakanRekan != null ? '\nDitolak rekan: ${item.catatanPenolakanRekan}' : ''}'
              '${item.catatanApproval != null ? '\nCatatan admin: ${item.catatanApproval}' : ''}',
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
      key: Key('tukar-${item.id}'),
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
}