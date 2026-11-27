# TODO — absensi_frontapp

> Isi aktif aja — kalau item selesai, hapus (bukan di-checklist doang),
> biar file ini tetep pendek dan gampang di-scan. Detail histori lengkap
> tetap di CHANGELOG-fr.md.

## Belum dibuat

- [ ] **Libur nasional tidak dibedakan di kalender Jadwal** — backend
      fase 95 (27 Nov) menambahkan `jadwals.libur_nasional`, tapi
      JadwalScreen cuma membaca `jenis`, jadi 17 Agustus dan hari Minggu
      terlihat sama persis. Pola yang sama dengan `piket` yang dulu
      sewarna dengan reguler (ditutup 25 Nov).

      PERIKSA DULU: apakah `JadwalController` sudah mengirim kolomnya?
      Kemungkinan belum — kolomnya baru dibuat untuk keperluan
      generator, bukan untuk API. Kalau belum, ini dua langkah:
      backend mengirim, FE memakai.

      Belum tentu perlu: karyawan mungkin tidak peduli ALASAN liburnya,
      cuma peduli dia libur. Yang jelas butuh pembedaan ini TukarJadwal
      (lihat item berikutnya), bukan kalender.

      Dicatat 27 Nov 2026.
           
## Audit UX menyeluruh — dikerjakan per DIMENSI, bukan per layar

Dimulai 25 Nov 2026. Pendekatannya sengaja beda dari review per-modul
sebelumnya: periksa SATU hal di semua layar sekaligus. Alasannya pola
yang berulang di sepuluh layar kalau diaudit per layar akan ditemukan
sepuluh kali sebagai sepuluh temuan terpisah.

Lima dimensi, dan satu dimensi per sesi — menggarap beberapa sekaligus
berarti perubahan besar di belasan file, dan itu persis keadaan yang
bikin kesalahan sulit dilacak.

### 1. Aksi destruktif — SELESAI 25 Nov (`592d3b4`, `428a453`)

Enam tempat sekarang punya konfirmasi lewat `konfirmasi()` di
`lib/widgets/dialog_konfirmasi.dart`.

Pelajaran yang jangan terulang: kata di dua tombol tidak boleh
serumpun. Versi pertama berbunyi "Batal" / "Batalkan" — dua kata nyaris
sama untuk aksi yang berlawanan. Sekarang "Tidak" / "Hapus Pengajuan".

Submit pengajuan SENGAJA tidak dikonfirmasi: masih bisa dibatalkan
selama belum diproses, dan dialog di tiap submit cuma menambah ketukan
yang lama-lama ditekan tanpa dibaca.

### 2. Keadaan kosong, gagal, dan memuat — SELESAI 25 Nov (`e42b418`, `5e69ecb`)

Kartu gagal sebelumnya disalin ke enam layar dengan LIMA bentuk berbeda.
Diangkat jadi `KartuError` + `KartuKosong` di
`lib/widgets/kartu_error.dart`, memakai bentuk milik RiwayatScreen —
satu-satunya yang warnanya dari tema, bukan `Colors.red` hardcode.

Dua perbaikan yang lebih dari kerapian:

- JadwalScreen menampilkan kartu gagal di ATAS kalender. Sebelumnya di
  bawah legenda, jadi saat gagal yang terlihat kalender kosong tanpa
  titik warna — terbaca "memang tidak ada jadwal".
- AbsenMenuScreen menyamakan gagal dengan kosong (`getStatus()` menelan
  error jadi null). Sekarang `getStatusOrThrow()` membedakannya.

InformasiScreen sengaja TIDAK memakai `KartuKosong`: dia pakai
`LayoutBuilder` supaya pull-to-refresh jalan di layar kosong, dan
membedakan "belum ada" dari "pencarian tidak ketemu".

### 3. Bahasa — SELESAI 25 Nov (`4ecdcfe`, `6a046b3`)

Dua temuan ditutup:

