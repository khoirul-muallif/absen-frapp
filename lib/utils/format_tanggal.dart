/// Dua kebutuhan yang berbeda, sengaja dipisah.
///
/// Sebelumnya tiap form punya satu `_formatTanggal()` yang mengembalikan
/// `yyyy-MM-dd` — formatnya benar untuk dikirim ke backend, tapi dipakai
/// juga untuk ditampilkan, jadi karyawan melihat "2026-11-25" di layar.
/// Itu format mesin, bukan untuk dibaca orang.
library;

const _namaBulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Untuk DIKIRIM ke backend. Jangan dipakai di layar.
String tanggalUntukApi(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Untuk DITAMPILKAN ke karyawan: "25 Nov 2026".
///
/// Nama bulannya Indonesia, beda dari yang dikirim backend (Carbon
/// memakai nama bulan Inggris). Itu disengaja — yang dari backend
/// ditampilkan apa adanya, yang dibentuk di FE pakai bahasa Indonesia.
String tanggalUntukLayar(DateTime d) =>
    '${d.day} ${_namaBulan[d.month - 1]} ${d.year}';