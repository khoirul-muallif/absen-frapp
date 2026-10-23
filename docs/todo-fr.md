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
- [ ] **Menu "Gaji" & "Piket"** — muncul di referensi UI yang dikirim
      15 Okt 2026, tapi gak ada endpoint-nya di backend sekarang. Scope
      masa depan, atau referensi dari app lain yang beda modul?
- [ ] **Struktur layar Riwayat** — referensi UI gabung Presensi/Izin/Cuti
      dkk jadi 1 screen pakai tab, beda dari struktur sekarang (tiap modul
      screen terpisah, diakses dari grid home). Diikutin atau tetap kayak
      sekarang?
- [ ] **Konfirmasi pembagian semester `JenisCuti::semesterDari()`** —
      filter dropdown Cuti di `cuti_form_screen.dart` (fase 16, fix bug
      dropdown nampilin 2 semester sekaligus) masih ASUMSI semester
      1=Jan-Jun, 2=Jul-Des. Perlu dicek ke kode backend aslinya biar gak
      meleset di bulan-bulan tertentu.

## Belum dibuat

- [ ] **Layar "Jadwal"** (kalender + detail jadwal per tanggal) — belum
      ada sama sekali di frontend, dan referensi UI nunjukkin ini jadi
      titik masuk buat form Tukar Jadwal juga (lihat catatan di atas)
- [ ] **Swipe-to-delete gak ada hint visual di semua modul** — Izin/Lembur/
      Dinas/Cuti/TukarJadwal semua pakai Dismissible buat batalkan, tapi
      gak ada indikasi apapun ke user kalau item bisa di-swipe. Ditemukan
      saat testing Lembur (16 Okt 2026). Perlu tambahan hint (ikon panah,
      teks kecil "Geser untuk batalkan", atau ganti ke tombol eksplisit).
- [ ] **Opsi mode TukarJadwalFormScreen untuk karyawan umum** — form
      sekarang selalu nawarin "Tukar dengan Rekan" & "Pindah Tanggal"
      buat semua karyawan. Perlu dibatasi: karyawan tipe umum cuma
      ditampilkan opsi "Pindah Tanggal" (sembunyikan Tukar). Alasan/
      cakupannya belum dipastikan — konfirmasi dulu sebelum
      dikerjakan.


## Belum ditest end-to-end

- [ ] **TukarJadwal** (fase 15, partial) — Riwayat & Menunggu Respon Saya
      sudah dicoba, gak crash walau kosong. `responRekan`/`batalkan`
      BELUM bisa ditest karena belum ada data TukarJadwal sama sekali
      (belum ada form ajukan, belum ada cara seed manual). Perlu seed
      data dummy (Tinker/Postman) 2 karyawan buat lanjut test ini.

## Technical debt

- [ ] **Multipart upload duplikat di 2 tempat** — `_absenMultipart` di
      `absensi_service.dart` dan `CutiService.ajukan()` di
      `cuti_service.dart` sama-sama nulis `http.MultipartRequest` manual
      sendiri-sendiri karena `ApiClient` belum support file upload. Belum
      dirapikan jadi 1 helper bersama.

## Catatan konvensi FE (biar gak keulang)

- Field jam dari backend untuk Izin (`jam_keluar`/`jam_kembali`) dan
  Lembur (`jam_mulai`/`jam_selesai`) dikirim RAW `"08:00:00"`, bukan
  `H:i`. Potong string, jangan coba parse sebagai Carbon/DateTime.
- Lembur SEKARANG bisa lintas tengah malam di backend (fix fase 59,
  commit `5dbbaa3`/`27b56d0` repo `absensi-app`) — validasi lama
  (`after:jam_mulai`) sudah diganti jadi cuma menolak durasi nol.
  FE masih ikut validasi lama yang salah (lihat item "Revert validasi
  client-side Lembur lintas tengah malam" di atas) — belum direvert.
- Tanggal dari `DinasController`/`CutiController` dikirim format `'d M Y'`
  (mis. "15 Oct 2026"), bukan ISO — aman ditampilkan mentah tanpa parsing,
  tapi jangan dicoba di-parse jadi `DateTime`.
- `lib/screens/<modul>/<file>.dart` (izin/, lembur/, dinas/, cuti/,
  tukar_jadwal/) semuanya nested 1 level lebih dalam dari
  `lib/screens/` — butuh `../../` buat reach `lib/widgets/`, `lib/theme/`,
  `lib/services/`, dkk, BUKAN `../`. `home_screen.dart` beda, langsung
  di `lib/screens/`, jadi tetap `../`.