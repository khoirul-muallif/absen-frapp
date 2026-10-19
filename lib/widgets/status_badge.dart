// lib/widgets/status_badge.dart
import 'package:flutter/material.dart';

/// Status mentah dari backend (pending/approved/rejected/menunggu_rekan/
/// menunggu_admin/ditolak_rekan) dipetakan ke label Indonesia + warna,
/// dipakai sama di semua modul (Izin/Lembur/Dinas/Cuti/TukarJadwal).
(String, Color) statusDisplay(String status) {
  switch (status) {
    case 'pending':
      return ('Menunggu', Colors.grey.shade700);
    case 'approved':
      return ('Disetujui', Colors.green.shade700);
    case 'rejected':
      return ('Ditolak', Colors.red.shade700);
    case 'menunggu_rekan':
      return ('Menunggu Rekan', Colors.orange.shade800);
    case 'menunggu_admin':
      return ('Menunggu Admin', Colors.grey.shade700);
    case 'ditolak_rekan':
      return ('Ditolak Rekan', Colors.red.shade700);
    // lib/theme/status_badge.dart — tambahin case ini ke statusDisplay(),
    // di ATAS baris `default:` yang sudah ada
    case 'tepat_waktu':
      return ('Tepat Waktu', Colors.green.shade700);
    case 'terlambat':
      return ('Terlambat', Colors.orange.shade800);
    case 'alpha':
      return ('Alpha', Colors.red.shade700);
    case 'sakit':
    case 'izin':
    case 'cuti':
      return (status == 'sakit' ? 'Sakit' : status == 'izin' ? 'Izin' : 'Cuti', Colors.blue.shade700);
    case 'dinas':
      return ('Dinas', Colors.blue.shade700);
    case 'libur':
      return ('Libur', Colors.grey.shade700);
    default:
      return (status, Colors.grey.shade700);
  }
}

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = statusDisplay(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}