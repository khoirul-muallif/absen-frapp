# TODO — absensi_frontapp

> Isi aktif aja — kalau item selesai, hapus (bukan di-checklist doang),
> biar file ini tetep pendek dan gampang di-scan. Detail histori lengkap
> tetap di CHANGELOG-fr.md.

## Belum dibuat

      
- [ ] **Sembunyikan baris email kosong di layar profil** — backend fase 81
      membuat `karyawan.email` nullable (~110 dari 150 karyawan RS tidak
      punya email). KOREKSI 10 Nov 2026: kekhawatiran parsing melempar
      TIDAK terbukti — `UserModel.fromJson()` sudah pakai
      `json['email'] ?? ''` sejak awal, jadi null jadi string kosong dan
      tidak ada yang crash.

      Yang tersisa cuma tampilan: `Text(user.email)` jadi baris kosong,
      dan ListTile dengan ikon amplop jadi ikon tanpa nilai. Sembunyikan
      barisnya kalau kosong. Tidak mendesak, tidak memblokir deploy.

- [ ] **Sisa kuota Cuti kurang TIDAK memblokir submit, tapi warnanya
      merah seperti bentrok yang memblokir** — dua peringatan terlihat
      sama padahal akibatnya beda. Kalau bentroknya dihapus, tombol
      Ajukan hidup lagi meski kuota kurang, dan backend yang menolak.
      Usul termurah: peringatan kuota jadi oranye, bentrok tetap merah.
      Dicatat 24 Nov 2026.

      KOREKSI untuk arsip: item lama di sini mengusulkan mencegah lewat
      `selectableDayPredicate` seperti di TukarJadwal. Itu TIDAK BISA —
      `showDateRangePicker` tidak punya parameter itu, hanya
      `showDatePicker` yang punya. Gantinya `lastDate` dijepit (lintas
      tahun & semester) dan peringatan di form (bentrok approved).
      Ditutup `7096007` dan `69c64ec`.
      


- [ ] **Redesign visual Beranda** — struktur navigasi sudah final (bottom
      nav 3 tab), tapi gaya visual masih default Material. Referensi dari
      aplikasi lama: kartu profil dengan latar melengkung, ikon menu bulat
      berwarna per kategori, ring chart kehadiran, tombol Presensi di
      tengah bottom nav. Dikerjakan setelah audit UX per-modul selesai
      biar nggak nabrak perubahan struktural. Dicatat 5 Nov 2026.

- [ ] **Telusur/audit UX frontend secara menyeluruh** — review semua
      screen (bukan per-modul kayak sesi-sesi sebelumnya) buat nyari
      pola yang kurang ramah pengguna: copy/pesan yang masih teknis atau
      kurang jelas, alur yang bisa dipangkas/disederhanakan. Konsistensi
      section Card sudah selesai 23 Nov 2026 — `SectionCard` dipakai di
      kelima form (TukarJadwal, Izin, Lembur, Cuti, Dinas). Masih
      rencana, belum ada scope/checklist konkret — perlu sesi tersendiri
      buat nentuin cakupannya (semua modul sekaligus, atau satu-satu
      kayak pola review Filament Resource di backend fase 25-36).
      Dicatat 4 Nov 2026.

## Perlu investigasi sebelum dikerjakan

*(kosong — tapi catat: klaim lama "semua tanggal lewat sudah dicegah di
sumbernya sejak `4ebe805`" TIDAK benar. Cuti dan Dinas masih
`firstDate: now.subtract(7 days)` sampai 23 Nov 2026, padahal backend
memvalidasi `after_or_equal:today` — tanggal lewat bisa dipilih dan baru
ditolak setelah submit. Ditutup `9806a54` dan `82ba1f7`. Pelajaran: klaim
"sudah dicegah di semua modul" perlu diperiksa per modul, bukan
diasumsikan merata.)*

## Keputusan yang menggantung (butuh jawaban Khoirul)


- [ ] **Menu "Gaji" & "Piket"** — muncul di referensi UI yang dikirim
      15 Okt 2026, tapi gak ada endpoint-nya di backend sekarang. Scope
      masa depan, atau referensi dari app lain yang beda modul?


## Belum ditest end-to-end

