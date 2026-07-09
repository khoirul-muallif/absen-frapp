import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../services/absensi_service.dart';

enum AbsenMode { masuk, pulang }

class StepWajah extends StatefulWidget {
  final Position position;
  final String? kodeQr; // null kalau mode pulang
  final AbsenMode mode;

  const StepWajah({
    super.key,
    required this.position,
    this.kodeQr,
    required this.mode,
  });

  @override
  State<StepWajah> createState() => _StepWajahState();
}

class _StepWajahState extends State<StepWajah> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _livenessPassed = false;
  String _statusText = 'Posisikan wajah di dalam frame';
  final AbsensiService _absensiService = AbsensiService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      setState(() {
        _statusText = 'Gagal mengakses kamera depan: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _ambilFotoDanVerifikasi() async {
    if (_cameraController == null || _isProcessing) return;
    setState(() {
      _isProcessing = true;
      _statusText = 'Memproses...';
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        setState(() {
          _statusText = 'Wajah tidak terdeteksi. Coba lagi.';
          _isProcessing = false;
        });
        return;
      }

      final face = faces.first;
      final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
      final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;

      if (leftEyeOpen < 0.3 || rightEyeOpen < 0.3) {
        setState(() {
          _statusText = 'Mata terdeteksi tertutup. Buka mata dan coba lagi.';
          _isProcessing = false;
        });
        return;
      }

      setState(() => _livenessPassed = true);
      await _submitAbsen(File(photo.path));
    } catch (e) {
      setState(() {
        _statusText = 'Terjadi kesalahan: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _submitAbsen(File foto) async {
    setState(() => _statusText = 'Mengirim data absen...');

    final Map<String, dynamic> result;

    if (widget.mode == AbsenMode.masuk) {
      result = await _absensiService.absenMasuk(
        latitude: widget.position.latitude,
        longitude: widget.position.longitude,
        kodeQr: widget.kodeQr!,
        fotoMasuk: foto,
      );
    } else {
      result = await _absensiService.absenPulang(
        latitude: widget.position.latitude,
        longitude: widget.position.longitude,
        fotoPulang: foto,
      );
    }

    if (!mounted) return;

    if (result['success'] == true) {
      final judul = widget.mode == AbsenMode.masuk
          ? 'Absen Masuk Berhasil'
          : 'Absen Pulang Berhasil';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(judul),
          content: Text(result['message'] ?? 'Absen tercatat.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _statusText = result['message'] ?? 'Absen gagal.';
        _isProcessing = false;
        _livenessPassed = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(child: Text(_statusText));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            widget.mode == AbsenMode.masuk
                ? 'Verifikasi Wajah - Absen Masuk'
                : 'Verifikasi Wajah - Absen Pulang',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CameraPreview(_cameraController!),
              ),
              Container(
                width: 220,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _livenessPassed ? Colors.green : Colors.teal,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(140),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _ambilFotoDanVerifikasi,
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Ambil Foto & Absen'),
          ),
        ),
      ],
    );
  }
}