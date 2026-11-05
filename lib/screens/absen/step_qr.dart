import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class StepQr extends StatefulWidget {
  final void Function(String kodeQr) onSukses;
  const StepQr({super.key, required this.onSukses});

  @override
  State<StepQr> createState() => _StepQrState();
}

class _StepQrState extends State<StepQr> {
  // autoStart dimatikan: start dikendalikan manual supaya kasus
  // controllerAlreadyInitialized (instance sebelumnya belum selesai
  // dilepas di sisi native) bisa ditangani dengan retry, bukan langsung
  // jatuh ke errorBuilder.
  final MobileScannerController _controller =
      MobileScannerController(autoStart: false);

  bool _isProcessing = false;
  bool _starting = true;
  String? _startError;

  static const _maxPercobaan = 5;
  static const _jedaPercobaan = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _mulaiScanner();
  }

  Future<void> _mulaiScanner() async {
    if (!mounted) return;
    setState(() {
      _starting = true;
      _startError = null;
    });

    for (var percobaan = 1; percobaan <= _maxPercobaan; percobaan++) {
      try {
        await _controller.start();
        if (!mounted) return;
        setState(() => _starting = false);
        return;
      } on MobileScannerException catch (e) {
        final masihDipakai =
            e.errorCode == MobileScannerErrorCode.controllerAlreadyInitialized;
        if (!masihDipakai) {
          if (!mounted) return;
          setState(() {
            _starting = false;
            _startError = e.errorDetails?.message ?? e.errorCode.name;
          });
          return;
        }
        try {
          await _controller.stop();
        } catch (_) {
          // sudah berhenti / belum pernah start -- aman diabaikan
        }
        await Future.delayed(_jedaPercobaan);
        if (!mounted) return;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _starting = false;
          _startError = e.toString();
        });
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _starting = false;
      _startError =
          'Kamera masih dipakai proses sebelumnya. Tunggu sebentar lalu coba lagi.';
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final kode = barcodes.first.rawValue;
      if (kode != null && kode.isNotEmpty) {
        setState(() => _isProcessing = true);
        await _controller.stop();
        if (!mounted) return;
        widget.onSukses(kode);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildPesan(String pesan, {required bool bisaCobaLagi}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_outlined, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(pesan, textAlign: TextAlign.center),
            if (bisaCobaLagi) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _mulaiScanner,
                child: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIsi() {
    if (_starting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_startError != null) {
      return _buildPesan(_startError!, bisaCobaLagi: true);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) => _buildPesan(
            'Kamera error: ${error.errorDetails?.message ?? error.errorCode.name}',
            bisaCobaLagi: true,
          ),
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
    );
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
        Expanded(child: _buildIsi()),
      ],
    );
  }
}