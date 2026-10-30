## feat: redesign menu Absen — 2 tombol eksplisit, auto-lokasi, disable kondisional

Commit: `905b9c3`, `e334d78`, `7d8108d`, `<isi hash commit terbaru>` (30 Okt 2026)

Rangkaian 4 commit merombak alur absen di Home, dipicu bug auto-routing
tombol "Absen" tunggal yang nebak sendiri mau diarahkan ke flow masuk
atau pulang berdasar `getStatus()` (lihat todo-fr.md lama, item "bug
absen auto-routing").

**905b9c3 / e334d78**: tombol tunggal diganti 2 tombol eksplisit "Absen
Masuk"/"Absen Pulang" (langkah awal, masih di grid Beranda). Sekalian
benerin retry QR/wajah yang tadinya rebutan hardware kamera
(IndexedStack nahan StepQr/StepWajah tetap hidup walau disembunyikan)
-- beberapa percobaan fix gagal sebelum ketemu solusi: balik total ke
Beranda (bukan rebuild di tempat) + peringatan tunggu 5-10 detik sebelum
tap Absen lagi, lewat `StepWajah.onGagal` (digabung dari 2 callback
`onUlangiDariAwal`/`onScanUlangQr` yang tadinya identik).

**7d8108d**: lokasi (GPS + izin lokasi + izin kamera) dipindah dari step
terpisah di dalam flow jadi di-fetch di Beranda SEBELUM push ke
AbsenFlowScreen/AbsenPulangFlowScreen -- kalau gagal, user gak jadi
masuk flow sama sekali (kamera gak kebuka). Logic diekstrak ke
`LokasiHelper.ambilLokasi()` (`lib/utils/lokasi_helper.dart`), dipakai
bareng oleh `StepLokasi` (dipertahankan sebagai fallback, tidak
dihapus dari flow) dan pemanggil baru. `AbsenFlowScreen`/
`AbsenPulangFlowScreen` dapat parameter opsional `initialPosition` --
kalau diisi, step Lokasi di-skip.

**<hash commit terbaru>**: 2 tombol di atas dipindah dari grid Beranda
ke screen baru `AbsenMenuScreen` (dibuka lewat 1 tile "Absen" di
Beranda) -- status absen sekarang dimuat sekali di awal screen ini
(bukan per-tap), jadi kedua tombol bisa langsung menampilkan kondisi
enabled/disabled begitu dibuka: "Absen Masuk" disabled kalau
`sudahMasuk`, "Absen Pulang" disabled kalau belum masuk atau sudah
pulang. Tombol disabled tetap ditampilkan (abu-abu) dengan keterangan
("Sudah absen masuk pukul HH:mm"), tidak disembunyikan.

### KEPUTUSAN: tidak menambahkan cek jadwal/libur di client

Sempat dipertimbangkan nge-disable tombol kalau hari ini libur
(mencegah tap yang pasti ditolak). Ditolak: backend `masuk()` sudah
menangani ini dengan pesan eksplisit sejak fase 43 ("Hari ini jadwal
Anda libur, tidak perlu absen masuk."), dan `step_wajah.dart` sudah
menampilkan `result['message']` backend apa adanya. Menduplikasi cek
ini di FE berarti menduplikasi logic `shiftYangDiharapkanPada()`
(cuti/dinas approved + libur instansi + Jadwal, bukan cuma status
libur) -- kelas masalah single-source-of-truth yang sama dengan yang
sudah berulang kali ditutup di backend (`KuotaCuti::sisaUntuk()` fase
26, `Shift::jamMasukString()` fase 14/27). Biarkan backend yang
menolak, FE cuma merelay pesannya.

Belum ditest end-to-end di device untuk commit terbaru -- lihat
todo-fr.md kalau ada temuan saat testing.

## fix(ux): warna SnackBar sesuai jenis pesan + posisi pindah ke atas

Commit: 6f021c6, 9136a82 (27 Okt 2026)

Dua temuan testing manual yang digabung jadi satu perbaikan: SnackBar
bawaan Flutter (floating, dicoba dulu di commit sebelumnya) masih sering
ketutup jari/keyboard begitu baru submit form, dan semua pesan tampil
warna netral yang sama tanpa bedain error vs sukses.

`lib/utils/snackbar_helper.dart` (baru): notifikasi custom pakai
`Overlay`, slide-in dari ATAS (di bawah status bar, bukan nempel di
bawah layar), auto-dismiss 3 detik, tap-to-dismiss, notif baru otomatis
gantiin yang masih nongol (gak numpuk). Ditambah `AppSnackBarType`
(info/success/error) — merah buat validasi & pesan gagal, hijau buat
sukses eksplisit (approve/reject TukarJadwal di
`menunggu_respon_screen.dart`), abu-abu netral buat sisanya (default,
pemanggilan lama yang belum diupdate tetap aman).

Diterapkan ke semua pemanggilan `ScaffoldMessenger.showSnackBar` lama
(11 file: Cuti/Izin/Lembur/Dinas/TukarJadwal — form & list screen,
`home_screen.dart`). Menutup item lama todo-fr.md "SnackBar kurang user
friendly" — diperbaiki dari sisi posisi+warna, bukan diganti popup
(opsi awal yang diusulkan).

## feat(tukar-jadwal): badge jumlah pengajuan menunggu respon + bottom sheet pilih rekan

Commit: e246821 (26 Okt 2026)

Dua temuan dari testing manual `TukarJadwalFormScreen` (yang ternyata
sudah lengkap dibuat, bukan blocked seperti catatan lama):

- Rekan sering gak sadar ada pengajuan tukar jadwal yang nunggu
  direspon — ikon lonceng di app bar `TukarJadwalScreen` polos tanpa
  indikator apa pun. Ditambah `Badge` count di 2 tempat: ikon lonceng
  itu sendiri, dan card menu "Tukar Jadwal" di `home_screen.dart`
  (`HomeScreen` diubah dari `StatelessWidget` ke `StatefulWidget`).
  Sumbernya sama-sama `GET /api/tukar-jadwal/menunggu-respon-saya`.
- Pemilihan rekan tujuan (mode Tukar) bikin scroll panjang begitu
  banyak rekan yang punya jadwal di tanggal itu — daftar `RadioListTile`
  sebelumnya dirender inline di `ListView` yang sama dengan field
  Alasan & tombol submit. Dipindah ke `showModalBottomSheet` +
  `DraggableScrollableSheet`, dibuka lewat `ListTile` ringkasan.

Sempat ada insiden salah tempel (sisa blok lama `_rekanList.map`
nyangkut, bracket gak nutup) yang bikin `flutter run` gagal — diperbaiki
sebelum commit final.

## style: tema teal/mint terpusat + StatusBadge di semua modul

Commit: 654b73a (19 Okt 2026)

Styling disamakan ke referensi UI (teal/mint, kartu rounded, badge status
warna) yang dikirim 15 Okt 2026, dibuat terpusat biar gak duplikasi per
screen: lib/theme/app_theme.dart (AppColors primary teal #1D9E75 disamakan
Filament admin panel, buildAppTheme()), lib/widgets/status_badge.dart
(statusDisplay() memetakan status mentah -> label Indonesia + warna,
mencakup status approval pending/approved/rejected/menunggu_rekan/dst DAN
status harian absensi tepat_waktu/terlambat/alpha/izin/sakit/cuti/dinas/
libur dalam satu tempat, plus widget StatusBadge). main.dart pasang
theme: buildAppTheme(). Semua `_statusColor()` lokal di 6 screen (Izin/
Lembur/Dinas/Cuti/TukarJadwal/Riwayat) dihapus, diganti StatusBadge.
Logic pembatalan (bisaDibatalkan) tidak disentuh, cuma tampilan.

Dikonfirmasi visual: warna sudah berubah di app setelah build & install.

## feat: lokalisasi date/time picker ke Bahasa Indonesia

Commit: 0c290de (19 Okt 2026)

Date picker, time picker, date range picker (semua widget Material
bawaan) masih locale Inggris default. Fix: pubspec.yaml tambah
flutter_localizations (sdk: flutter), bump intl 0.19.0 -> ^0.20.3 (dipaksa
constraint flutter_localizations). main.dart: MaterialApp dikasih
locale: Locale('id','ID'), supportedLocales (id_ID + en_US),
localizationsDelegates (GlobalMaterialLocalizations/WidgetsLocalizations/
CupertinoLocalizations). Efeknya global ke semua picker tanpa sentuh
satu-satu. Dikonfirmasi: "Select date" -> "Pilih tanggal", nama
hari/bulan & tombol Batal/OK semua Indonesia.

## fix: paksa format 24 jam di semua TimePicker (Izin & Lembur)

Commit: 1a06852 (16 Okt 2026)

showTimePicker() di izin_form_screen.dart (jam keluar), izin_screen.dart
(isi jam kembali), lembur_form_screen.dart (jam mulai & selesai) masih
ikut format AM/PM locale device. Fix: tambah parameter builder yang
override MediaQuery.alwaysUse24HourFormat jadi true di tiap pemanggilan.
Ditemukan & dicatat di todo-fr.md saat testing 16 Okt 2026.

## fase 16: fix Cuti filter dropdown semester + catat 2 temuan UX ke todo-fr

Commit: 912e327 (16 Okt 2026)

Bug ditemukan saat testing: dropdown jenis cuti di cuti_form_screen.dart
nampilin SEMUA semester (1 dan 2) buat tiap jenis cuti semesteran,
padahal cuma semester berjalan yang relevan. CutiController::kuota()
backend memang sengaja balikin kedua semester -- perbaikannya di FE:
_loadJenisCuti() sekarang filter ke semester berjalan (asumsi semester
1=Jan-Jun, 2=Jul-Des, BELUM dikonfirmasi ke JenisCuti::semesterDari()
backend, dicatat di todo-fr.md).

Sekalian catat 2 temuan UX dari sesi testing yang sama ke todo-fr.md:
SnackBar dirasa kurang user friendly (diusulkan ganti popup, belum
diputuskan scope-nya), dan time picker belum 24 jam (di-fix di commit
1a06852 di atas).

## chore: upgrade Flutter 3.47.7, bump file_picker 13.x, fix compileSdk & deprecation warnings

Commit: c4b5630 (16 Okt 2026)

Dipicu build gagal saat flutter run pasca penambahan file_picker (modul
Cuti, fase 14) -- file_picker:checkDebugAarMetadata minta compileSdk 36+.

- android/app/build.gradle.kts: compileSdk = 36
- flutter upgrade 3.44.5 -> 3.47.7 (dicoba duluan, ternyata gak cukup --
  akar masalah beneran di versi file_picker)
- file_picker 8.3.7 -> 13.1.0 (lompat 5 major version, federated plugin
  rewrite)
- cuti_form_screen.dart: API lama FilePicker.platform.pickFiles() (sudah
  dihapus v12+) -> FilePicker.pickFile(), langsung balikin PlatformFile?

Beres-beres deprecation ikutan dari upgrade Dart 3.13, tanpa ubah logic:
analysis_options.yaml (exclude folder platform dari analyzer),
riwayat_screen.dart (withOpacity -> withValues(alpha:)),
tukar_jadwal_service.dart (null-aware map entry 'key': ?x),
step_lokasi.dart (desiredAccuracy -> locationSettings).

App berhasil di-build & install ke device fisik setelah ini -- jadi
testing end-to-end 4 modul yang sempat ketunda bisa lanjut (lihat entry
di bawah).

## Hasil testing end-to-end Lembur/Dinas/Cuti/TukarJadwal (16 Okt 2026)

Setelah fix build di atas, testing manual di device fisik untuk 4 modul
yang sebelumnya belum pernah dicoba sama sekali:

- **Lembur**: SEMUA LOLOS. Validasi alasan wajib & larangan lintas tengah
  malam jalan sesuai harapan. Submit valid -> status `pending` (bukan
  auto-approve kayak Izin -- jawab asumsi terbuka sejak fase 11).
  diajukan_at normal. Batal via swipe jalan.
- **Dinas**: SEMUA LOLOS. Validasi lintas tahun, bentrok Cuti/Dinas
  approved, riwayat & batal semua sesuai harapan.
- **Cuti**: 5/6 lolos. Upload lampiran multipart TERBUKTI JALAN (file
  beneran nyampe & kesimpen di server) -- paling krusial karena multipart
  manual CutiService belum pernah dicoba. Cek sisa kuota & pesan tolak
  jalan. 1 bug ditemukan (dropdown semester, fix di fase 16 di atas).
- **TukarJadwal**: test terbatas -- Riwayat & Menunggu Respon Saya gak
  crash walau kosong, tapi responRekan/batalkan belum bisa ditest sama
  sekali karena belum ada data (belum ada form ajukan, belum ada cara
  seed manual).

Ditemukan juga 1 UX gap lintas-modul: swipe-to-delete gak ada hint
visual di semua modul. Dicatat ke todo-fr.md.

## docs: pindahkan dokumentasi ke folder docs/, tambah runbook & todo-fr

Commit: 6c242f9 (15 Okt 2026)

Reorganisasi dokumentasi, konsisten dengan struktur folder docs/ di repo
backend: CHANGELOG-fr.md & status-14-10-26.md dipindah ke docs/,
docs/runbook.md baru (command sering dipakai + kredensial akun test),
docs/todo-fr.md baru (keputusan menggantung, modul belum ditest,
technical debt, catatan konvensi FE).
## fase 15: modul TukarJadwal (frontend) -- riwayat & respon rekan, form ajukan belum bisa dibuat

Audit TukarJadwalController.php + model TukarJadwal.php asli (dikirim
user): ajukan() terima jadwal_id (ID row Jadwal sendiri) & jadwal_tujuan_id
(ID row Jadwal rekan, required kalau mode=tukar) -- bukan tanggal/shift
langsung. 5 status: menunggu_rekan/menunggu_admin/ditolak_rekan/approved/
rejected. respon-rekan payload {setuju: bool, catatan: string?}. batalkan()
cuma oleh pengaju & status menunggu_rekan/menunggu_admin.

Dibuat yang gak keblok: tukar_jadwal_model.dart, tukar_jadwal_service.dart,
menunggu_respon_screen.dart (approve/reject), tukar_jadwal_screen.dart
(riwayat + batal), card "Tukar Jadwal" di home_screen.dart.

BLOCKER ditemukan: gak ada endpoint GET buat list Jadwal (sendiri atau
rekan) sebagai sumber picker jadwal_id/jadwal_tujuan_id di form ajukan --
dicek di routes/api.php backend, memang gak ada rute jadwal sama sekali.
Diusulkan 2 endpoint baru ke backend (dicatat di todo.md backend, commit
fc450ce): GET /api/jadwal/saya (gak ada keputusan bisnis) dan
GET /api/jadwal/rekan?tanggal=... (BUTUH keputusan scope privasi -- unit
kerja sama, instansi sama, atau gak dibatasi). TukarJadwalFormScreen
BELUM dibuat, nunggu endpoint ini & keputusan scope-nya.

Workaround dicatat: response riwayat() cuma kirim nama karyawan (bukan
ID) di jadwal_asal/jadwal_tujuan -- deteksi "pengajuan saya sendiri" buat
gating tombol Batalkan sementara cocokin nama ke AuthProvider.user.nama,
rawan false-positive kalau ada nama sama persis.

BELUM DITEST end-to-end, sama seperti Lembur/Dinas/Cuti.

## fase 14: modul Cuti (frontend)

Modul Cuti dibuat berdasarkan audit CutiController.php asli (dikirim user
bareng Dinas & Lembur). Paling kompleks dari 4 modul pertama: perlu pilih
jenis_cuti dari daftar aktif, tampilkan sisa kuota per jenis+semester,
lampiran conditional wajib, semua validasi tanggal/semester/tahun-crossing
ditangani di sisi server (FE cuma relay pesannya).

Baru: cuti_kuota_model.dart, cuti_model.dart, cuti_service.dart,
cuti_form_screen.dart, cuti_screen.dart, card "Cuti" di home_screen.dart,
ApiConstants.cuti & cutiKuota.

Desain: GET /api/cuti/kuota dipakai ganda sebagai sumber kuota DAN sumber
daftar jenis cuti aktif (tidak ada endpoint list jenis_cuti terpisah) --
dropdown form langsung diisi dari situ, termasuk flag perlu_lampiran per
jenis untuk nentuin apakah field lampiran wajib ditampilkan.

CutiService.ajukan() pakai multipart manual (http.MultipartRequest +
TokenStorage) karena ApiClient belum support file upload -- sama kondisi
dengan _absenMultipart di absensi_service.dart. BELUM dirapikan jadi satu
helper bersama; dicatat sebagai technical debt kecil.

Dependency baru: file_picker ditambahkan ke pubspec.yaml untuk lampiran
cuti (pdf/jpg/jpeg/png).

BELUM DITEST end-to-end -- sama seperti Lembur (fase 11) & Dinas (fase
12), masih menunggu akses device Android. Modul ini sekaligus paling
butuh test manual paling teliti karena ada 3 jalur validasi server yang
belum pernah dicoba dari sisi FE: cek bentrok cuti/dinas approved, cek
sisa kuota (termasuk pending lain), dan upload lampiran actual.

## fase 13: fix bug Lembur -- alasan wajib & larangan lintas tengah malam

Commit: a1132e6 (15 Okt 2026)

Audit LemburController.php asli (dikirim user) menemukan 2 ketidaksesuaian
dengan FE Lembur fase 11:

1. alasan required di backend (`'alasan' => 'required|...'`) tapi FE
   bikin opsional -- submit tanpa alasan selalu gagal 422. Fix: alasan
   jadi non-nullable di model/form/service, form wajib divalidasi.
2. jam_selesai divalidasi 'after:jam_mulai' oleh backend -- menolak
   lembur lintas tengah malam. Ini kontradiksi sama keputusan arsitektur
   lama (Lembur seharusnya bisa span midnight, cuma durasi nol yang
   ditolak -- lihat decisions-and-principles). BELUM diselesaikan mana
   yang benar; diputuskan ditunda, investigasi backend menyusul. Untuk
   sekarang FE ikut validasi backend yang berlaku: tolak submit kalau
   jam_selesai <= jam_mulai.

Masih BELUM ditest end-to-end (sama seperti fase 11/12 -- belum ada akses
device Android).

## fase 12: modul Dinas (frontend)

Commit: babe387 (15 Okt 2026)

Modul Dinas dibuat ngikutin pola Izin (fase 10) & Lembur (fase 11):
dinas_model.dart, dinas_service.dart (pakai ApiClient), dinas_form_screen.dart,
dinas_screen.dart, card "Dinas" di home_screen.dart, ApiConstants.dinas
di constants.dart.

Beda dari Lembur: form pakai rentang tanggal (tanggal_mulai +
tanggal_selesai, showDateRangePicker) bukan satu tanggal + jam, dan field
isiannya tujuan + keperluan tanpa jam sama sekali. Batal tetap di-gate ke
status == 'pending'.

BELUM DITEST end-to-end -- sama seperti fase 11, belum ada akses device
Android. Asumsi field diajukan_at di respons GET /api/dinas juga belum
diverifikasi ke DinasController.php backend.

## fase 11: modul Lembur (frontend) + reorganisasi folder Izin

Commit: f35355c (15 Okt 2026)

Modul Lembur dibuat ngikutin pola modul Izin (fase 10): lembur_model.dart,
lembur_service.dart (pakai ApiClient), lembur_form_screen.dart,
lembur_screen.dart, card "Lembur" di home_screen.dart, ApiConstants.lembur
di constants.dart.

Beda dari Izin: jam_mulai & jam_selesai sama-sama diisi di form pengajuan
(bukan diisi belakangan), alasan nullable, lintas tengah malam
diperbolehkan sebagai satu record -- form cuma menolak durasi nol.
Batalkan di-gate ke status == 'pending' (beda dari Izin yang di-gate ke
jamKembali == null, karena Lembur gak punya pola isi-belakangan).

Sekalian reorganisasi folder: izin_form_screen.dart & izin_screen.dart
dipindah ke lib/screens/izin/, konsisten dengan lib/screens/lembur/ yang
baru dibuat.

BELUM DITEST end-to-end (gak ada akses device Android saat commit ini).
Dua hal yang masih asumsi, perlu diverifikasi pas testing:
- Format field diajukan_at di respons GET /api/lembur
- Apakah Lembur auto-approved kayak Izin, atau pending menunggu admin
  (menentukan kapan tombol batal muncul di UI)
  
## fase 10: modul Izin (frontend) — ajukan, isi jam kembali, batalkan

Commit: <isi hash setelah commit> (14 Okt 2026)

Modul pertama dari Cuti/Izin/Lembur/Dinas/TukarJadwal di frontend,
dipilih sebagai percontohan pola (auto-approved, tanpa kuota — paling
sederhana) sebelum direplikasi ke modul lain. Urutan yang disepakati:
Izin -> Lembur -> Dinas -> Cuti -> TukarJadwal.

Baru: izin_model.dart, izin_service.dart (ApiClient), izin_form_screen.dart
(ajukan — sengaja tanpa field jam_kembali, diisi belakangan setelah
karyawan balik), izin_screen.dart (list riwayat, swipe-delete cuma aktif
kalau jam_kembali masih null sesuai guard backend, tap untuk isi jam
kembali), card "Izin" baru di home_screen.dart.

ApiClient ditambah method patch() untuk PATCH /api/izin/{id}/jam-kembali.

CATATAN: field jam Izin dari backend dikirim mentah "08:00:00" (beda
dari field jam lain yang H:i) — ditangani lewat substring di screen,
bukan direformat di model (lihat todo.md backend soal ketidakseragaman
ini).

Diuji end-to-end (karyawan Rina Wulandari): ajukan -> approved otomatis,
approved_by NULL -> isi jam kembali via tap -> terverifikasi benar di DB.

## fase 9: migrasi AuthService/AbsensiService/NotifikasiService ke ApiClient + fix terkait

Commit: 5f1fb58 (14 Okt 2026)

ApiClient terpusat (fase 8) sekarang dipakai penuh oleh AuthService dan
AbsensiService, kecuali absen masuk/pulang (_absenMultipart) yang tetap
manual karena ApiClient belum support multipart/form-data.

BUG DITEMUKAN & DIPERBAIKI: Stack Overflow saat migrasi awal — ApiClient
punya field AuthService dan AuthService punya field ApiClient, saling
instansiasi tanpa henti lewat field initializer begitu salah satunya
dibuat. Fix: ekstrak TokenStorage (get/save/clear token) sebagai
dependency bersama, dipakai ApiClient dan AuthService tanpa saling
bergantung.

NotifikasiService juga dimigrasi ke ApiClient, konsisten dengan dua
service lain.

BUG DITEMUKAN & DIPERBAIKI: notifikasi tidak bisa dihapus lewat swipe —
_hapus() nunggu response API dulu baru _loadData(), sementara Dismissible
sudah menganggap item selesai di-dismiss di frame yang sama -> "A
dismissed Dismissible widget is still part of the tree". Diganti jadi
optimistic remove dari state duluan, baru panggil API; kalau gagal baru
reload buat mengembalikan item.

constants.dart: baseUrl sekarang fail loud (StateError) kalau
API_BASE_URL tidak ada di .env, ganti dari fallback diam-diam ke
localhost:8000 yang di HP fisik merujuk ke HP itu sendiri, bukan ke
server dev — bikin semua request gagal tanpa pesan jelas.

Uji shift malam (fix backend b0dbee6) dikonfirmasi sukses end-to-end:
karyawan Rina Wulandari, shift malam 23:00-07:00, Absensi sesi terbuka
tanggal 13 Okt. Login di 14 Okt langsung diarahkan ke flow pulang,
berhasil mengisi waktu_pulang di row yang sama (tidak duplikat).

## fase 8: ApiClient terpusat + fix bug notifikasi baca struktur lama

Commit: 8838c81

BUG DITEMUKAN & DIPERBAIKI: notifikasi_service.dart membaca
data['notifikasi']['data'], struktur lama dari era NotifikasiController
masih pakai paginate(). Backend sudah menyederhanakannya ke
data.records + data.total sejak fase 24 (lihat CHANGELOG backend),
tapi frontend belum pernah disesuaikan -- akan null exception begitu
layar notifikasi dibuka. Diganti ke data['records'].

Tambah lib/services/api_client.dart: wrapper GET/POST/DELETE dengan
header otomatis (token + Accept) dan penanganan 401 terpusat (hapus
token lokal + lempar ApiException), supaya modul baru (Cuti, Izin,
Lembur, Dinas, TukarJadwal) tidak perlu menulis ulang pola auth +
error handling di tiap service seperti auth_service/absensi_service/
notifikasi_service sekarang.

Service lama BELUM dimigrasi ke ApiClient -- tetap jalan seperti
sebelumnya, cuma notifikasi_service yang kena fix struktur data di
atas. Migrasi service lama ditunda, bukan prioritas sekarang.

Ditemukan lewat audit sinkronisasi kontrak API dengan backend
(lihat CHANGELOG backend fase 24, 40).