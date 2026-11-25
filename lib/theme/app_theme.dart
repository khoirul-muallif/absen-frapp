// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Warna utama disamakan dengan primary color Filament admin panel
/// (PROJECT_CONTEXT.md: teal #1D9E75) biar konsisten antara app mobile
/// dan admin panel.
class AppColors {
  static const primary = Color(0xFF1D9E75);
  static const background = Color(0xFFF4F5F4);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    // Hijau solid di semua layar. Sebelumnya transparan dengan teks
    // gelap, jadi tiap layar terlihat seperti kertas abu-abu polos —
    // dan setelah Beranda didesain ulang 25 Nov, Beranda jadi satu-
    // satunya yang berwarna.
    //
    // Beranda menimpa ini sendiri (transparan di atas latar hijau
    // melengkung), jadi tidak terganggu.
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      // Ikon status bar jadi terang, karena latarnya sekarang gelap.
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
        // TabBar berada DI DALAM AppBar (RiwayatScreen), jadi latarnya
    // hijau — tapi foregroundColor AppBar tidak diturunkan ke sini.
    // Tanpa ini label tabnya abu-abu gelap di atas hijau, nyaris
    // tidak terbaca.
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorSize: TabBarIndicatorSize.label,
      indicatorColor: Colors.white,
      dividerColor: Colors.transparent,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        // M3 default ElevatedButton = latar surfaceContainerLow + teks
        // primary, yang dengan seed hijau ini terlihat seperti tombol
        // NONAKTIF. Tombol utama harus solid.
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
        disabledForegroundColor: Colors.white70,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}