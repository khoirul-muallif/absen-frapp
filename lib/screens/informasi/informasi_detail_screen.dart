import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/informasi_service.dart';
import '../../models/informasi_model.dart';

class InformasiDetailScreen extends StatefulWidget {
  final int id;
  /// Dipakai sebagai judul sementara selagi detailnya dimuat, supaya
  /// layar tidak terbuka kosong tanpa petunjuk sedang membuka apa.
  final String judulAwal;

  const InformasiDetailScreen({
    super.key,
    required this.id,
    required this.judulAwal,
  });

  @override
  State<InformasiDetailScreen> createState() => _InformasiDetailScreenState();
}

class _InformasiDetailScreenState extends State<InformasiDetailScreen> {
  final _service = InformasiService();

  InformasiDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _sudahTidakAda = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
      _sudahTidakAda = false;
    });

    try {
      final detail = await _service.detail(widget.id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        // findOrFail ada DI DALAM scope aktif(), jadi 404 di sini biasanya
        // bukan "id salah" tapi "admin menonaktifkan pengumuman ini
        // sementara daftarnya terbuka". Tombol Coba Lagi tidak menolong.
        _sudahTidakAda = e.statusCode == 404;
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan saat memuat pengumuman.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_detail?.judul ?? widget.judulAwal)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _kartuError()
              : _isi(),
    );
  }

  Widget _isi() {
    final detail = _detail!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          detail.judul,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              detail.tanggalTerbit,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        const Divider(height: 28),
        // isi dikirim sebagai teks biasa. Kalau field ini nanti diganti
        // RichEditor di Filament, tag HTML-nya akan tampil mentah di sini.
        Text(detail.isi, style: const TextStyle(fontSize: 15, height: 1.5)),
      ],
    );
  }

  Widget _kartuError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _sudahTidakAda ? Icons.visibility_off_outlined : Icons.cloud_off,
              size: 48,
              color: Colors.grey[500],
            ),
            const SizedBox(height: 16),
            Text(
              _sudahTidakAda
                  ? 'Pengumuman ini sudah tidak tersedia'
                  : 'Gagal memuat pengumuman',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _sudahTidakAda
                  ? 'Mungkin sudah ditarik oleh admin.'
                  : _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            if (_sudahTidakAda)
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kembali'),
              )
            else
              FilledButton.tonal(
                onPressed: _muat,
                child: const Text('Coba Lagi'),
              ),
          ],
        ),
      ),
    );
  }
}