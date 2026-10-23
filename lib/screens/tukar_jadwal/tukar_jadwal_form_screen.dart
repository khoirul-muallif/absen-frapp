import 'package:flutter/material.dart';
import '../../services/tukar_jadwal_service.dart';
import '../../services/jadwal_service.dart';
import '../../models/jadwal_model.dart';

class TukarJadwalFormScreen extends StatefulWidget {
  const TukarJadwalFormScreen({super.key});

  @override
  State<TukarJadwalFormScreen> createState() => _TukarJadwalFormScreenState();
}

class _TukarJadwalFormScreenState extends State<TukarJadwalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tukarJadwalService = TukarJadwalService();
  final _jadwalService = JadwalService();
  final _alasanController = TextEditingController();

  String _mode = 'tukar'; // 'tukar' | 'pindah'
  bool _submitting = false;

  DateTime _tanggalAsal = DateTime.now();
  JadwalItem? _jadwalAsal;
  bool _loadingAsal = false;

  // Mode tukar
  DateTime _tanggalTujuan = DateTime.now();
  List<JadwalItem> _rekanList = [];
  JadwalItem? _jadwalTujuanTerpilih;
  bool _loadingRekan = false;

  // Mode pindah
  DateTime _tanggalBaru = DateTime.now();

  // Prefetch jadwal sendiri (30 hari lalu s/d 90 hari depan) -- dipakai
  // selectableDayPredicate biar DatePicker bisa meng-abu-kan tanggal yang
  // gak relevan, bukan tampil polos semua bisa dipilih.
  Map<String, JadwalItem> _jadwalSayaByTanggal = {};
  bool _loadingPrefetch = true;

  static const _bulanIndex = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };

  @override
  void initState() {
    super.initState();
    _prefetchJadwalSaya();
  }

  Future<void> _prefetchJadwalSaya() async {
    final mulai = DateTime.now().subtract(const Duration(days: 30));
    final selesai = DateTime.now().add(const Duration(days: 90));
    final list = await _jadwalService.sayaDalamRentang(
      _formatTanggal(mulai),
      _formatTanggal(selesai),
    );
    if (!mounted) return;
    final map = <String, JadwalItem>{};
    for (final j in list) {
      final tanggal = _parseTanggalBackend(j.tanggal);
      if (tanggal != null) map[_keyTanggal(tanggal)] = j;
    }
    setState(() {
      _jadwalSayaByTanggal = map;
      _loadingPrefetch = false;
    });
    _muatJadwalAsal(_tanggalAsal);
  }

  // Backend kirim tanggal format 'd M Y' (mis. "23 Oct 2026", nama bulan
  // Inggris dari Carbon::format(), BUKAN locale device) -- parse manual
  // sendiri, jangan pakai DateFormat locale-dependent (lihat catatan
  // konvensi FE soal ini).
  DateTime? _parseTanggalBackend(String tanggal) {
    final parts = tanggal.split(' ');
    if (parts.length != 3) return null;
    final hari = int.tryParse(parts[0]);
    final bulan = _bulanIndex[parts[1]];
    final tahun = int.tryParse(parts[2]);
    if (hari == null || bulan == null || tahun == null) return null;
    return DateTime(tahun, bulan, hari);
  }

  String _keyTanggal(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  String _formatTanggal(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _muatJadwalAsal(DateTime tanggal) async {
    setState(() {
      _tanggalAsal = tanggal;
      _loadingAsal = true;
    });
    final jadwal = await _jadwalService.sayaPadaTanggal(_formatTanggal(tanggal));
    if (!mounted) return;
    setState(() {
      _jadwalAsal = jadwal;
      _loadingAsal = false;
    });
  }

  Future<void> _muatRekan(DateTime tanggal) async {
    setState(() {
      _tanggalTujuan = tanggal;
      _jadwalTujuanTerpilih = null;
      _loadingRekan = true;
    });
    final list = await _jadwalService.rekanPadaTanggal(_formatTanggal(tanggal));
    if (!mounted) return;
    setState(() {
      _rekanList = list;
      _loadingRekan = false;
    });
  }

  Future<void> _pilihTanggalAsal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalAsal,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      selectableDayPredicate: (day) {
        final item = _jadwalSayaByTanggal[_keyTanggal(day)];
        if (item == null) return false; // gak ada Jadwal sama sekali
        if (_mode == 'pindah' && item.jenis == 'libur') return false; // pindah: asal wajib hari kerja (fase 66)
        return true;
      },
    );
    if (picked != null) _muatJadwalAsal(picked);
  }

  Future<void> _pilihTanggalTujuan() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalTujuan,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) _muatRekan(picked);
  }

  Future<void> _pilihTanggalBaru() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalBaru,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      selectableDayPredicate: (day) {
        final item = _jadwalSayaByTanggal[_keyTanggal(day)];
        return item != null && item.jenis == 'libur'; // tujuan pindah wajib hari libur sendiri (fase 66)
      },
    );
    if (picked != null) setState(() => _tanggalBaru = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_jadwalAsal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada jadwal Anda di tanggal ini, pilih tanggal lain')),
      );
      return;
    }
    if (!_jadwalAsal!.bisaDiajukan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal ini sedang terikat pengajuan tukar jadwal lain')),
      );
      return;
    }

    int? jadwalTujuanId;
    String? tanggalBaru;

    if (_mode == 'tukar') {
      if (_jadwalTujuanTerpilih == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih jadwal rekan tujuan dulu')),
        );
        return;
      }
      if (!_jadwalTujuanTerpilih!.bisaDiajukan) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal rekan ini sedang terikat pengajuan lain')),
        );
        return;
      }
      jadwalTujuanId = _jadwalTujuanTerpilih!.jadwalId;
    } else {
      tanggalBaru = _formatTanggal(_tanggalBaru);
    }

    setState(() => _submitting = true);

    final result = await _tukarJadwalService.ajukan(
      mode: _mode,
      jadwalId: _jadwalAsal!.jadwalId,
      jadwalTujuanId: jadwalTujuanId,
      tanggalBaru: tanggalBaru,
      alasan: _alasanController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal mengajukan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Tukar/Pindah Jadwal')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'tukar', label: Text('Tukar dengan Rekan')),
                  ButtonSegment(value: 'pindah', label: Text('Pindah Tanggal')),
                ],
                selected: {_mode},
                onSelectionChanged: (selected) {
                  setState(() {
                    _mode = selected.first;
                    _jadwalTujuanTerpilih = null; // gak relevan di mode pindah
                    if (_mode == 'pindah' && _jadwalAsal?.jenis == 'libur') {
                      _jadwalAsal = null; // asal libur gak valid buat mode pindah
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              const Text('Jadwal Saya', style: TextStyle(fontWeight: FontWeight.bold)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tanggal'),
                subtitle: Text(_formatTanggal(_tanggalAsal)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _loadingPrefetch ? null : _pilihTanggalAsal,
              ),
              const Text(
                'Tanggal abu-abu = tidak ada jadwal Anda di sana (atau bukan hari kerja untuk mode Pindah).',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              if (_loadingAsal)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else if (_jadwalAsal == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Tidak ada jadwal Anda di tanggal ini.',
                    style: TextStyle(color: Colors.red),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Shift: ${_jadwalAsal!.shift ?? '(Libur)'}'
                    '${_jadwalAsal!.bisaDiajukan ? '' : ' — sedang terikat pengajuan lain'}',
                    style: TextStyle(
                      color: _jadwalAsal!.bisaDiajukan ? null : Colors.orange[800],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              if (_mode == 'tukar') ...[
                const Text('Jadwal Rekan Tujuan', style: TextStyle(fontWeight: FontWeight.bold)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tanggal'),
                  subtitle: Text(_formatTanggal(_tanggalTujuan)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pilihTanggalTujuan,
                ),
                if (_loadingRekan)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  )
                else if (_rekanList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Tidak ada rekan satu unit yang punya jadwal di tanggal ini.',
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                else
                  ..._rekanList.map((rekan) => RadioListTile<int>(
                        contentPadding: EdgeInsets.zero,
                        value: rekan.jadwalId,
                        groupValue: _jadwalTujuanTerpilih?.jadwalId,
                        onChanged: rekan.bisaDiajukan
                            ? (_) => setState(() => _jadwalTujuanTerpilih = rekan)
                            : null,
                        title: Text(rekan.karyawanNama ?? '-'),
                        subtitle: Text(
                          'Shift: ${rekan.shift ?? '(Libur)'}'
                          '${rekan.bisaDiajukan ? '' : ' — sedang terikat pengajuan lain'}',
                        ),
                      )),
              ] else ...[
                const Text('Pindah ke Tanggal', style: TextStyle(fontWeight: FontWeight.bold)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tanggal Baru'),
                  subtitle: Text(_formatTanggal(_tanggalBaru)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _loadingPrefetch ? null : _pilihTanggalBaru,
                ),
                const Text(
                  'Hanya tanggal libur Anda yang bisa dipilih (abu-abu = bukan hari libur Anda).',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],

              const SizedBox(height: 16),
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