# TODO — absensi_frontapp

> Isi aktif aja — kalau item selesai, hapus (bukan di-checklist doang),
> biar file ini tetep pendek dan gampang di-scan. Detail histori lengkap
> tetap di CHANGELOG-fr.md.

## Bug aktif

- [ ] **Tombol "Absen" di Home auto-routing diam-diam, bikin salah niat
      ketukar** — `onTap` tombol Absen manggil `getStatus()` terus nebak
      sendiri mau diarahkan ke flow masuk atau pulang, tanpa user pernah
      eksplisit milih. Dua kejadian nyata (27 Okt 2026):
      1. Udah absen masuk pagi, buka app lagi jam 9 cuma buat cek/iseng
         → otomatis didorong ke flow PULANG (karena logic "udah masuk,
         belum pulang" match), padahal gak niat pulang beneran.
      2. Lupa absen pulang kemarin (sesi masih terbuka) → pagi ini niat
         absen masuk hari baru, malah kedetek sebagai pulang sesi
         kemarin. (Catatan: ini SEBENERNYA sesuai desain backend fase 57
         — shift malam masuk T pulang T+1 harus kedetek gini — tapi buat
         kasus "beneran lupa", user gak py jalan buat bilang "ini masuk
         baru, bukan nerusin kemarin".)

      Rencana fix: pisah jadi 2 tombol eksplisit di Home — "Absen Masuk"
      & "Absen Pulang" — masing-masing langsung ke flow-nya sendiri
      tanpa nebak client-side. Backend udah punya guard yang benar
      (`masuk()` nolak kalau sesi kemarin masih terbuka, `pulang()` cari
      jendela 2 hari) — client tinggal nampilin pesan errornya apa
      adanya (pakai `showAppSnackBar` yang udah ada) kalau ditolak,
      bukan nyoba nebak duluan.

## Belum dibuat

- [ ] **Layar "Jadwal"** (kalender + detail jadwal per tanggal) — belum
      ada sama sekali di frontend, dan referensi UI nunjukkin ini jadi
      titik masuk buat form Tukar Jadwal juga.
- [ ] **Deteksi wajah otomatis via gesture** — sekarang foto wajah
      (absen masuk/pulang) masih manual pencet tombol capture. Rencana
      ke depan: auto-trigger begitu sistem deteksi gesture tertentu
      (mirip liveness detection), bukan capture sekali jepret manual.
      Perlu `google_mlkit_face_detection` dipakai streaming dari kamera
      (bukan sekali capture seperti sekarang) — perubahan besar,
      scope sesi tersendiri. Dicatat 27 Okt 2026, belum ada desain
      konkret.

## Keputusan yang menggantung (butuh jawaban Khoirul)

- [ ] **Menu "Gaji" & "Piket"** — muncul di referensi UI yang dikirim
      15 Okt 2026, tapi gak ada endpoint-nya di backend sekarang. Scope
      masa depan, atau referensi dari app lain yang beda modul?
- [ ] **Struktur layar Riwayat** — referensi UI gabung Presensi/Izin/Cuti
      dkk jadi 1 screen pakai tab, beda dari struktur sekarang (tiap modul
      screen terpisah, diakses dari grid home). Diikutin atau tetap kayak
      sekarang?

## Belum ditest end-to-end

*(kosong — TukarJadwal, Cuti, Lembur, Dinas, Izin semua sudah tervalidasi
end-to-end per 26 Okt 2026)*

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
- Tanggal dari `DinasController`/`CutiController` dikirim format `'d M Y'`
  (mis. "15 Oct 2026"), bukan ISO — aman ditampilkan mentah tanpa parsing,
  tapi jangan dicoba di-parse jadi `DateTime`.
- `lib/screens/<modul>/<file>.dart` (izin/, lembur/, dinas/, cuti/,
  tukar_jadwal/) semuanya nested 1 level lebih dalam dari
  `lib/screens/` — butuh `../../` buat reach `lib/widgets/`, `lib/theme/`,
  `lib/services/`, dkk, BUKAN `../`. `home_screen.dart` beda, langsung
  di `lib/screens/`, jadi tetap `../`.
- Notifikasi SnackBar pakai `showAppSnackBar(context, message, type: ...)`
  dari `lib/utils/snackbar_helper.dart` — JANGAN balik pakai
  `ScaffoldMessenger.of(context).showSnackBar()` langsung lagi. `type`
  default `info` (netral), pakai `.error` buat pesan gagal/validasi,
  `.success` buat pesan sukses eksplisit.