- **Tanggal format mesin di lima form.** `_formatTanggal()` lokal
  mengembalikan `yyyy-MM-dd` karena itu yang dikirim ke backend, lalu
  dipakai juga untuk ditampilkan — jadi karyawan melihat "2026-11-25".
  Dipisah jadi `tanggalUntukApi()` dan `tanggalUntukLayar()` di
  `lib/utils/format_tanggal.dart`.
- **Jenis `piket` tidak ada di legenda Jadwal** dan warnanya sama
  persis dengan reguler. Sekarang punya warna sendiri, jadi bisa
  dibedakan di kalender juga.

Yang DIPERIKSA dan ternyata benar: label "Keperluan" vs "Alasan" di
form. Sempat dikira tidak seragam, ternyata pembagiannya tepat — lihat
catatan konvensi di bawah.

Sisa yang belum disisir: nilai enum lain yang mungkin bocor apa adanya
ke layar (status pegawai sudah ditambal `_kapital()` di profil 24 Nov,
tapi itu satu tempat, bukan aturan).
### 4. Jalan buntu — SELESAI 26 Nov (`08bf2ef`, `a3a3150`)

Layar yang bisa dibuka tapi tidak jelas langkah berikutnya.

Dua temuan ditutup:

- **JadwalScreen: menekan tanggal tanpa jadwal tidak menampilkan apa
  pun** — tidak ada kartu, tidak ada pesan. Karyawan tidak tahu apakah
  memang kosong atau ketukannya tidak terdaftar. Diam total adalah
  umpan balik terburuk.
- **AbsenMenuScreen saat sudah absen masuk DAN pulang** — kedua tombol
  mati, layarnya cuma dua kotak abu-abu tanpa tanda bahwa memang sudah
  selesai.

Sebagian sudah tertutup sendiri saat dimensi 2: TukarJadwalList dalam
keadaan kosong sekarang menyebut CARANYA ("Ajukan dari layar Jadwal"),
karena layar itu tidak punya tombol +.

Yang DIPERIKSA dan ternyata sudah benar: MenungguResponScreen kosong
(sudah dapat KartuKosong), InformasiDetailScreen saat 404 (sudah ada
tombol Kembali), dan semua form setelah sukses (pop ke layar
sebelumnya).

### 5. Konsistensi visual — SEBAGIAN 25 Nov (`18ff2d1`)

AppBar hijau solid di semua layar lewat `appBarTheme`. Satu perubahan
untuk semua layar. Ikut berubah: `tabBarTheme` (label TabBar tidak
mewarisi `foregroundColor` AppBar, jadi abu-abu di atas hijau), dan
kartu rekap Riwayat yang tidak lagi `primaryContainer`.

Ide "lengkungan hijau di semua layar" DITOLAK: butuh struktur
ListView + Stack yang tidak dimiliki Jadwal dan form-form, jadi
menirunya berarti menyentuh dan menguji ulang belasan file dengan hasil
yang tidak jauh berbeda dari sekadar AppBar berwarna.

Yang BELUM: apa yang terjadi persis di bawah AppBar masih berbeda per
layar — Riwayat punya TabBar, Informasi langsung kotak pencarian,
Beranda kartu mengambang, layar daftar langsung kartu pertama. Kalau
mau diseragamkan, perlu aturan jarak yang disepakati dulu.

Ide "background gambar di AppBar" ditahan 25 Nov: menambah hal yang
harus dimuat, dan belum jelas masalah apa yang diselesaikan.

## Perlu investigasi sebelum dikerjakan


## Keputusan yang menggantung (butuh jawaban Khoirul)


- [ ] **Menu "Gaji" & "Piket"** — muncul di referensi UI yang dikirim
      15 Okt 2026, tapi gak ada endpoint-nya di backend sekarang. Scope
      masa depan, atau referensi dari app lain yang beda modul?

      DITUNDA 26 Nov 2026: belum ada keputusan dari pihak RS, dan tidak
      ada yang menunggu ini. Jangan digarap sampai ditanyakan.


