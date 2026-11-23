// lib/screens/lembur/lembur_form_screen.dart
import 'package:flutter/material.dart';
import '../../services/lembur_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/section_card.dart';

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
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<TimeOfDay?> _pilihJam(TimeOfDay? sebelumnya) {
    return showTimePicker(
      context: context,
      // Pilihan sebelumnya jadi titik awal, bukan selalu jam sekarang.
      initialTime: sebelumnya ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
  }

  Future<void> _submit() async {
    // Jam mulai/selesai ikut divalidasi Form sekarang — tidak ada lagi
    // tiga pengecekan terpisah lewat snackbar di sini.
    if (!_formKey.currentState!.validate()) return;

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
      showAppSnackBar(context, result['message'] ?? 'Gagal mengajukan lembur',
          type: AppSnackBarType.error);
    }
  }

  /// Baris jam yang errornya muncul di bawah fieldnya, bukan lewat
  /// snackbar yang melayang jauh dari tempat masalahnya lalu hilang.
  Widget _barisJam({
    required String label,
    required TimeOfDay? nilai,
    required ValueChanged<TimeOfDay> onPilih,
    required String? Function() validator,
  }) {
    return FormField<TimeOfDay>(
      initialValue: nilai,
      validator: (_) => validator(),
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            subtitle: Text(nilai != null ? _formatJam(nilai) : 'Belum dipilih'),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final picked = await _pilihJam(nilai);
              if (picked == null) return;
              onPilih(picked);
              state.didChange(picked);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Lembur')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SectionCard(
                title: 'Waktu Lembur',
                icon: Icons.schedule,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tanggal'),
                    subtitle: Text(_formatTanggal(_tanggal)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pilihTanggal,
                  ),
                  _barisJam(
                    label: 'Jam Mulai',
                    nilai: _jamMulai,
                    onPilih: (t) => setState(() => _jamMulai = t),
                    validator: () =>
                        _jamMulai == null ? 'Jam mulai wajib dipilih' : null,
                  ),
                  _barisJam(
                    label: 'Jam Selesai',
                    nilai: _jamSelesai,
                    onPilih: (t) => setState(() => _jamSelesai = t),
                    validator: () {
                      if (_jamSelesai == null) {
                        return 'Jam selesai wajib dipilih';
                      }
                      // Backend (LemburController::ajukan(), fase 59) cuma
                      // menolak durasi nol — lintas tengah malam sudah
                      // diizinkan, jadi jangan dilarang di sini.
                      if (_jamMulai != null &&
                          _jamSelesai!.hour == _jamMulai!.hour &&
                          _jamSelesai!.minute == _jamMulai!.minute) {
                        return 'Tidak boleh sama dengan jam mulai';
                      }
                      return null;
                    },
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
                      hintText: 'Jelaskan alasan lembur...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Alasan wajib diisi'
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