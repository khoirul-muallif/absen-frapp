// lib/screens/absen/step_lokasi.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/lokasi_helper.dart';

class StepLokasi extends StatefulWidget {
  final void Function(Position position) onSukses;
  const StepLokasi({super.key, required this.onSukses});

  @override
  State<StepLokasi> createState() => _StepLokasiState();
}

class _StepLokasiState extends State<StepLokasi> {
  bool _loading = false;
  String? _error;

  Future<void> _cekLokasi() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final hasil = await LokasiHelper.ambilLokasi();

    if (!mounted) return;

    if (!hasil.berhasil) {
      setState(() {
        _error = hasil.error;
        _loading = false;
      });
      return;
    }

    setState(() => _loading = false);
    widget.onSukses(hasil.position!);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text(
              'Verifikasi Lokasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pastikan Anda berada di area instansi',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _loading ? null : _cekLokasi,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Cek Lokasi Saya'),
            ),
          ],
        ),
      ),
    );
  }
}