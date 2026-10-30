# TODO — absensi_frontapp

> Isi aktif aja — kalau item selesai, hapus (bukan di-checklist doang),
> biar file ini tetep pendek dan gampang di-scan. Detail histori lengkap
> tetap di CHANGELOG-fr.md.

## Belum dibuat

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
- Tanggal dari `DinasController`/`CutiController`/`JadwalController`
  dikirim format `'d M Y'` (mis. "15 Oct 2026"), bukan ISO — aman
  ditampilkan mentah tanpa parsing. Kalau butuh di-parse jadi `DateTime`
  (mis. buat key kalender di `JadwalScreen`), kunci locale eksplisit ke
  `en_US` di parser-nya (`DateFormat('d MMM yyyy', 'en_US')`) — jangan
  bergantung locale default device (`id_ID`), nama bulan Inggris gak
  bakal cocok kalau device-nya Indonesia.
- `lib/screens/<modul>/<file>.dart` (izin/, lembur/, dinas/, cuti/,
  tukar_jadwal/, jadwal/) semuanya nested 1 level lebih dalam dari
  `lib/screens/` — butuh `../../` buat reach `lib/widgets/`, `lib/theme/`,
  `lib/services/`, dkk, BUKAN `../`. `home_screen.dart` beda, langsung
  di `lib/screens/`, jadi tetap `../`.
- Notifikasi SnackBar pakai `showAppSnackBar(context, message, type: ...)`
  dari `lib/utils/snackbar_helper.dart` — JANGAN balik pakai
  `ScaffoldMessenger.of(context).showSnackBar()` langsung lagi. `type`
  default `info` (netral), pakai `.error` buat pesan gagal/validasi,
  `.success` buat pesan sukses eksplisit.