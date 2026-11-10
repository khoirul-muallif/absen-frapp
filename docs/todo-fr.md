# TODO — absensi_frontapp

> Isi aktif aja — kalau item selesai, hapus (bukan di-checklist doang),
> biar file ini tetep pendek dan gampang di-scan. Detail histori lengkap
> tetap di CHANGELOG-fr.md.

## Belum dibuat
- [ ] **`email` di response profil bisa null** — backend fase 81 (10 Nov
      2026) membuat `karyawan.email` nullable. Pihak RS mengonfirmasi tidak
      semua karyawan punya email, dan sejak login pindah ke username (fase
      79) email cuma data profil biasa.

      Yang perlu dicek: model Dart untuk profil karyawan. Kalau field-nya
      `String email` bukan `String? email`, parsing JSON melempar dan layar
      profil mati — bukan untuk satu-dua orang, tapi untuk ~110 dari 150
      karyawan. Cek juga setiap tempat yang menampilkan email langsung
      (`Text(user.email)`) — perlu fallback, bukan string kosong yang
      menyisakan label menggantung.

      Ini TIDAK berkaitan dengan blocker LoginScreen (fase 79). Di situ
      `email` dicabut dari request body; di sini `email` tetap ada di
      response, cuma bisa bernilai null.
      
- [ ] **LoginScreen WAJIB pindah ke username — FE sekarang pasti gagal
      login** — backend sudah mengubah `POST /api/auth/login` dari
      `email` ke `username` (fase 79, 9 Nov 2026). FE masih mengirim
      `email`, jadi responnya 422 `username: required` dan tidak ada
      satu pun karyawan yang bisa masuk. Ini bukan lagi "menunggu
      keputusan" — ini blocker rilis.

      Yang perlu diubah: label field, `keyboardType` (`emailAddress` →
      `text`), kunci yang dikirim di body request, dan kunci error yang
      dibaca untuk menempelkan pesan (`errors.email` → `errors.username`
      — kalau tidak ikut diubah, pesan "Username atau password salah"
      tidak muncul di mana-mana).

      Catatan: `email` TETAP ada di response login dan `/auth/me`
      sebagai data profil, jadi layar profil tidak perlu diubah.
      `username` ditambahkan di sebelahnya kalau mau ditampilkan.

      Password default & reset: admin bisa me-reset password karyawan
      dari panel (fase 78), dikembalikan ke password default. Karyawan
      yang lupa password menghubungi admin.

- [ ] **Hapus "Sakit" dari kartu rekap RiwayatScreen** — TERJAWAB
      9 Nov 2026: enum `absensi.status = 'sakit'` adalah dead value,
      bukan fitur yang belum dibuat. Cuti sakit sudah dicover modul
      Cuti. Jadi backend TIDAK akan mulai mengisinya — hapus field
      `sakit` dari `_RekapCard` dan dari model `RekapAbsen`.
      Sekalian: ganti label "Alpha" jadi "Tidak Hadir" (istilah
      administratif vs yang dibaca karyawan sendiri).

- [ ] **LoginScreen masih polos** — tidak ada logo RS, tidak ada warna
      atau identitas apa pun; dua field + satu tombol di tengah layar
      putih. Ini layar pertama yang dilihat karyawan, jadi dampaknya
      lebih besar daripada form-form lain yang sudah dicatat.
      SplashScreen juga masih memakai `FlutterLogo` bawaan (komentar
      "nanti diganti logo RS" sudah ada di kodenya sejak lama). Butuh
      aset logo RSU Banyumanik 2 dulu. Dicatat 6 Nov 2026.

- [ ] **LoginScreen ikut berubah kalau login pindah ke username** —
      label field, `keyboardType` (`emailAddress` → `text`), dan teks
      error. Menunggu keputusan + endpoint backend (lihat todo.md
      backend). Dicatat 6 Nov 2026.

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

- [ ] **Form Izin/Lembur/Cuti/Dinas masih layout polos** — Column putih
      tanpa sekat, beda dari TukarJadwalFormScreen yang sudah pakai
      section Card (`7b42ee1`). Sudah tercakup item "Telusur/audit UX
      frontend secara menyeluruh" di atas, tapi dicatat terpisah karena
      perbaikannya mekanis dan bisa dikerjakan lebih dulu tanpa menunggu
      scope audit UX ditentukan. Dua hal kecil yang sekalian:
      `initialTime: TimeOfDay.now()` di picker jam mengabaikan pilihan
      sebelumnya, dan jam keluar divalidasi lewat snackbar sementara
      Keperluan pakai `validator` Form. Dicatat 6 Nov 2026.
      
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

- [ ] **RiwayatScreen: batasi chevron kanan** — bisa maju tanpa batas ke
      bulan yang pasti kosong (tidak ada data masa depan di backend).
      Kunci di bulan berjalan. Dicatat 6 Nov 2026.