## Belum ditest end-to-end

*(kosong — TukarJadwal, Cuti, Lembur, Dinas, Izin semua sudah tervalidasi
end-to-end per 26 Okt 2026)*

## Technical debt

*(kosong)*

## Catatan konvensi FE (biar gak keulang)

- Aksi yang TIDAK bisa dibatalkan sendiri pakai `konfirmasi()` dari
  `lib/widgets/dialog_konfirmasi.dart`. Kata di tombol kiri jangan
  serumpun dengan tombol kanan — "Batal" vs "Batalkan" terbukti
  ambigu 25 Nov. Dialog yang ditutup lewat back atau ketukan di luar
  mengembalikan null, dan itu BUKAN persetujuan.

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
- "Keperluan" vs "Alasan" di form SENGAJA berbeda, bukan kelalaian.
  Izin dan Dinas pakai "Keperluan" (ada urusan konkret yang dituju),
  Lembur/Cuti/TukarJadwal pakai "Alasan" (menjawab kenapa). Diputuskan
  25 Nov 2026 saat audit UX — jangan diseragamkan.

- Tanggal yang dibentuk di FE: `tanggalUntukApi()` untuk dikirim ke
  backend (`yyyy-MM-dd`), `tanggalUntukLayar()` untuk ditampilkan
  ("25 Nov 2026", nama bulan Indonesia). Keduanya di
  `lib/utils/format_tanggal.dart`. Jangan bikin `_formatTanggal()`
  lokal lagi — itu yang dulu bikin format mesin bocor ke layar.

- `harus_ganti_password` dari backend (fase 89) mengarahkan, BUKAN
  memaksa. MainScreen membukanya setelah frame pertama dan layarnya
  boleh ditutup; flagnya tetap true sampai password diganti, jadi
  peringatannya muncul lagi tiap aplikasi dibuka. Jangan dibuat
  `PopScope(canPop: false)` — kalau ada bug di alur ganti password,
  karyawan itu tidak bisa absen sama sekali.
- Layar yang datanya bisa berubah dari layar lain harus disegarkan saat
  kembali, bukan menunggu ditarik. Dua tempat yang sudah: Beranda
  setelah kembali dari AbsenMenuScreen (`7c3ee29`), dan tab Riwayat
  saat dipilih dari bottom nav (`81ab936`, lewat
  `RiwayatScreenState.segarkanTabAktif()`).

  IndexedStack + wantKeepAlive membuat tab dibangun sekali lalu ditahan
  selamanya — itu benar untuk mempertahankan bulan yang sedang dilihat,
  tapi berarti tidak ada yang memuat ulang kalau tidak dipicu.

- Pemuatan data tab TIDAK di `initState`. IndexedStack membangun
  ketiganya sekaligus, jadi `initState` berarti request untuk layar yang
  mungkin tidak pernah dilihat. MainScreen yang memicu saat tab dipilih
  (`6040347`): `segarkanTabAktif()` untuk Riwayat, `muatSaatDibuka()`
  untuk Informasi.

  Tiap layar punya penanda `_pernahDimuat`: pemuatan PERTAMA pakai
  spinner karena layarnya masih kosong, berikutnya tanpa spinner supaya
  yang sudah tampil tidak berkedip.

  `TukarJadwalList` dipakai dua tempat — sebagai tab dan sebagai layar
  yang di-push dari notifikasi. Parameter `muatSaatDibuka` (default
  true) membedakannya.

  Pola yang sama berlaku untuk layar yang datanya bisa berubah dari
  layar lain: Beranda menyegarkan diri saat kembali dari AbsenMenuScreen
  (`7c3ee29`). `wantKeepAlive` menahan bulan yang sedang dilihat, tapi
  berarti tidak ada yang memuat ulang kalau tidak dipicu.