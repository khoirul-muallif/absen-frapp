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

  TimeOfDay? _jamKeluar;
  TimeOfDay? _jamKembaliRencana;
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

  int _menitDari(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<TimeOfDay?> _pilihJam(TimeOfDay? sebelumnya) {
    return showTimePicker(
      context: context,
      initialTime: sebelumnya ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
  }

  Future<void> _submit() async {
    // Jam keluar ikut divalidasi Form sekarang, jadi tidak ada lagi
    // pengecekan terpisah lewat snackbar di sini.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final result = await _izinService.ajukan(
      tanggal: _formatTanggal(DateTime.now()),
      jamKembaliRencana: _formatJam(_jamKembaliRencana!),
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
                  // Izin keluar sementara selalu untuk hari ini, jadi
                  // tidak ada yang perlu dipilih. Tetap ditampilkan supaya
                  // karyawan tahu tanggal apa yang tercatat.
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, size: 20),
                    title: const Text('Hari ini'),
                    subtitle: Text(_formatTanggal(DateTime.now())),
                  ),
                  // FormField, bukan pengecekan manual di _submit: jam
                  // keluar yang belum dipilih sekarang ditandai di tempat
                  // yang salah, sama seperti Keperluan — bukan lewat
                  // snackbar yang muncul jauh dari fieldnya lalu hilang.
                  _barisJam(
                    label: 'Jam Keluar',
                    nilai: _jamKeluar,
                    onPilih: (t) => setState(() => _jamKeluar = t),
                    validator: () =>
                        _jamKeluar == null ? 'Jam keluar wajib dipilih' : null,
                  ),
                  _barisJam(
                    label: 'Rencana Kembali',
                    nilai: _jamKembaliRencana,
                    onPilih: (t) => setState(() => _jamKembaliRencana = t),
                    validator: () {
                      if (_jamKembaliRencana == null) {
                        return 'Rencana kembali wajib dipilih';
                      }
                      if (_jamKeluar != null &&
                          _menitDari(_jamKembaliRencana!) <=
                              _menitDari(_jamKeluar!)) {
                        return 'Harus setelah jam keluar';
                      }
                      return null;
                    },
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