*(kosong — TukarJadwal, Cuti, Lembur, Dinas, Izin semua sudah tervalidasi
end-to-end per 26 Okt 2026)*

## Technical debt

*(kosong)*

## Catatan konvensi FE (biar gak keulang)

- Riwayat dua tab saja: Presensi + Tukar Jadwal. Izin, Cuti, Dinas,
  Lembur SENGAJA tidak ikut — tetap di layar terpisah lewat grid Beranda
  (keputusan 20 Nov 2026, menjawab usulan referensi UI yang menggabungkan
  semuanya jadi satu layar bertab).

- Notifikasi: empat nilai `tipe` dari backend — `terlambat`,
  `belum_absen_masuk`, `belum_absen_pulang`, `tukar_jadwal` (dikunci
  `KontrakNotifikasiTest` di backend, fase 85). Ketujuh notifikasi
  TukarJadwal memakai `tipe` yang SAMA; yang membedakan `aksi`:
  `diajukan`, `disetujui_rekan`, `ditolak_rekan`, `approved`,
  `rejected`, `dibatalkan_admin`, `dibatalkan_pengaju`. Kalau ikon atau
  warna mau dibedakan per kejadian, pakai `aksi`, bukan `tipe`.

  `aksi` TIDAK diratakan ke akar response — `NotifikasiController` cuma
  mengangkat `judul`, `pesan`, `tipe`. Sisanya di dalam `data`, yang
  dikirim utuh. Baca lewat `json['data']?['aksi']`.

  Untuk `aksi: 'dibatalkan_pengaju'`, baris TukarJadwal-nya sudah
  DIHAPUS backend dan `tukar_jadwal_id` menunjuk id yang tidak ada lagi
  (keputusan 9 Nov 2026: id tetap dikirim demi konsistensi bentuk
  `data`). Getter `NotifikasiItem.detailSudahTidakAda` menandainya.

- TukarJadwal mode Tukar: tanggal tujuan SENGAJA dikunci sama dengan
  tanggal asal (bukan keterbatasan backend — backend mendukung beda
  tanggal kalau salah satu sisi libur, lihat CHANGELOG backend fase
  71-73). Keputusan produk: FE tidak menawarkan opsi beda tanggal
  supaya user nggak kena kejutan submit gagal karena validasi silang
  (pengaju/tujuan bentrok shift kerja sendiri di tanggal pasangan).
  User diarahkan hubungi admin kalau butuh tukar beda tanggal.

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
- Status Absensi dari backend cuma tujuh nilai: `tepat_waktu`,
  `terlambat`, `alpha`, `izin`, `cuti`, `dinas`, `libur` (enum kolom
  `absensi.status`, default `alpha`). TIDAK ADA `'sakit'` — case-nya
  sempat ada di `statusDisplay()` dan tidak pernah terpanggil, dibuang
  23 Nov 2026. `alpha` ditampilkan sebagai "Tidak Hadir" di semua tempat.
- Form pakai `SectionCard` dari `lib/widgets/section_card.dart` (diangkat
  dari TukarJadwalFormScreen 23 Nov 2026). Jangan bikin section Card
  sendiri per layar lagi.
- Field non-teks yang wajib (jam, rentang tanggal, lampiran) divalidasi
  lewat `FormField<T>` dengan `state.didChange()` setelah picker ditutup,
  BUKAN pengecekan manual di `_submit()` yang melempar snackbar.
  Errornya muncul di bawah fieldnya, sejajar dengan TextFormField.
- `initialTime` pada `showTimePicker` selalu pakai nilai yang sudah
  dipilih (`_jam ?? TimeOfDay.now()`), jangan selalu `TimeOfDay.now()`.
- Identitas instansi (nama + logo) disimpan lokal lewat `InstansiStorage`
  setelah login, SENGAJA tidak dibersihkan saat logout. Itu satu-satunya
  cara LoginScreen dan SplashScreen tahu instansi mana sebelum ada yang
  login. Jangan tambahkan ke `AuthService.logout()`.
- Logo instansi selalu lewat `LogoInstansi` (`lib/widgets/logo_instansi.dart`),
  yang jatuh ke placeholder untuk tiga keadaan wajar: belum pernah login,
  instansi belum mengunggah logo, dan URL gagal dimuat.