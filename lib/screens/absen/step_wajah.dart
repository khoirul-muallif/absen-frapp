import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../services/absensi_service.dart';
import '../../utils/snackbar_helper.dart';

enum AbsenMode { masuk, pulang }

enum _Gesture { kedip, senyum }

class StepWajah extends StatefulWidget {
  final Position position;
  final String? kodeQr; // null kalau mode pulang
  final AbsenMode mode;
  final VoidCallback onGagal;

  const StepWajah({
    super.key,
    required this.position,
    this.kodeQr,
    required this.mode,
    required this.onGagal,
  });

  @override
  State<StepWajah> createState() => _StepWajahState();
}

class _StepWajahState extends State<StepWajah> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      // fast: cukup buat landmark probabilitas tiap frame stream -- foto
      // final tetap diambil lewat takePicture() kualitas penuh, bukan
      // di-crop dari frame stream ini.
      performanceMode: FaceDetectorMode.fast,
    ),
  );
  final AbsensiService _absensiService = AbsensiService();

  bool _isInitializing = true;
  bool _isStreaming = false;
  bool _isBusyFrame = false; // skip frame kalau masih proses yang sebelumnya
  bool _isSubmitting = false;
  bool _gesturePassed = false;
  bool _selesai = false; // guard biar onGagal/submit gak kepanggil dobel

  late final _Gesture _target;
  String _statusText = '';

  // Kedip butuh urutan terbuka -> tertutup -> terbuka lagi, bukan cuma satu
  // frame mata tertutup -- biar foto statis/freeze gak lolos kebetulan.
  bool _pernahTertutup = false;
  int _frameSenyumBerturut = 0;
  static const _ambangSenyum = 0.70;
  static const _ambangMataTerbuka = 0.55;
  static const _ambangMataTertutup = 0.30;
  static const _frameSenyumDibutuhkan = 4; // ~0.5-0.6 detik di throttle 150ms

  DateTime? _terakhirWajahTerdeteksi;
  Timer? _timeoutTimer;
  DateTime _lastFrameProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);

  static const _throttle = Duration(milliseconds: 150);
  static const _batasTanpaWajah = Duration(seconds: 6);
  static const _batasTotalGesture = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _target = Random().nextBool() ? _Gesture.kedip : _Gesture.senyum;
    _statusText = _instruksiAwal();
    _initCamera();
  }

  String _instruksiAwal() => _target == _Gesture.kedip
      ? 'Posisikan wajah di dalam frame, lalu kedipkan mata'
      : 'Posisikan wajah di dalam frame, lalu tersenyumlah';

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
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isInitializing = false);
      _mulaiTimeoutTotal();
      _mulaiStream();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = 'Gagal mengakses kamera depan.';
        _isInitializing = false;
      });
      _gagalDenganPeringatan(
        'Gagal mengakses kamera depan. Pastikan izin kamera sudah diberikan ke aplikasi.',
      );
    }
  }

  void _mulaiTimeoutTotal() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_batasTotalGesture, () {
      if (!mounted || _gesturePassed || _selesai) return;
      _gagalDenganPeringatan(
        'Waktu verifikasi habis. Pastikan pencahayaan cukup dan wajah terlihat jelas di kamera, lalu coba lagi.',
      );
    });
  }

  void _mulaiStream() {
    if (_cameraController == null || _isStreaming) return;
    _isStreaming = true;
    _cameraController!.startImageStream(_onFrame);
  }

  Future<void> _hentikanStream() async {
    if (_cameraController == null || !_isStreaming) return;
    _isStreaming = false;
    try {
      await _cameraController!.stopImageStream();
    } catch (_) {
      // controller mungkin sudah di-dispose, aman diabaikan
    }
  }

  void _onFrame(CameraImage image) {
    if (_isBusyFrame || _gesturePassed || _selesai) return;
    final now = DateTime.now();
    if (now.difference(_lastFrameProcessedAt) < _throttle) return;
    _lastFrameProcessedAt = now;
    _isBusyFrame = true;
    _prosesFrame(image).whenComplete(() => _isBusyFrame = false);
  }

  Future<void> _prosesFrame(CameraImage image) async {
    final inputImage = _toInputImage(image);
    if (inputImage == null) return;

    List<Face> faces;
    try {
      faces = await _faceDetector.processImage(inputImage);
    } catch (_) {
      return;
    }
    if (!mounted || _gesturePassed || _selesai) return;

    if (faces.isEmpty) {
      _tandaiTanpaWajah();
      return;
    }
    _terakhirWajahTerdeteksi = DateTime.now();
    _evaluasiGesture(faces.first);
  }

  void _tandaiTanpaWajah() {
    final sejak = _terakhirWajahTerdeteksi;
    if (sejak != null && DateTime.now().difference(sejak) > _batasTanpaWajah) {
      _gagalDenganPeringatan(
        'Wajah tidak terdeteksi. Pastikan wajah terlihat jelas dan pencahayaan cukup, lalu coba lagi.',
      );
      return;
    }
    if (mounted) {
      setState(() => _statusText = 'Wajah tidak terdeteksi, posisikan di tengah frame');
    }
  }

  void _evaluasiGesture(Face face) {
    if (_target == _Gesture.kedip) {
      _evaluasiKedip(face);
    } else {
      _evaluasiSenyum(face);
    }
  }

  void _evaluasiKedip(Face face) {
    final kiri = face.leftEyeOpenProbability;
    final kanan = face.rightEyeOpenProbability;
    if (kiri == null || kanan == null) return;

    final tertutup = kiri < _ambangMataTertutup && kanan < _ambangMataTertutup;
    final terbuka = kiri > _ambangMataTerbuka && kanan > _ambangMataTerbuka;

    if (tertutup) {
      _pernahTertutup = true;
      if (mounted) setState(() => _statusText = 'Bagus, sekarang buka mata kembali');
      return;
    }
    if (terbuka && _pernahTertutup) {
      _gesturTerkonfirmasi();
    }
  }

  void _evaluasiSenyum(Face face) {
    final senyum = face.smilingProbability;
    if (senyum == null) return;

    if (senyum >= _ambangSenyum) {
      _frameSenyumBerturut++;
      if (_frameSenyumBerturut >= _frameSenyumDibutuhkan) {
        _gesturTerkonfirmasi();
      } else if (mounted) {
        setState(() => _statusText = 'Bagus, pertahankan senyumnya...');
      }
    } else {
      _frameSenyumBerturut = 0;
    }
  }

  void _gesturTerkonfirmasi() {
    if (_gesturePassed) return;
    _gesturePassed = true;
    _timeoutTimer?.cancel();
    if (mounted) setState(() => _statusText = 'Terverifikasi! Mengambil foto...');
    _ambilFotoFinal();
  }

  Future<void> _ambilFotoFinal() async {
    await _hentikanStream();
    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      final XFile photo = await _cameraController!.takePicture();
      await _submitAbsen(File(photo.path));
    } catch (e) {
      _gagalDenganPeringatan('Gagal mengambil foto. Silakan coba lagi.');
    }
  }

  Future<void> _submitAbsen(File foto) async {
    if (mounted) setState(() => _statusText = 'Mengirim data absen...');

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
      _selesai = true;
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
                 Navigator.of(context)
                  ..pop()  // tutup dialog
                  ..pop(); // keluar dari flow absen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      setState(() => _isSubmitting = false);
      // Gagal di sisi backend (bukan deteksi wajah) -- tetap diarahkan balik
      // lewat onGagal, konsisten alur retry-dari-awal.
      _gagalDenganPeringatan(result['message'] ?? 'Absen gagal, silakan coba lagi.');
    }
  }

  void _gagalDenganPeringatan(String pesan) {
    if (_selesai) return;
    _selesai = true;
    _hentikanStream();
    if (mounted) {
      showAppSnackBar(context, pesan, type: AppSnackBarType.error);
    }
    widget.onGagal();
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _cameraController?.description;
    if (camera == null) return null;

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
    if (image.planes.length != 1) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _hentikanStream();
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
                    color: _gesturePassed ? Colors.green : Colors.teal,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(140),
                ),
              ),
              if (_isSubmitting)
                Container(
                  color: Colors.black45,
                  child: const Center(child: CircularProgressIndicator()),
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
      ],
    );
  }
}