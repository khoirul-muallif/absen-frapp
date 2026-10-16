// lib/screens/cuti/cuti_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/cuti_service.dart';
import '../../models/cuti_kuota_model.dart';

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
    if (!mounted) return;
    setState(() {
      _jenisCutiList = list;
      _loadingJenis = false;
    });
  }

  String _formatTanggal(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pilihRentang() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 7)),
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
    if (!_formKey.currentState!.validate()) return;

    if (_jenisTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jenis cuti dulu')),
      );
      return;
    }
    if (_rentang == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal mulai dan selesai dulu')),
      );
      return;
    }
    if (_jenisTerpilih!.perluLampiran && _lampiran == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_jenisTerpilih!.nama} wajib melampirkan surat keterangan')),
      );
      return;
    }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal mengajukan cuti')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    DropdownButtonFormField<CutiKuotaItem>(
                      initialValue: _jenisTerpilih,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Cuti',
                        border: OutlineInputBorder(),
                      ),
                      items: _jenisCutiList.map((j) {
                        final label = j.semester != null
                            ? '${j.nama} (semester ${j.semester}, sisa ${j.sisa} hari)'
                            : '${j.nama} (sisa ${j.sisa} hari)';
                        return DropdownMenuItem(value: j, child: Text(label));
                      }).toList(),
                      onChanged: (v) => setState(() {
                        _jenisTerpilih = v;
                        _lampiran = null;
                      }),
                      validator: (v) => v == null ? 'Pilih jenis cuti' : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Rentang Tanggal'),
                      subtitle: Text(
                        _rentang != null
                            ? '${_formatTanggal(_rentang!.start)} s/d ${_formatTanggal(_rentang!.end)}'
                            : 'Belum dipilih',
                      ),
                      trailing: const Icon(Icons.date_range),
                      onTap: _pilihRentang,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _alasanController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Alasan',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Alasan wajib diisi' : null,
                    ),
                    if (_jenisTerpilih?.perluLampiran == true) ...[
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Lampiran (wajib)'),
                        subtitle: Text(_lampiran != null
                            ? _lampiran!.path.split('/').last
                            : 'Belum dipilih'),
                        trailing: const Icon(Icons.attach_file),
                        onTap: _pilihLampiran,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Ajukan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}