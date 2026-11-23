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
          
- [ ] **Ikon lonceng + badge di TukarJadwalScreen sekarang boleh dicabut**
      — prasyaratnya LENGKAP per 20 Nov 2026: notifikasi sudah mengenal
      tipe & aksi, dan sudah bisa ditekan untuk membuka MenungguResponScreen.
      Lonceng tidak lagi jadi satu-satunya pintu ke tombol Setuju/Tolak.
      Ini membuka perombakan navigasi yang tertahan sejak 6 Nov.


 - [ ] **SplashScreen masih pakai `FlutterLogo` bawaan** — komentar "nanti
      diganti logo RS" sudah ada di kodenya sejak lama. LoginScreen sudah
      dirapikan 20 Nov 2026 (identitas, kartu form, tombol solid,
      prefixIcon); Splash belum disentuh. Nyambung ke item logo instansi
      di atas.

- [ ] **Logo instansi dari backend** — LoginScreen dan SplashScreen masih
      pakai placeholder (lingkaran hijau berisi ikon rumah sakit di Login,
      `FlutterLogo` di Splash). Usul 20 Nov 2026: ambil dari API bagian
      instansi, bukan aset yang di-bundle — lebih benar kalau nanti ada
      instansi kedua, dan logo bisa diganti tanpa rilis ulang aplikasi.

      MASALAH URUTAN yang perlu diselesaikan dulu: LoginScreen tampil
      SEBELUM ada yang login, jadi aplikasi belum tahu instansi mana dan
      kemungkinan endpoint-nya butuh token. Tiga kemungkinan jalan keluar:

      1. Endpoint publik untuk logo instansi (tanpa auth). Paling
         sederhana, tapi perlu diputuskan apakah logo RS itu informasi
         yang boleh diakses tanpa login — kemungkinan besar iya, logo
         bukan rahasia.
      2. Logo disimpan lokal setelah login pertama, dipakai di login
         berikutnya. Login pertama tetap pakai placeholder.
      3. Hanya Beranda dan layar dalam yang pakai logo dari API; Login
         dan Splash tetap pakai aset bundle.

      Backend juga perlu kolomnya dulu — cek apakah tabel `instansi`
      sudah punya field logo. Kalau belum: migration + FileUpload di
      InstansiResource + field di response API.

      Di FE, ganti isi `_identitas()` di login_screen.dart — ukuran dan
      posisinya sudah disiapkan, tinggal tukar Icon jadi Image.


- [ ] **Alur isi jam kembali di Izin terasa janggal** — belum ada
      diagnosis, baru firasat. Yang sudah terlihat: tidak ada tombol
      sama sekali, cuma `onTap` pada ListTile tanpa petunjuk visual
      bahwa kartu itu bisa ditekan; badge status hampir selalu
      "approved" (izin auto-approve sejak keputusan RS 8 Okt, lihat
      IzinController) sehingga nyaris tidak membawa informasi, sementara
      yang benar-benar menentukan apa yang bisa dilakukan user —
      terisi/tidaknya jam kembali — tidak ditandai apa pun; dan sekali
      terisi tidak bisa dikoreksi sendiri (guard backend
      `jam_kembali === null`, disengaja supaya "siapa & kapan mengisi"
      terbaca dari `updated_at`), jadi salah pilih jam berarti harus
      menghubungi admin. Perlu sesi analisis tersendiri: mungkin
      jawabannya bukan memperbaiki tampilan, tapi mempertanyakan apakah
      karyawan memang pihak yang tepat untuk mencatat jam kembali.
      Dicatat 6 Nov 2026.

- [ ] **Validasi silang Cuti & Dinas belum dicegah di sumbernya** —
      KOREKSI 23 Nov 2026: item lama bilang "dua date picker terpisah",
      itu tidak benar — keduanya sudah pakai `showDateRangePicker`.
      Dua keluhan lain di item lama juga sudah ditutup `9806a54`/`82ba1f7`:
      jumlah hari dan sisa kuota sekarang tampil hidup sebelum submit.

      Yang BELUM: aturan backend yang bisa menolak setelah submit tidak
      dicegah lewat `selectableDayPredicate` seperti di TukarJadwal —
      tidak boleh melintasi tahun, tidak boleh melintasi semester untuk
      jenis cuti semesteran, dan bentrok dengan cuti/dinas yang sudah
      approved. Yang ketiga perlu prefetch dulu seperti
      `_prefetchJadwalSaya()` di TukarJadwalFormScreen.
      
