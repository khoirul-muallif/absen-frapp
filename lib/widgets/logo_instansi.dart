import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Logo instansi dengan placeholder. Dipakai di Splash, Login, dan
/// kartu profil Beranda.
///
/// Placeholder-nya bukan sekadar isian: instalasi baru belum pernah
/// login, jadi logo memang belum ada — dan instansi boleh saja tidak
/// mengunggah logo sama sekali.
class LogoInstansi extends StatelessWidget {
  final String? url;
  final double ukuran;

  const LogoInstansi({super.key, required this.url, this.ukuran = 88});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _placeholder();

    return ClipOval(
      child: Image.network(
        url!,
        width: ukuran,
        height: ukuran,
        fit: BoxFit.cover,
        // URL bisa menunjuk file yang sudah dihapus admin, atau server
        // sedang tidak terjangkau. Jangan tampilkan ikon rusak.
        errorBuilder: (_, _, _) => _placeholder(),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.local_hospital_outlined,
        size: ukuran / 2,
        color: Colors.white,
      ),
    );
  }
}