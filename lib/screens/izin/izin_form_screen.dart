import 'package:flutter/material.dart';
import '../../services/izin_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/section_card.dart';

class IzinFormScreen extends StatefulWidget {
  const IzinFormScreen({super.key});

  @override
  State<IzinFormScreen> createState() => _IzinFormScreenState();
}

class _IzinFormScreenState extends State<IzinFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _izinService = IzinService();
  final _keperluanController = TextEditingController();

  DateTime _tanggal = DateTime.now();
  TimeOfDay? _jamKeluar;
  bool _submitting = false;

  @override
  void dispose() {
    _keperluanController.dispose();
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
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _pilihJamKeluar() async {
    final picked = await showTimePicker(
      context: context,
      // Pilihan sebelumnya jadi titik awal. Sebelumnya selalu
      // TimeOfDay.now(), jadi mengoreksi jam berarti menggulir ulang
      // dari jam sekarang setiap kali.
      initialTime: _jamKeluar ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _jamKeluar = picked);
  }

  Future<void> _submit() async {
    // Jam keluar ikut divalidasi Form sekarang, jadi tidak ada lagi
    // pengecekan terpisah lewat snackbar di sini.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final result = await _izinService.ajukan(
      tanggal: _formatTanggal(_tanggal),
      jamKeluar: _formatJam(_jamKeluar!),
      keperluan: _keperluanController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      showAppSnackBar(context, result['message'] ?? 'Gagal mengajukan izin',
          type: AppSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Izin')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SectionCard(
                title: 'Waktu Izin',
                icon: Icons.event_note,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tanggal'),
                    subtitle: Text(_formatTanggal(_tanggal)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pilihTanggal,
                  ),
                  // FormField, bukan pengecekan manual di _submit: jam
                  // keluar yang belum dipilih sekarang ditandai di tempat
                  // yang salah, sama seperti Keperluan — bukan lewat
                  // snackbar yang muncul jauh dari fieldnya lalu hilang.
                  FormField<TimeOfDay>(
                    initialValue: _jamKeluar,
                    validator: (_) =>
                        _jamKeluar == null ? 'Jam keluar wajib dipilih' : null,
                    builder: (state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Jam Keluar'),
                          subtitle: Text(_jamKeluar != null
                              ? _formatJam(_jamKeluar!)
                              : 'Belum dipilih'),
                          trailing: const Icon(Icons.access_time),
                          onTap: () async {
                            await _pilihJamKeluar();
                            state.didChange(_jamKeluar);
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
                      ],
                    ),
                  ),
                ],
              ),
              SectionCard(
                title: 'Keperluan',
                icon: Icons.edit_note,
                children: [
                  TextFormField(
                    controller: _keperluanController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Jelaskan keperluan izin...',
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