- [ ] **NotifikasiScreen harus mengenal `tipe: 'tukar_jadwal'`** — backend
      mulai mengirim nilai `tipe` baru ini sejak fase 74 (4 kelas
      notifikasi TukarJadwal). Sebelumnya cuma ada `'terlambat'` dan
      nilai milik `BelumAbsen`. **Cek dulu apakah switch ikon/warna di
      `notifikasi_screen.dart` punya cabang `default`** — kalau tidak,
      nilai baru ini bisa bikin ikon kosong atau crash. Ini satu-satunya
      hal yang masih bisa menggagalkan fitur notifikasi tukar jadwal di
      device meski backend-nya sudah hijau total.

      Bentuk `data` yang dikirim: `judul`, `pesan`, `tipe`
      (selalu `'tukar_jadwal'`), `aksi`, `tukar_jadwal_id`, `tanggal`.
      Nilai `aksi`: `diajukan`, `disetujui_rekan`, `ditolak_rekan`,
      `approved`, `rejected`, `dibatalkan_admin`, `dibatalkan_pengaju`.
      `tipe` sengaja satu nilai untuk ketujuh kejadian supaya FE tidak
      perlu tujuh cabang — kalau nanti ikonnya mau dibedakan per
      kejadian, pakai `aksi`, bukan `tipe`.

      **Catatan penting:** untuk `aksi: 'dibatalkan_pengaju'`, baris
      TukarJadwal-nya sudah DIHAPUS di backend, jadi `tukar_jadwal_id`
      menunjuk ke id yang tidak ada lagi (keputusan 9 Nov 2026: id tetap
      dikirim demi konsistensi bentuk `data`). Kalau nanti notifikasi
      dibuat bisa di-tap untuk membuka detail, yang ini harus ditangani
      — jangan sampai 404 jadi crash. Dicatat 9 Nov 2026.

- [ ] **Ikon lonceng + badge di TukarJadwalScreen sekarang boleh dicabut**
      — blocker-nya sudah hilang: backend mengirim notifikasi ke rekan
      tujuan setiap ada pengajuan masuk (fase 74), jadi mencabut lonceng
      tidak lagi menghapus satu-satunya cara rekan tahu ada yang
      menunggu dijawab. Ini membuka perombakan navigasi yang tertahan
      sejak 6 Nov (tab Riwayat menyerap riwayat tukar jadwal, satu pintu
      pengajuan lewat JadwalScreen). Prasyarat: item NotifikasiScreen di
      atas dikerjakan DULU — kalau lonceng dicabut sementara
      NotifikasiScreen belum mengenal `tipe` barunya, rekan justru
      kehilangan kedua jalur sekaligus. Dicatat 9 Nov 2026.
      
- [ ] **Isi tab Informasi** — layar sudah ada (`informasi_screen.dart`,
      commit [isi setelah commit]) tapi hardcoded empty state. Nunggu
      model + endpoint di backend (dicatat juga di todo.md). Setelah
      itu: service, model, list kartu pengumuman + layar detail.
      Dicatat 5 Nov 2026.

- [ ] **Redesign visual Beranda** — struktur navigasi sudah final (bottom
      nav 3 tab), tapi gaya visual masih default Material. Referensi dari
      aplikasi lama: kartu profil dengan latar melengkung, ikon menu bulat
      berwarna per kategori, ring chart kehadiran, tombol Presensi di
      tengah bottom nav. Dikerjakan setelah audit UX per-modul selesai
      biar nggak nabrak perubahan struktural. Dicatat 5 Nov 2026.

- [ ] **Fitur ganti email & password** — menu "Profil"/"Ubah Password"
      sudah ada wadahnya di app bar (PopupMenuButton pojok kanan atas,
      commit [isi setelah commit]), tapi isinya masih placeholder
      snackbar "segera hadir". Perlu endpoint backend buat update
      email/password (belum ada — cek dulu apakah `AuthController`
      sudah punya atau perlu baru), dan screen form di FE. Dicatat
      5 Nov 2026.

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

*(kosong — semua tervalidasi `after_or_equal:today` di backend DAN
dicegah di sumbernya di FE (kalender gak nawarin tanggal lewat lagi
sejak commit `4ebe805`): Cuti/Dinas, TukarJadwal, Izin/Lembur)*

## Keputusan yang menggantung (butuh jawaban Khoirul)

- [ ] **"Sakit" di kartu rekap RiwayatScreen** — field `sakit` tidak
      pernah diisi backend (`rekap()` tidak mengirimnya), jadi angkanya
      permanen 0 bagi semua orang, tapi tetap ditampilkan di
      `_RekapCard`. Hapus dari kartu, atau backend mulai mengisinya?
      Nyambung ke Known Gap #5 di QUICK_CONTEXT.md (enum
      `absensi.status` punya opsi `'sakit'` yang belum jelas
      peruntukannya). Sekalian: label "Alpha" itu istilah administratif,
      di kartu yang dibaca karyawan sendiri "Tidak Hadir" lebih jelas.
      Dicatat 6 Nov 2026.

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