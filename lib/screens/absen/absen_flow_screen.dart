import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'step_lokasi.dart';
import 'step_qr.dart';
import 'step_wajah.dart';

class AbsenFlowScreen extends StatefulWidget {
  const AbsenFlowScreen({super.key});

  @override
  State<AbsenFlowScreen> createState() => _AbsenFlowScreenState();
}

class _AbsenFlowScreenState extends State<AbsenFlowScreen> {
  int _currentStep = 0;

  // Data yang dikumpulkan sepanjang flow
  Position? _position;
  String? _kodeQr;

  void _onLokasiSukses(Position position) {
    setState(() {
      _position = position;
      _currentStep = 1;
    });
  }

  void _onQrSukses(String kodeQr) {
    setState(() {
      _kodeQr = kodeQr;
      _currentStep = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absen')),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentStep),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                StepLokasi(onSukses: _onLokasiSukses),
                StepQr(onSukses: _onQrSukses),
                if (_position != null && _kodeQr != null)
                  StepWajah(position: _position!, kodeQr: _kodeQr!)
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
    final labels = ['Lokasi', 'Scan QR', 'Wajah'];
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