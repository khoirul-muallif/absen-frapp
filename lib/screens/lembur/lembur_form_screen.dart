// lib/screens/lembur/lembur_form_screen.dart
import 'package:flutter/material.dart';
import '../../services/lembur_service.dart';

class LemburFormScreen extends StatefulWidget {
  const LemburFormScreen({super.key});

  @override
  State<LemburFormScreen> createState() => _LemburFormScreenState();
}

class _LemburFormScreenState extends State<LemburFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lemburService = LemburService();
  final _alasanController = TextEditingController();

  DateTime _tanggal = DateTime.now();
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;
  bool _submitting = false;

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  String _formatTanggal(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatJam(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _pilihJamMulai() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _jamMulai = picked);
  }

  Future<void> _pilihJamSelesai() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _jamSelesai = picked);
  }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_jamMulai == null || _jamSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jam mulai dan jam selesai dulu')),
      );
      return;
    }

    // lembur_form_screen.dart — ganti pengecekan durasi nol jadi ini
    if (!(_jamSelesai!.hour > _jamMulai!.hour ||
        (_jamSelesai!.hour == _jamMulai!.hour && _jamSelesai!.minute > _jamMulai!.minute))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jam selesai harus setelah jam mulai (belum bisa lintas tengah malam)')),
      );
      return;
    }

    setState(() => _submitting = true);

     final result = await _lemburService.ajukan(
      tanggal: _formatTanggal(_tanggal),
      jamMulai: _formatJam(_jamMulai!),
      jamSelesai: _formatJam(_jamSelesai!),
      alasan: _alasanController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal mengajukan lembur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Lembur')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tanggal'),
                subtitle: Text(_formatTanggal(_tanggal)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pilihTanggal,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Jam Mulai'),
                subtitle: Text(_jamMulai != null ? _formatJam(_jamMulai!) : 'Belum dipilih'),
                trailing: const Icon(Icons.access_time),
                onTap: _pilihJamMulai,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Jam Selesai'),
                subtitle: Text(_jamSelesai != null ? _formatJam(_jamSelesai!) : 'Belum dipilih'),
                trailing: const Icon(Icons.access_time),
                onTap: _pilihJamSelesai,
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