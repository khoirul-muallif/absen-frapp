# TODO — absensi_frontapp

> Isi aktif aja — kalau item selesai, hapus (bukan di-checklist doang),
> biar file ini tetep pendek dan gampang di-scan. Detail histori lengkap
> tetap di CHANGELOG-fr.md.

## Keputusan yang menggantung (butuh jawaban Khoirul)

- [ ] **Feedback error/sukses pakai SnackBar dirasa kurang user friendly**
      — semua modul (Izin/Lembur/Dinas/Cuti/TukarJadwal) pakai
      `ScaffoldMessenger.showSnackBar()` buat nampilin pesan sukses/gagal
      dari server. Diusulkan ganti ke popup (AlertDialog) biar lebih
      kelihatan. Perlu diputuskan: popup buat SEMUA pesan, atau cuma
      error yang penting (SnackBar tetap dipakai buat konfirmasi ringan
      kayak "berhasil dibatalkan")? Ditemukan saat testing 16 Okt 2026.

- [ ] **Scope `GET /api/jadwal/rekan`** — blocker `TukarJadwalFormScreen`.
      Dibatasi unit_kerja sama, instansi sama, atau gak dibatasi? Endpoint
      ini (+ `GET /api/jadwal/saya`) juga belum ada di backend, sudah
      dicatat di `todo.md` repo `absensi-app` (commit `fc450ce`).
- [ ] **Menu "Gaji" & "Piket"** — muncul di referensi UI yang dikirim
      15 Okt 2026, tapi gak ada endpoint-nya di backend sekarang. Scope
      masa depan, atau referensi dari app lain yang beda modul?
- [ ] **Struktur layar Riwayat** — referensi UI gabung Presensi/Izin/Cuti
      dkk jadi 1 screen pakai tab, beda dari struktur sekarang (tiap modul
      screen terpisah, diakses dari grid home). Diikutin atau tetap kayak
      sekarang?

## Belum dibuat

- [ ] **Time picker masih ikut format AM/PM dari device, harusnya 24 jam
      selalu** — `showTimePicker()` di `izin_form_screen.dart` (jam
      keluar), `izin_screen.dart` (isi jam kembali), dan
      `lembur_form_screen.dart` (jam mulai/selesai) belum dipaksa 24 jam,
      jadi ikut locale device yang bisa AM/PM. Fix: bungkus pakai
      `builder: (context, child) => MediaQuery(data:
      MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!)` di tiap pemanggilan `showTimePicker()`. Ditemukan
      saat testing 16 Okt 2026.

- [ ] **`TukarJadwalFormScreen`** (ajukan tukar/pindah baru) — blocked
      sampai keputusan scope `GET /api/jadwal/rekan` di atas
- [ ] **Layar "Jadwal"** (kalender + detail jadwal per tanggal) — belum
      ada sama sekali di frontend, dan referensi UI nunjukkin ini jadi
      titik masuk buat form Tukar Jadwal juga (lihat catatan di atas)
- [ ] **Swipe-to-delete gak ada hint visual di semua modul** — Izin/Lembur/
      Dinas/Cuti/TukarJadwal semua pakai Dismissible buat batalkan, tapi
      gak ada indikasi apapun ke user kalau item bisa di-swipe. Ditemukan
      saat testing Lembur (16 Okt 2026). Perlu tambahan hint (ikon panah,
      teks kecil "Geser untuk batalkan", atau ganti ke tombol eksplisit).

## Belum ditest end-to-end

- [ ] **Lembur** (fase 11, fix fase 13) — termasuk verifikasi format
      `diajukan_at` dan apakah auto-approved atau pending beneran
- [ ] **Dinas** (fase 12)
- [ ] **Cuti** (fase 14) — paling butuh perhatian: cek bentrok cuti/dinas,
      cek sisa kuota (termasuk pending lain), upload lampiran beneran
      nyampe ke server
- [ ] **TukarJadwal** (fase 15, partial) — riwayat, menunggu-respon-saya,
      respon rekan, batalkan

## Technical debt

- [ ] **Multipart upload duplikat di 2 tempat** — `_absenMultipart` di
      `absensi_service.dart` dan `CutiService.ajukan()` di
      `cuti_service.dart` sama-sama nulis `http.MultipartRequest` manual
      sendiri-sendiri karena `ApiClient` belum support file upload. Belum
      dirapikan jadi 1 helper bersama.
- [ ] **Styling masih default Material** di semua screen Izin/Lembur/
      Dinas/Cuti/TukarJadwal — belum disamain ke tema referensi (teal/mint,
      kartu rounded, outline badge status) yang dikirim 15 Okt 2026.

## Catatan konvensi FE (biar gak keulang)

- Field jam dari backend untuk Izin (`jam_keluar`/`jam_kembali`) dan
  Lembur (`jam_mulai`/`jam_selesai`) dikirim RAW `"08:00:00"`, bukan
  `H:i`. Potong string, jangan coba parse sebagai Carbon/DateTime.
- Lembur gak bisa lintas tengah malam di backend sekarang
  (`after:jam_mulai`), padahal ada keputusan desain lama yang bilang
  sebaliknya — FE ikut validasi backend yang berlaku, bug-nya dicatat di
  `todo.md` backend (commit `f44d43a`).
- Tanggal dari `DinasController`/`CutiController` dikirim format `'d M Y'`
  (mis. "15 Oct 2026"), bukan ISO — aman ditampilkan mentah tanpa parsing,
  tapi jangan dicoba di-parse jadi `DateTime`.