// lib/screens/absen/absen_pulang_flow_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'step_lokasi.dart';
import 'step_wajah.dart';

class AbsenPulangFlowScreen extends StatefulWidget {
  final Position? initialPosition;

  const AbsenPulangFlowScreen({super.key, this.initialPosition});

  @override
  State<AbsenPulangFlowScreen> createState() => _AbsenPulangFlowScreenState();
}

class _AbsenPulangFlowScreenState extends State<AbsenPulangFlowScreen> {
  late int _currentStep;
  late final int _stepAwal;
  Position? _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _currentStep = widget.initialPosition != null ? 1 : 0;
    _stepAwal = _currentStep;
  }

  void _onLokasiSukses(Position position) {
    setState(() {
      _position = position;
      _currentStep = 1;
    });
  }

  /// Keluar dari flow kembali ke menu Absen. Alasan kegagalannya sudah
  /// disampaikan lewat snackbar di StepWajah, jadi tidak perlu dialog lagi.
  void _kembaliKeMenu() {
    if (mounted) Navigator.of(context).pop();
  }


  /// Hanya step aktif yang di-mount, sejalan dengan AbsenFlowScreen --
  /// IndexedStack sebelumnya mem-build StepWajah sejak step Lokasi,
  /// sehingga kamera depan menyala sebelum layarnya terlihat.
  Widget _buildStepAktif() {
    switch (_currentStep) {
      case 0:
        return StepLokasi(onSukses: _onLokasiSukses);
      case 1:
        if (_position == null) return const SizedBox();
        return StepWajah(
          position: _position!,
          mode: AbsenMode.pulang,
          onGagal: _kembaliKeMenu,
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep <= _stepAwal,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _konfirmasiKeluar();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Absen Pulang')),
        body: Column(
          children: [
            _StepIndicator(currentStep: _currentStep),
            Expanded(
              child: _buildStepAktif(),
            ),
          ],
        ),
      ),
    );
  }
    /// Konfirmasi hanya kalau user sudah maju dari step awal -- di step
  /// pertama belum ada progres yang hilang, jadi back langsung jalan.
  Future<void> _konfirmasiKeluar() async {
    final keluar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Absen?'),
        content: const Text(
          'Progres yang sudah dilakukan akan hilang dan Anda perlu '
          'mengulang dari awal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Lanjutkan Absen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Batalkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (keluar == true && mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  static const _labels = ['Lokasi', 'Wajah'];

  @override
  Widget build(BuildContext context) {
    final warnaAktif = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        // Slot genap = lingkaran step, slot ganjil = garis penghubung.
        children: List.generate(_labels.length * 2 - 1, (slot) {
          final i = slot ~/ 2;

          if (slot.isOdd) {
            return Container(
              width: 32,
              height: 2,
              // Disejajarkan dengan tengah lingkaran (radius 16), bukan
              // dengan Column yang sekarang lebih tinggi karena ada label.
              margin: const EdgeInsets.only(top: 15),
              color: i < currentStep ? warnaAktif : Colors.grey[300],
            );
          }

          final isActive = i <= currentStep;
          return Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isActive ? warnaAktif : Colors.grey[300],
                child: i < currentStep
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.black54,
                        ),
                      ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 64,
                child: Text(
                  _labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? null : Colors.grey[600],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}