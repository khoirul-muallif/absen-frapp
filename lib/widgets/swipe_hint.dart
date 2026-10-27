import 'package:flutter/material.dart';

/// Hint visual kecil di bawah item yang bisa di-swipe untuk dibatalkan.
/// Dipakai di semua modul approval (Izin/Lembur/Dinas/Cuti/TukarJadwal)
/// supaya user tahu item itu bisa digeser, bukan cuma ditebak.
class SwipeHint extends StatelessWidget {
  const SwipeHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Geser untuk batalkan',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(width: 4),
          Icon(Icons.swipe_left_alt_outlined, size: 14, color: Colors.grey[500]),
        ],
      ),
    );
  }
}