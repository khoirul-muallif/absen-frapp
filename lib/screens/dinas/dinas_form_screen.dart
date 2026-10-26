// lib/screens/dinas/dinas_form_screen.dart
import 'package:flutter/material.dart';
import '../../services/dinas_service.dart';
import '../../utils/snackbar_helper.dart';

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

  DateTimeRange? _rentang;
  bool _submitting = false;

  @override
  void dispose() {
    _tujuanController.dispose();
    _keperluanController.dispose();
    super.dispose();
  }

  String _formatTanggal(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pilihRentang() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 90)),
      initialDateRange: _rentang,
    );
    if (picked != null) setState(() => _rentang = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_rentang == null) {
      showAppSnackBar(context, 'Pilih tanggal mulai dan selesai dulu');
      return;
    }

    setState(() => _submitting = true);

    final result = await _dinasService.ajukan(
      tanggalMulai: _formatTanggal(_rentang!.start),
      tanggalSelesai: _formatTanggal(_rentang!.end),
      tujuan: _tujuanController.text.trim(),
      keperluan: _keperluanController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      showAppSnackBar(context, result['message'] ?? 'Gagal mengajukan dinas');
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
          child: Column(
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
                onTap: _pilihRentang,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tujuanController,
                decoration: const InputDecoration(
                  labelText: 'Tujuan',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Tujuan wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _keperluanController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Keperluan',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Keperluan wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
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