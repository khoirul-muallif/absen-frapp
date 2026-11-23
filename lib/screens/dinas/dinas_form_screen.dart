// lib/screens/dinas/dinas_form_screen.dart
import 'package:flutter/material.dart';
import '../../services/dinas_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/section_card.dart';

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
      lastDate: now.add(const Duration(days: 90)),
      initialDateRange: _rentang,
    );
    if (picked != null) setState(() => _rentang = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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