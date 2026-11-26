import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/absensi_model.dart';
import '../../services/absensi_service.dart';
import '../../utils/lokasi_helper.dart';
import '../../utils/snackbar_helper.dart';
import 'absen_flow_screen.dart';
import 'absen_pulang_flow_screen.dart';
import '../../services/api_client.dart';
import '../../widgets/kartu_error.dart';

class AbsenMenuScreen extends StatefulWidget {
  const AbsenMenuScreen({super.key});

  @override
  State<AbsenMenuScreen> createState() => _AbsenMenuScreenState();
}

class _AbsenMenuScreenState extends State<AbsenMenuScreen> {
  AbsensiStatus? _status;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final status = await AbsensiService().getStatusOrThrow();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan saat memuat status absen.';
        _loading = false;
      });
    }
  }

  Future<Position?> _ambilLokasiDenganLoading() async {
    final navigator = Navigator.of(context, rootNavigator: true);
    var dialogTampil = true;  

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Flexible(child: Text('Mencari lokasi Anda...')),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((_) => dialogTampil = false);

    final hasil = await LokasiHelper.ambilLokasi();
    if (dialogTampil) {
      dialogTampil = false;
      navigator.pop();
    }

    if (!mounted) return null;

    if (!hasil.berhasil) {
      showAppSnackBar(context, hasil.error ?? 'Gagal mendapatkan lokasi',
          type: AppSnackBarType.error);
      return null;
    }

    return hasil.position;
  }

  Future<void> _handleAbsenMasuk() async {
    final posisi = await _ambilLokasiDenganLoading();
    if (posisi == null) return;

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AbsenFlowScreen(initialPosition: posisi)),
    );
    _loadStatus();
  }

  Future<void> _handleAbsenPulang() async {
    final posisi = await _ambilLokasiDenganLoading();
    if (posisi == null) return;

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AbsenPulangFlowScreen(initialPosition: posisi)),
    );
    _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absen')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStatus,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      children: [
                        KartuError(
                          pesan: _error!,
                          judul: 'Gagal memuat status absen',
                          onCobaLagi: _loadStatus,
                        ),
                      ],
                    )
                  : _status == null
                      // Berbeda dari gagal: request berhasil tapi tidak
                      // ada status untuk hari ini. Tidak ada yang bisa
                      // dicoba lagi, jadi tanpa tombol.
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            KartuKosong(
                              ikon: Icons.event_available_outlined,
                              judul: 'Tidak ada jadwal absen hari ini',
                              penjelasan:
                                  'Hubungi admin kalau menurut Anda '
                                  'seharusnya ada jadwal.',
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          children: [
                            _AbsenButton(
                              icon: Icons.login,
                              label: 'Absen Masuk',
                              enabled: !_status!.sudahMasuk,
                              keterangan: _status!.sudahMasuk
                                  ? 'Sudah absen masuk'
                                      '${_status!.waktuMasuk != null ? ' pukul ${_status!.waktuMasuk}' : ''}'
                                  : null,
                              onTap: _handleAbsenMasuk,
                            ),
                            const SizedBox(height: 16),
                            _AbsenButton(
                              icon: Icons.logout,
                              label: 'Absen Pulang',
                              enabled:
                                  _status!.sudahMasuk && !_status!.sudahPulang,
                              keterangan: _status!.sudahPulang
                                  ? 'Sudah absen pulang'
                                      '${_status!.waktuPulang != null ? ' pukul ${_status!.waktuPulang}' : ''}'
                                  : (!_status!.sudahMasuk
                                      ? 'Belum absen masuk'
                                      : null),
                              onTap: _handleAbsenPulang,
                            ),
                                                        // Kedua tombol mati dan tidak ada yang bisa
                            // dilakukan lagi hari ini. Tanpa ini layarnya
                            // cuma dua kotak abu-abu, dan karyawan harus
                            // menebak sendiri bahwa memang sudah selesai.
                            if (_status!.sudahMasuk && _status!.sudahPulang)
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: Column(
                                  children: [
                                    Icon(Icons.task_alt,
                                        size: 40,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Absen hari ini sudah lengkap',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sampai jumpa besok. Riwayat kehadiran '
                                      'Anda bisa dilihat di tab Riwayat.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
        ),
      ),
    );
  }
}

class _AbsenButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final String? keterangan;
  final VoidCallback onTap;

  const _AbsenButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.keterangan,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: enabled
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, size: 36, color: enabled ? null : Colors.grey),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: enabled ? null : Colors.grey[600],
                        ),
                      ),
                      if (keterangan != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          keterangan!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}