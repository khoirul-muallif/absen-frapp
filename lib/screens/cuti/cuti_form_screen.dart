// lib/screens/cuti/cuti_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/cuti_service.dart';
import '../../models/cuti_kuota_model.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/section_card.dart';

class CutiFormScreen extends StatefulWidget {
  const CutiFormScreen({super.key});

  @override
  State<CutiFormScreen> createState() => _CutiFormScreenState();
}

class _CutiFormScreenState extends State<CutiFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cutiService = CutiService();
  final _alasanController = TextEditingController();

  List<CutiKuotaItem> _jenisCutiList = [];
  bool _loadingJenis = true;
  CutiKuotaItem? _jenisTerpilih;
  DateTimeRange? _rentang;
  File? _lampiran;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadJenisCuti();
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

  String _formatTanggal(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int get _jumlahHari =>
      _rentang == null ? 0 : _rentang!.end.difference(_rentang!.start).inDays + 1;

  Future<void> _pilihRentang() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      // CutiController memvalidasi after_or_equal:today. Sebelumnya
      // kalender menawarkan 7 hari ke belakang, jadi tanggal lewat baru
      // ditolak SETELAH submit.
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
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
      tanggalMulai: _formatTanggal(_rentang!.start),
      tanggalSelesai: _formatTanggal(_rentang!.end),
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
                                  _rentang != null
                                      ? '${_formatTanggal(_rentang!.start)} s/d ${_formatTanggal(_rentang!.end)}'
                                      : 'Belum dipilih',
                                ),
                                trailing: const Icon(Icons.date_range),
                                onTap: () async {
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
                        onPressed: _submitting ? null : _submit,
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