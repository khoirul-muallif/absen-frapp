import 'package:flutter/material.dart';
import '../../services/tukar_jadwal_service.dart';
import '../../services/jadwal_service.dart';
import '../../models/jadwal_model.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/snackbar_helper.dart';

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
  bool _asalValidPredicate(DateTime day) {
    final item = _jadwalSayaByTanggal[_keyTanggal(day)];
    if (item == null) return false; // gak ada Jadwal sama sekali
    if (_mode == 'pindah' && item.jenis == 'libur') return false; // pindah: asal wajib hari kerja (fase 66)
    return true;
  }

  bool _tujuanPindahValidPredicate(DateTime day) {
    final item = _jadwalSayaByTanggal[_keyTanggal(day)];
    return item != null && item.jenis == 'libur'; // tujuan pindah wajib hari libur sendiri (fase 66)
  }

  // Flutter mensyaratkan initialDate pada showDatePicker harus lolos
  // selectableDayPredicate, kalau tidak dialog gagal kebuka tanpa pesan
  // apa pun. Cari tanggal valid terdekat dari titik acuan (maju-mundur
  // bergantian) sebagai initialDate yang aman.
  DateTime? _tanggalValidTerdekat(DateTime acuan, bool Function(DateTime) predicate) {
    final firstDate = DateTime.now().subtract(const Duration(days: 30));
    final lastDate = DateTime.now().add(const Duration(days: 90));
    for (int offset = 0; offset <= 120; offset++) {
      final maju = acuan.add(Duration(days: offset));
      if (!maju.isAfter(lastDate) && predicate(maju)) return maju;
      final mundur = acuan.subtract(Duration(days: offset));
      if (!mundur.isBefore(firstDate) && predicate(mundur)) return mundur;
    }
    return null;
  }
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
    // Karyawan umum shift-nya tetap (assignment periode KaryawanShift),
    // jadi "tukar" dengan rekan satu tim cuma dapat tanggal & jam yang
    // sama persis -- gak masuk akal. Cuma rotasi yang ditawari mode tukar.
    final tipeJadwal = context.read<AuthProvider>().user?.tipeJadwal;
    if (tipeJadwal == 'umum') {
      _mode = 'pindah';
    }
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
    final initial = _asalValidPredicate(_tanggalAsal)
        ? _tanggalAsal
        : _tanggalValidTerdekat(_tanggalAsal, _asalValidPredicate);
    if (initial == null) {
      showAppSnackBar(
        context,
        _mode == 'pindah'
            ? 'Tidak ada jadwal hari kerja Anda dalam 30 hari lalu - 90 hari ke depan'
            : 'Tidak ada jadwal Anda dalam 30 hari lalu - 90 hari ke depan',
        type: AppSnackBarType.error,
      );
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      selectableDayPredicate: _asalValidPredicate,
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

  Future<void> _bukaPilihRekan() async {
    final dipilih = await showModalBottomSheet<JadwalItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scrollController) => RadioGroup<int>(
          groupValue: _jadwalTujuanTerpilih?.jadwalId,
          onChanged: (value) {
            final rekan = _rekanList.firstWhere((r) => r.jadwalId == value);
            Navigator.pop(context, rekan);
          },
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Pilih Rekan Tujuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ..._rekanList.map((rekan) => RadioListTile<int>(
                    value: rekan.jadwalId,
                    toggleable: false,
                    title: Text(rekan.karyawanNama ?? '-'),
                    subtitle: Text(
                      'Shift: ${rekan.shift ?? '(Libur)'}'
                      '${rekan.bisaDiajukan ? '' : ' — sedang terikat pengajuan lain'}',
                    ),
                    enabled: rekan.bisaDiajukan,
                  )),
            ],
          ),
        ),
      ),
    );
    if (dipilih != null) setState(() => _jadwalTujuanTerpilih = dipilih);
  }

  Future<void> _pilihTanggalBaru() async {
    final initial = _tujuanPindahValidPredicate(_tanggalBaru)
        ? _tanggalBaru
        : _tanggalValidTerdekat(_tanggalBaru, _tujuanPindahValidPredicate);
    if (initial == null) {
      showAppSnackBar(
        context,
        'Tidak ada tanggal libur Anda yang bisa dipilih dalam 30 hari lalu - 90 hari ke depan',
        type: AppSnackBarType.error,
      );
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      selectableDayPredicate: _tujuanPindahValidPredicate,
    );
    if (picked != null) setState(() => _tanggalBaru = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_jadwalAsal == null) {
      showAppSnackBar(context, 'Tidak ada jadwal Anda di tanggal ini, pilih tanggal lain', type: AppSnackBarType.error);
      return;
    }
    if (!_jadwalAsal!.bisaDiajukan) {
      showAppSnackBar(context, 'Jadwal ini sedang terikat pengajuan tukar jadwal lain', type: AppSnackBarType.error);
      return;
    }

    int? jadwalTujuanId;
    String? tanggalBaru;

    if (_mode == 'tukar') {
      if (_jadwalTujuanTerpilih == null) {
        showAppSnackBar(context, 'Pilih jadwal rekan tujuan dulu', type: AppSnackBarType.error);
        return;
      }
      if (!_jadwalTujuanTerpilih!.bisaDiajukan) {
        showAppSnackBar(context, 'Jadwal rekan ini sedang terikat pengajuan lain', type: AppSnackBarType.error);
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
      showAppSnackBar(context, result['message'] ?? 'Gagal mengajukan', type: AppSnackBarType.error);
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
              Builder(builder: (context) {
                final tipeJadwal = context.watch<AuthProvider>().user?.tipeJadwal;
                final bisaTukar = tipeJadwal != 'umum';

                if (!bisaTukar) {
                  // Karyawan umum: cuma mode Pindah, segmented button gak
                  // perlu ditampilkan sama sekali (bukan ditampilkan lalu
                  // di-disable -- opsi yang gak pernah relevan buat tipe
                  // ini mending gak usah dilihat).
                  return const Text(
                    'Pindah Tanggal',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  );
                }

                return SegmentedButton<String>(
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
                );
              }),
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
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  tileColor: Colors.grey.shade100,
                  title: Text(_jadwalTujuanTerpilih == null
                      ? 'Pilih rekan tujuan'
                      : _jadwalTujuanTerpilih!.karyawanNama ?? '-'),
                  subtitle: _jadwalTujuanTerpilih != null
                      ? Text('Shift: ${_jadwalTujuanTerpilih!.shift ?? '(Libur)'}')
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: (_loadingRekan || _rekanList.isEmpty) ? null : _bukaPilihRekan,
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
                  ),
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