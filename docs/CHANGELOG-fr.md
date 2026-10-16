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