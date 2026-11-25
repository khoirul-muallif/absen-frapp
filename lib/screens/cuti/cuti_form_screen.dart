// lib/screens/cuti/cuti_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/cuti_service.dart';
import '../../services/dinas_service.dart';
import '../../models/cuti_kuota_model.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/section_card.dart';
import '../../utils/format_tanggal.dart';

class CutiFormScreen extends StatefulWidget {
  const CutiFormScreen({super.key});

  @override
  State<CutiFormScreen> createState() => _CutiFormScreenState();
}

class _CutiFormScreenState extends State<CutiFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cutiService = CutiService();
  final _dinasService = DinasService();
  final _alasanController = TextEditingController();

  List<CutiKuotaItem> _jenisCutiList = [];
  bool _loadingJenis = true;
  CutiKuotaItem? _jenisTerpilih;
  DateTimeRange? _rentang;
  File? _lampiran;
  bool _submitting = false;

  /// Rentang cuti & dinas yang SUDAH approved. Backend menolak pengajuan
  /// yang beririsan dengan salah satunya, dan sebelum ini penolakannya
  /// baru muncul setelah submit tanpa menyebut bentrok dengan apa.
  List<({DateTime mulai, DateTime selesai, String label})> _terpakai = [];
  bool _loadingTerpakai = true;

  @override
  void initState() {
    super.initState();
    _loadJenisCuti();
    _muatRentangTerpakai();
  }

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _loadJenisCuti() async {
    final list = await _cutiService.kuota();

    // Filter ke semester berjalan aja -- entri tanpa semester (periode
    // tahunan) selalu ikut tampil.
    final bulanSekarang = DateTime.now().month;
    final semesterSekarang = bulanSekarang <= 6 ? 1 : 2;
    final filtered = list
        .where((j) => j.semester == null || j.semester == semesterSekarang)
        .toList();

    if (!mounted) return;
    setState(() {
      _jenisCutiList = filtered;
      _loadingJenis = false;
    });
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

  /// Batas akhir yang boleh dipilih. Backend menolak rentang yang
  /// melintasi pergantian tahun, dan untuk jenis cuti semesteran juga
  /// pergantian semester. Dijepit di kalender supaya tidak bisa dipilih.
  DateTime get _batasAkhir {
    final now = DateTime.now();
    final semesteran = _jenisTerpilih?.semester != null;
    if (!semesteran) return DateTime(now.year, 12, 31);
    // Semester 1 berakhir 30 Juni, semester 2 ikut akhir tahun.
    return now.month <= 6
        ? DateTime(now.year, 6, 30)
        : DateTime(now.year, 12, 31);
  }

  Future<void> _pilihRentang() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      // CutiController memvalidasi after_or_equal:today.
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: _batasAkhir,
      initialDateRange: _rentang,
    );
    if (picked != null) setState(() => _rentang = picked);
  }

  Future<void> _pilihLampiran() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (file != null && file.path != null) {
      setState(() => _lampiran = File(file.path!));
    }
  }

  Future<void> _submit() async {
    // Jenis, rentang, dan lampiran ikut divalidasi Form sekarang — tidak
    // ada lagi tiga pengecekan terpisah lewat snackbar di sini.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final result = await _cutiService.ajukan(
      jenisCutiId: _jenisTerpilih!.jenisCutiId,
      tanggalMulai: tanggalUntukApi(_rentang!.start),
      tanggalSelesai: tanggalUntukApi(_rentang!.end),
      alasan: _alasanController.text.trim(),
      lampiran: _lampiran,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      showAppSnackBar(context, result['message'] ?? 'Gagal mengajukan cuti',
          type: AppSnackBarType.error);
    }
  }

  /// Sisa kuota setelah pengajuan ini, kalau keduanya sudah dipilih.
  /// Angka mentah dari endpoint kuota; backend tetap yang memutuskan saat
  /// approve (kuota dikunci lockForUpdate di sana, fase 22).
  Widget? _ringkasanKuota() {
    if (_jenisTerpilih == null || _rentang == null) return null;

    final sisaSesudah = _jenisTerpilih!.sisa - _jumlahHari;
    final kurang = sisaSesudah < 0;
    final skema = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            kurang ? Icons.warning_amber : Icons.info_outline,
            size: 16,
            color: kurang ? skema.error : skema.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              kurang
                  ? '$_jumlahHari hari diajukan, sisa kuota cuma ${_jenisTerpilih!.sisa} hari'
                  : '$_jumlahHari hari diajukan, sisa kuota jadi $sisaSesudah hari',
              style: TextStyle(
                fontSize: 12,
                color: kurang ? skema.error : skema.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ringkasan = _ringkasanKuota();

    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Cuti')),
      body: _loadingJenis
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    SectionCard(
                      title: 'Jenis & Waktu',
                      icon: Icons.beach_access,
                      children: [
                        DropdownButtonFormField<CutiKuotaItem>(
                          initialValue: _jenisTerpilih,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Jenis Cuti',
                            border: OutlineInputBorder(),
                          ),
                          items: _jenisCutiList.map((j) {
                            final label = j.semester != null
                                ? '${j.nama} (semester ${j.semester}, sisa ${j.sisa} hari)'
                                : '${j.nama} (sisa ${j.sisa} hari)';
                            return DropdownMenuItem(
                                value: j, child: Text(label));
                          }).toList(),
                          onChanged: (v) => setState(() {
                            _jenisTerpilih = v;
                            _lampiran = null;
                            // Jenis semesteran memperpendek batas akhir.
                            // Rentang yang dipilih sebelumnya bisa jadi
                            // melewati batas baru — buang daripada
                            // membiarkannya ditolak setelah submit.
                            if (_rentang != null &&
                                _rentang!.end.isAfter(_batasAkhir)) {
                              _rentang = null;
                            }
                          }),
                          validator: (v) => v == null ? 'Pilih jenis cuti' : null,
                        ),
                        FormField<DateTimeRange>(
                          initialValue: _rentang,
                          validator: (_) => _rentang == null
                              ? 'Rentang tanggal wajib dipilih'
                              : null,
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
                                  padding:
                                      const EdgeInsets.only(left: 16, top: 4),
                                  child: Text(
                                    state.errorText!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ?ringkasan,
                        if (_bentrok.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
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
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SectionCard(
                      title: 'Alasan',
                      icon: Icons.edit_note,
                      children: [
                        TextFormField(
                          controller: _alasanController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Jelaskan alasan cuti...',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Alasan wajib diisi'
                              : null,
                        ),
                      ],
                    ),
                    if (_jenisTerpilih?.perluLampiran == true)
                      SectionCard(
                        title: 'Lampiran',
                        icon: Icons.attach_file,
                        children: [
                          FormField<File>(
                            initialValue: _lampiran,
                            validator: (_) => _lampiran == null
                                ? '${_jenisTerpilih!.nama} wajib melampirkan surat keterangan'
                                : null,
                            builder: (state) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Surat Keterangan'),
                                  subtitle: Text(
                                    _lampiran != null
                                        // Pisahkan pakai separator OS, bukan
                                        // '/' — di Android path-nya '/',
                                        // tapi jangan bergantung ke situ.
                                        ? _lampiran!.path.split(Platform.pathSeparator).last
                                        : 'Belum dipilih',
                                  ),
                                  trailing: const Icon(Icons.attach_file),
                                  onTap: () async {
                                    await _pilihLampiran();
                                    state.didChange(_lampiran);
                                  },
                                ),
                                if (state.hasError)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(left: 16, top: 4),
                                    child: Text(
                                      state.errorText!,
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