// lib/screens/absen/absen_flow_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'step_lokasi.dart';
import 'step_qr.dart';
import 'step_wajah.dart';

class AbsenFlowScreen extends StatefulWidget {
  /// Kalau diisi (sudah didapat dari Beranda sebelum masuk sini), step
  /// Lokasi dilewati -- flow langsung mulai dari Scan QR.
  final Position? initialPosition;

  const AbsenFlowScreen({super.key, this.initialPosition});

  @override
  State<AbsenFlowScreen> createState() => _AbsenFlowScreenState();
}

class _AbsenFlowScreenState extends State<AbsenFlowScreen> {

  /// Hanya step aktif yang di-mount. Sebelumnya pakai IndexedStack yang
  /// mem-build semua children sekaligus, sehingga StepQr memegang kamera
  /// sejak step Lokasi dan masih mounted saat StepWajah mencoba membuka
  /// kamera depan.
  Widget _buildStepAktif() {
    switch (_currentStep) {
      case 0:
        return StepLokasi(onSukses: _onLokasiSukses);
      case 1:
        return StepQr(onSukses: _onQrSukses);
      case 2:
        if (_position == null || _kodeQr == null) return const SizedBox();
        return StepWajah(
          position: _position!,
          kodeQr: _kodeQr!,
          mode: AbsenMode.masuk,
          onGagal: _kembaliKeMenu,
        );
      default:
        return const SizedBox();
    }
  }
  
  late int _currentStep;

  Position? _position;
  String? _kodeQr;

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

  void _onQrSukses(String kodeQr) {
    setState(() {
      _kodeQr = kodeQr;
      _currentStep = 2;
    });
  }

  /// Keluar dari flow kembali ke menu Absen. Alasan kegagalannya sudah
  /// disampaikan lewat snackbar di StepWajah, jadi tidak perlu dialog lagi.
  void _kembaliKeMenu() {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absen')),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentStep),
          Expanded(
            child: _buildStepAktif(),
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