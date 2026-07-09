import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class StepQr extends StatefulWidget {
  final void Function(String kodeQr) onSukses;
  const StepQr({super.key, required this.onSukses});

  @override
  State<StepQr> createState() => _StepQrState();
}

class _StepQrState extends State<StepQr> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final kode = barcodes.first.rawValue;
      if (kode != null && kode.isNotEmpty) {
        setState(() => _isProcessing = true);
        _controller.stop();
        widget.onSukses(kode);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Arahkan kamera ke QR code instansi',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}