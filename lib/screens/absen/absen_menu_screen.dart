import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/absensi_model.dart';
import '../../services/absensi_service.dart';
import '../../utils/lokasi_helper.dart';
import '../../utils/snackbar_helper.dart';
import 'absen_flow_screen.dart';
import 'absen_pulang_flow_screen.dart';

class AbsenMenuScreen extends StatefulWidget {
  const AbsenMenuScreen({super.key});

  @override
  State<AbsenMenuScreen> createState() => _AbsenMenuScreenState();
}

class _AbsenMenuScreenState extends State<AbsenMenuScreen> {
  AbsensiStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    final status = await AbsensiService().getStatus();
    if (!mounted) return;
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  Future<Position?> _ambilLokasiDenganLoading() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final hasil = await LokasiHelper.ambilLokasi();

    if (!mounted) return null;
    Navigator.of(context, rootNavigator: true).pop();

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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _status == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Gagal memuat status absen'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadStatus,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
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
                          enabled: _status!.sudahMasuk && !_status!.sudahPulang,
                          keterangan: _status!.sudahPulang
                              ? 'Sudah absen pulang'
                                  '${_status!.waktuPulang != null ? ' pukul ${_status!.waktuPulang}' : ''}'
                              : (!_status!.sudahMasuk ? 'Belum absen masuk' : null),
                          onTap: _handleAbsenPulang,
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