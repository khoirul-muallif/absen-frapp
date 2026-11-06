# TODO — absensi_frontapp

> Isi aktif aja — kalau item selesai, hapus (bukan di-checklist doang),
> biar file ini tetep pendek dan gampang di-scan. Detail histori lengkap
> tetap di CHANGELOG-fr.md.

## Belum dibuat
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

- [ ] **IzinFormScreen masih layout polos** — Column putih tanpa sekat,
      beda dari TukarJadwalFormScreen yang sudah pakai section Card
      (`7b42ee1`). Berlaku juga ke form Lembur/Cuti/Dinas. Sudah
      tercakup item "Telusur/audit UX frontend secara menyeluruh" di
      atas, tapi dicatat terpisah karena perbaikannya mekanis dan bisa
      dikerjakan lebih dulu tanpa menunggu scope audit UX ditentukan.
      Dua hal kecil yang sekalian: `initialTime: TimeOfDay.now()` di
      picker jam mengabaikan pilihan sebelumnya, dan jam keluar
      divalidasi lewat snackbar sementara Keperluan pakai `validator`
      Form. Dicatat 6 Nov 2026.

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