import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/jadwal_model.dart';
import '../../services/jadwal_service.dart';
import '../tukar_jadwal/tukar_jadwal_form_screen.dart';

(String, Color) _jenisDisplay(String jenis) {
  switch (jenis) {
    case 'reguler':
      return ('Kerja', const Color(0xFF1D9E75));
    case 'piket':
      return ('Piket (Kerja)', const Color(0xFF1D9E75));
    case 'libur':
      return ('Libur', const Color(0xFF9E9E9E));
    case 'cuti':
      return ('Cuti', const Color(0xFFF57C00));
    case 'dinas':
      return ('Dinas', const Color(0xFF7B1FA2));
    default:
      return (jenis, const Color(0xFF9E9E9E));
  }
}

// Backend mengirim tanggal 'd M Y' (contoh "15 Oct 2026", nama bulan
// Inggris). Dikunci locale en_US di sini -- jangan bergantung locale
// default device, yang sekarang id_ID (lihat main.dart).
DateTime? _parseTanggal(String tanggal) {
  try {
    return DateFormat('d MMM yyyy', 'en_US').parse(tanggal);
  } catch (_) {
    return null;
  }
}

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  final _service = JadwalService();

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;
  bool _gagal = false;
  Map<DateTime, JadwalItem> _jadwalPerHari = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _key(DateTime.now());
    _loadBulan(_focusedMonth);
  }

  DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _loadBulan(DateTime bulan) async {
    setState(() {
      _loading = true;
      _gagal = false;
    });

    final awal = DateTime(bulan.year, bulan.month, 1);
    final akhir = DateTime(bulan.year, bulan.month + 1, 0);
    final format = DateFormat('yyyy-MM-dd');

    try {
      final items = await _service
          .sayaDalamRentangOrThrow(format.format(awal), format.format(akhir))
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      final perHari = <DateTime, JadwalItem>{};
      for (final item in items) {
        final tgl = _parseTanggal(item.tanggal);
        if (tgl != null) perHari[_key(tgl)] = item;
      }

      setState(() {
        _jadwalPerHari = perHari;
        _loading = false;
      });
    } catch (e) {
      // Menangkap ApiException (response sukses tapi success:false) MAUPUN
      // error jaringan level socket (SocketException/TimeoutException saat
      // WiFi/data mati total) -- keduanya harus berhenti nge-load, bukan
      // cuma ApiException.
      if (!mounted) return;
      setState(() {
        _jadwalPerHari = {};
        _loading = false;
        _gagal = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedDay != null ? _jadwalPerHari[_selectedDay] : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal')),
      body: RefreshIndicator(
        onRefresh: () => _loadBulan(_focusedMonth),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 4),
            TableCalendar<JadwalItem>(
              locale: 'id_ID',
              firstDay: DateTime(2025, 1, 1),
              lastDay: DateTime(2030, 12, 31),
              focusedDay: _focusedMonth,
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              selectedDayPredicate: (day) =>
                  _selectedDay != null && isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = _key(selectedDay);
                  _focusedMonth = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedMonth = focusedDay;
                _loadBulan(focusedDay);
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, _) => _buildDayCell(context, day),
                todayBuilder: (context, day, _) =>
                    _buildDayCell(context, day, isToday: true),
                selectedBuilder: (context, day, _) =>
                    _buildDayCell(context, day, isSelected: true),
                outsideBuilder: (context, day, _) =>
                    _buildDayCell(context, day, isOutside: true),
              ),
            ),
            const SizedBox(height: 16),
            const _Legenda(),
            const SizedBox(height: 16),
            if (_gagal)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Gagal memuat jadwal bulan ini.')),
                      TextButton(
                        onPressed: () => _loadBulan(_focusedMonth),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
            else if (selected != null)
            _DetailCard(
              tanggal: _selectedDay!,
              item: selected,
              onAjukan: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TukarJadwalFormScreen(tanggalAwal: _selectedDay),
                  ),
                );
                _loadBulan(_focusedMonth);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day, {
    bool isToday = false,
    bool isSelected = false,
    bool isOutside = false,
  }) {
    final item = _jadwalPerHari[_key(day)];
    final warna = item != null ? _jenisDisplay(item.jenis).$2 : null;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : warna?.withValues(alpha: 0.18),
        border: isToday && !isSelected
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
            : null,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: isSelected ? Colors.white : (isOutside ? Colors.grey[400] : null),
              fontWeight: isToday ? FontWeight.bold : null,
            ),
          ),
          if (item != null)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : warna,
              ),
            ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda();

  @override
  Widget build(BuildContext context) {
    const jenisList = ['reguler', 'libur', 'cuti', 'dinas'];
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: jenisList.map((jenis) {
        final (label, warna) = _jenisDisplay(jenis);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: warna),
            ),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final DateTime tanggal;
  final JadwalItem item;
  final VoidCallback onAjukan;
  const _DetailCard({required this.tanggal, required this.item, required this.onAjukan});

  @override
  Widget build(BuildContext context) {
    final (label, warna) = _jenisDisplay(item.jenis);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: warna),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.tanggal, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(label, style: TextStyle(color: warna, fontWeight: FontWeight.w600)),
                      if (item.shift != null) Text('Shift: ${item.shift}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAjukan,
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Ajukan Tukar/Pindah'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}