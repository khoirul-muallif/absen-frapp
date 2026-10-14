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