- [ ] **Pemilihan rentang tanggal di Cuti & Dinas kurang ramah** —
      dua date picker terpisah (mulai, selesai) tanpa gambaran rentang
      yang terbentuk; user baru harus menebak sendiri berapa hari yang
      dia ajukan. Belum ada diagnosis lengkap, baru keluhan dari
      pemakaian pertama. Hal-hal yang patut dilihat saat digarap:
      jumlah hari tidak ditampilkan sebelum submit padahal backend
      menghitungnya (`jumlah_hari`) dan itu yang memotong kuota; sisa
      kuota juga tidak terlihat di form Cuti padahal endpoint
      `/api/cuti/kuota` sudah ada dan `CutiService.kuota()` sudah
      dipakai di layar lain; aturan backend yang bisa menolak setelah
      submit (tidak boleh melintasi tahun, tidak boleh melintasi
      semester untuk jenis cuti semesteran, bentrok dengan cuti/dinas
      approved) tidak dicegah di sumbernya seperti yang sudah dilakukan
      di TukarJadwal lewat `selectableDayPredicate`. Kandidat solusi:
      `showDateRangePicker` satu kali, atau tetap dua picker tapi
      dengan ringkasan rentang + sisa kuota yang hidup. Perlu sesi
      tersendiri. Dicatat 6 Nov 2026.


- [ ] **RiwayatScreen: batasi tampilan awal** — daftar harian tampil utuh
      sebulan penuh. Cukup ~10 baris dulu + tombol "Lihat semua".
      Sempat dipertimbangkan membatasi ke 30 hari terakhir dan membuang
      navigasi bulan, ditolak: riwayat justru paling dicari saat ada
      selisih dengan rekap HRD, dan itu baru ketahuan setelah tutup
      bulan — datanya sudah lewat dari 30 hari. Endpoint juga cuma
      menerima `bulan`/`tahun`, jadi rolling 30 hari berarti gabung dua
      request di FE dan rekap bulanannya jadi janggal. Dicatat 6 Nov 2026.

      
- [ ] **Isi tab Informasi** — layar sudah ada (`informasi_screen.dart`)
      tapi hardcoded empty state. Backend SIAP sejak fase 75 (9 Nov 2026):
      dua endpoint, cari + paging. Perlu service, model, list kartu
      pengumuman + layar detail. Modul pertama yang pakai paging, jadi
      polanya belum ada di FE.

- [ ] **Redesign visual Beranda** — struktur navigasi sudah final (bottom
      nav 3 tab), tapi gaya visual masih default Material. Referensi dari
      aplikasi lama: kartu profil dengan latar melengkung, ikon menu bulat
      berwarna per kategori, ring chart kehadiran, tombol Presensi di
      tengah bottom nav. Dikerjakan setelah audit UX per-modul selesai
      biar nggak nabrak perubahan struktural. Dicatat 5 Nov 2026.

- [ ] **Verifikasi ganti password di device** — layar sudah ada
      (`lib/screens/profil/ubah_password_screen.dart`, commit `e2ff9b3`)
      dan endpoint backend sudah jalan (`f3eacf8`, 15 test hijau), tapi
      BELUM pernah dijalankan di perangkat. Yang perlu dicoba: satu kali
      ganti sungguhan, lalu logout dan login pakai password baru — itu
      yang membuktikan tidak ada hash ganda dari sisi klien.

      "Ganti email" DIBUANG dari scope 23 Nov 2026: email tidak dipakai
      untuk login (sudah username sejak fase 79), tidak dipakai untuk
      reset (ditolak fase 78), dan sejak fase 81 ~110 dari 150 karyawan
      tidak punya. Mengedit field yang tidak melakukan apa-apa bukan
      fitur. Menu "Profil" di PopupMenuButton masih placeholder.

- [ ] **Label "Tidak Hadir" bisa terpotong di kartu rekap Beranda** —
      empat kolom dibagi rata pakai Expanded, dan "Tidak Hadir" lebih
      panjang dari "Alpha" yang digantikannya (`5ca0cec`). Belum dilihat
      di layar sempit. Kalau terpotong: `textAlign: TextAlign.center`
      dan/atau turunkan ke `fontSize: 10`. Dicatat 23 Nov 2026.

- [ ] **Telusur/audit UX frontend secara menyeluruh** — review semua
      screen (bukan per-modul kayak sesi-sesi sebelumnya) buat nyari
      pola yang kurang ramah pengguna: konsistensi visual antar modul
      (section Card baru diterapkan di TukarJadwalFormScreen, modul
      lain — Izin/Lembur/Cuti/Dinas — masih layout polos ListTile
      rata tanpa sekat, lihat commit `7b42ee1`), copy/pesan yang
      masih teknis atau kurang jelas, alur yang bisa dipangkas/
      disederhanakan. Masih rencana, belum ada scope/checklist
      konkret — perlu sesi tersendiri buat nentuin cakupannya (semua
      modul sekaligus, atau satu-satu kayak pola review Filament
      Resource di backend fase 25-36). Dicatat 4 Nov 2026.

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
- [ ] **Struktur layar Riwayat** — referensi UI gabung Presensi/Izin/Cuti
      dkk jadi 1 screen pakai tab, beda dari struktur sekarang (tiap modul
      screen terpisah, diakses dari grid home). Diikutin atau tetap kayak
      sekarang?

## Belum ditest end-to-end

*(kosong — TukarJadwal, Cuti, Lembur, Dinas, Izin semua sudah tervalidasi
end-to-end per 26 Okt 2026)*

## Technical debt

*(kosong)*

## Catatan konvensi FE (biar gak keulang)

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