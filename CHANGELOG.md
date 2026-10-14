fase 8: ApiClient terpusat + fix bug notifikasi baca struktur lama

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