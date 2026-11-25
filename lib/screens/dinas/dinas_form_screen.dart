// lib/screens/dinas/dinas_form_screen.dart
import 'package:flutter/material.dart';
import '../../services/dinas_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/section_card.dart';
import '../../services/cuti_service.dart';
import '../../utils/format_tanggal.dart';

class DinasFormScreen extends StatefulWidget {
  const DinasFormScreen({super.key});

  @override
  State<DinasFormScreen> createState() => _DinasFormScreenState();
}

class _DinasFormScreenState extends State<DinasFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dinasService = DinasService();
  final _tujuanController = TextEditingController();
  final _keperluanController = TextEditingController();
  final _cutiService = CutiService();

  /// Rentang cuti & dinas yang SUDAH approved. Backend menolak pengajuan
  /// yang beririsan dengan salah satunya, dan sebelum ini penolakannya
  /// baru muncul setelah submit tanpa menyebut bentrok dengan apa.
  List<({DateTime mulai, DateTime selesai, String label})> _terpakai = [];
  bool _loadingTerpakai = true;

  DateTimeRange? _rentang;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _muatRentangTerpakai();
  }

  @override
  void dispose() {
    _tujuanController.dispose();
    _keperluanController.dispose();
    super.dispose();
  }

  Future<void> _muatRentangTerpakai() async {
    // Gagal diam-diam: ini cuma peringatan dini, bukan penentu. Backend
    // tetap yang memutuskan, jadi daftar kosong karena jaringan mati
    // tidak boleh menghalangi pengajuan.
    try {
      final hasil = await Future.wait([
        _cutiService.riwayatOrThrow(status: 'approved'),
        _dinasService.riwayatOrThrow(status: 'approved'),
      ]);
      if (!mounted) return;

      final daftar = <({DateTime mulai, DateTime selesai, String label})>[];
      for (final c in hasil[0] as List) {
        final m = _parseTanggalBackend(c.tanggalMulai);
        final s = _parseTanggalBackend(c.tanggalSelesai);
        if (m != null && s != null) {
          daftar.add((mulai: m, selesai: s, label: 'Cuti'));
        }
      }
      for (final d in hasil[1] as List) {
        final m = _parseTanggalBackend(d.tanggalMulai);
        final s = _parseTanggalBackend(d.tanggalSelesai);
        if (m != null && s != null) {
          daftar.add((mulai: m, selesai: s, label: 'Dinas'));
        }
      }

      setState(() {
        _terpakai = daftar;
        _loadingTerpakai = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTerpakai = false);
    }
  }

  static const _bulanIndex = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  // Nama bulan Inggris dari Carbon::format(), BUKAN locale device —
  // jangan pakai DateFormat yang locale-dependent (catatan konvensi FE).
  DateTime? _parseTanggalBackend(String tanggal) {
    final parts = tanggal.split(' ');
    if (parts.length != 3) return null;
    final hari = int.tryParse(parts[0]);
    final bulan = _bulanIndex[parts[1]];
    final tahun = int.tryParse(parts[2]);
    if (hari == null || bulan == null || tahun == null) return null;
    return DateTime(tahun, bulan, hari);
  }

  /// Rentang approved yang beririsan dengan pilihan sekarang. Aturan
  /// irisan disalin dari backend: mulai <= selesai_pilihan DAN
  /// selesai >= mulai_pilihan.
  List<({DateTime mulai, DateTime selesai, String label})> get _bentrok {
    if (_rentang == null) return [];
    return _terpakai
        .where((t) =>
            !t.mulai.isAfter(_rentang!.end) &&
            !t.selesai.isBefore(_rentang!.start))
        .toList();
  }

  int get _jumlahHari =>
      _rentang == null ? 0 : _rentang!.end.difference(_rentang!.start).inDays + 1;

  Future<void> _pilihRentang() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      // Backend memvalidasi after_or_equal:today. Sebelumnya kalender
      // menawarkan 7 hari ke belakang, jadi tanggal lewat baru ditolak
      // SETELAH submit.
      firstDate: DateTime(now.year, now.month, now.day),
      // Backend menolak rentang yang melintasi pergantian tahun. Dijepit
      // di kalender supaya tidak bisa dipilih sama sekali.
      lastDate: DateTime(now.year, 12, 31),
      initialDateRange: _rentang,
    );
    if (picked != null) setState(() => _rentang = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final result = await _dinasService.ajukan(
      tanggalMulai: tanggalUntukApi(_rentang!.start),
      tanggalSelesai: tanggalUntukApi(_rentang!.end),
      tujuan: _tujuanController.text.trim(),
      keperluan: _keperluanController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      showAppSnackBar(context, result['message'] ?? 'Gagal mengajukan dinas',
          type: AppSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Dinas')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SectionCard(
                title: 'Waktu Dinas',
                icon: Icons.date_range,
                children: [
                  FormField<DateTimeRange>(
                    initialValue: _rentang,
                    validator: (_) =>
                        _rentang == null ? 'Rentang tanggal wajib dipilih' : null,
                    builder: (state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Rentang Tanggal'),
                          subtitle: Text(
                            _loadingTerpakai
                                ? 'Memuat...'
                                : _rentang != null
                                    ? '${tanggalUntukLayar(_rentang!.start)} s/d ${tanggalUntukLayar(_rentang!.end)}'
                                    : 'Belum dipilih',
                          ),
                          trailing: const Icon(Icons.date_range),
                          // Dikunci selagi daftar cuti/dinas approved
                          // dimuat: memilih rentang sebelum datanya ada
                          // berarti peringatan bentrok baru muncul
                          // belakangan, setelah user mengira sudah aman.
                          onTap: _loadingTerpakai
                              ? null
                              : () async {
                                  await _pilihRentang();
                                  state.didChange(_rentang);
                                },
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 4),
                            child: Text(
                              state.errorText!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        // Backend menghitung jumlah_hari sendiri; angkanya
                        // ditampilkan di sini supaya user tidak perlu
                        // menghitung manual sebelum submit.
                        if (_rentang != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 4),
                            child: Text(
                              '$_jumlahHari hari',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (_bentrok.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Bentrok dengan ${_bentrok.map((b) => '${b.label} ${tanggalUntukLayar(b.mulai)} s/d ${tanggalUntukLayar(b.selesai)}').join(', ')}. Pilih tanggal lain.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SectionCard(
                title: 'Detail Dinas',
                icon: Icons.work_outline,
                children: [
                  TextFormField(
                    controller: _tujuanController,
                    decoration: const InputDecoration(
                      labelText: 'Tujuan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Tujuan wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _keperluanController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Keperluan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Keperluan wajib diisi'
                        : null,
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                onPressed: (_submitting || _bentrok.isNotEmpty)
                      ? null
                      : _submit, 
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ajukan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}