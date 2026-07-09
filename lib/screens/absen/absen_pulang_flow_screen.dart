import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'step_lokasi.dart';
import 'step_wajah.dart';

class AbsenPulangFlowScreen extends StatefulWidget {
  const AbsenPulangFlowScreen({super.key});

  @override
  State<AbsenPulangFlowScreen> createState() => _AbsenPulangFlowScreenState();
}

class _AbsenPulangFlowScreenState extends State<AbsenPulangFlowScreen> {
  int _currentStep = 0;
  Position? _position;

  void _onLokasiSukses(Position position) {
    setState(() {
      _position = position;
      _currentStep = 1;
    });
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