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
  Position? _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _currentStep = widget.initialPosition != null ? 1 : 0;
  }

  void _onLokasiSukses(Position position) {
    setState(() {
      _position = position;
      _currentStep = 1;
    });
  }

  Future<void> _kembaliKeBerandaPeringatan() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mulai Ulang dari Beranda'),
        content: const Text(
          'Anda akan kembali ke Beranda. Tunggu sekitar 5-10 detik sebelum '
          'menekan tombol Absen lagi, supaya kamera siap dipakai ulang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absen Pulang')),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentStep),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                StepLokasi(onSukses: _onLokasiSukses),
                if (_position != null)
                  StepWajah(
                    position: _position!,
                    mode: AbsenMode.pulang,
                    onGagal: _kembaliKeBerandaPeringatan,
                  )
                else
                  const SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final labels = ['Lokasi', 'Wajah'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(labels.length, (i) {
          final isActive = i <= currentStep;
          return Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
                child: i < currentStep
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text('${i + 1}',
                        style: TextStyle(
                            color: isActive ? Colors.white : Colors.black54)),
              ),
              if (i < labels.length - 1)
                Container(width: 40, height: 2, color: Colors.grey[300]),
            ],
          );
        }),
      ),
    );
  }
}