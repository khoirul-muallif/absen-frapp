import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/informasi_service.dart';
import '../../models/informasi_model.dart';
import 'informasi_detail_screen.dart';

class InformasiScreen extends StatefulWidget {
  const InformasiScreen({super.key});

  @override
  State<InformasiScreen> createState() => _InformasiScreenState();
}

class _InformasiScreenState extends State<InformasiScreen> {
  final _service = InformasiService();
  final _scrollController = ScrollController();
  final _cariController = TextEditingController();

  final List<InformasiItem> _items = [];
  int _halaman = 1;
  bool _adaLagi = false;
  String _q = '';

  bool _loadingAwal = true;
  bool _loadingHalamanBerikut = false;
  String? _error;

  Timer? _debounce;

  /// Penanda pencarian terakhir yang diminta. Mengetik "cuti" melepas
  /// beberapa request dan urutan mendaratnya tidak dijamin — tanpa ini
  /// hasil kata kunci lama bisa menimpa hasil yang sedang diketik.
  /// Pola yang sama dengan _requestTerakhir di RiwayatScreen.
  int _requestTerakhir = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_saatScroll);
    _muatAwal();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _cariController.dispose();
    super.dispose();
  }

  void _saatScroll() {
    if (!_adaLagi || _loadingHalamanBerikut || _loadingAwal) return;
    // 300px sebelum dasar, supaya halaman berikutnya sudah dalam
    // perjalanan saat user sampai di ujung.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _muatHalamanBerikut();
    }
  }

  void _saatKetik(String nilai) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (nilai.trim() == _q) return;
      _q = nilai.trim();
      _muatAwal();
    });
  }

  Future<void> _muatAwal({bool tampilkanSpinner = true}) async {
    final idRequest = ++_requestTerakhir;

    if (tampilkanSpinner) {
      setState(() {
        _loadingAwal = true;
        _error = null;
      });
    }

    try {
      final hasil = await _service.daftar(halaman: 1, q: _q);
      if (!mounted || idRequest != _requestTerakhir) return;
      setState(() {
        _items
          ..clear()
          ..addAll(hasil.records);
        _halaman = hasil.halamanSekarang;
        _adaLagi = hasil.adaLagi;
        _error = null;
        _loadingAwal = false;
      });
    } on ApiException catch (e) {
      if (!mounted || idRequest != _requestTerakhir) return;
      setState(() {
        _error = e.message;
        _loadingAwal = false;
      });
    } catch (_) {
      if (!mounted || idRequest != _requestTerakhir) return;
      setState(() {
        _error = 'Terjadi kesalahan saat memuat pengumuman.';
        _loadingAwal = false;
      });
    }
  }

  Future<void> _muatHalamanBerikut() async {
    final idRequest = _requestTerakhir;
    setState(() => _loadingHalamanBerikut = true);

    try {
      final hasil = await _service.daftar(halaman: _halaman + 1, q: _q);
      // Pencarian berganti selagi halaman berikutnya dimuat: buang
      // hasilnya, kalau tidak baris kata kunci lama menempel di bawah
      // hasil yang baru.
      if (!mounted || idRequest != _requestTerakhir) return;
      setState(() {
        _items.addAll(hasil.records);
        _halaman = hasil.halamanSekarang;
        _adaLagi = hasil.adaLagi;
        _loadingHalamanBerikut = false;
      });
    } catch (_) {
      if (!mounted || idRequest != _requestTerakhir) return;
      // Gagal memuat lanjutan bukan alasan membuang yang sudah tampil.
      // Diamkan saja; scroll berikutnya akan mencoba lagi.
      setState(() => _loadingHalamanBerikut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informasi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _cariController,
              onChanged: _saatKetik,
              decoration: InputDecoration(
                hintText: 'Cari judul pengumuman...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _cariController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _cariController.clear();
                          _debounce?.cancel();
                          _q = '';
                          _muatAwal();
                        },
                      ),
              ),
            ),
          ),
          Expanded(child: _isi()),
        ],
      ),
    );
  }

  Widget _isi() {
    if (_loadingAwal) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _kartuError();
    }
    if (_items.isEmpty) {
      return _kosong();
    }

    return RefreshIndicator(
      onRefresh: () => _muatAwal(tampilkanSpinner: false),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        // Satu baris ekstra di bawah untuk indikator halaman berikutnya.
        itemCount: _items.length + (_adaLagi ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _kartu(_items[index]);
        },
      ),
    );
  }

  Widget _kartu(InformasiItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InformasiDetailScreen(
              id: item.id,
              judulAwal: item.judul,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.judul,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    item.tanggalTerbit,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (item.ringkasan.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.ringkasan,
                  // Backend sudah memotong di 150 karakter, tapi di layar
                  // sempit itu masih bisa jadi empat baris lebih.
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _kosong() {
    // Dibedakan: belum ada pengumuman sama sekali vs pencarian tidak
    // ketemu. Pesan "Belum ada informasi" saat user baru mengetik kata
    // kunci membuat seolah seluruh modulnya kosong.
    final sedangMencari = _q.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: () => _muatAwal(tampilkanSpinner: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    sedangMencari
                        ? Icons.search_off
                        : Icons.campaign_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    sedangMencari
                        ? 'Tidak ada pengumuman yang cocok'
                        : 'Belum ada informasi',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      sedangMencari
                          ? 'Coba kata kunci lain. Pencarian hanya mencocokkan judul.'
                          : 'Pengumuman dari instansi akan tampil di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat pengumuman',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _muatAwal,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}