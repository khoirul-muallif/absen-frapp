## fix: audit modul form+list, notifikasi, dan auth

Commit: `c493872`, `879c010`, `fbb0b1b`, `727697d` (6 Nov 2026)

Lanjutan sesi yang sama, menutup sisa urutan audit per-modul. Tiga
kelas bug yang sama berulang di tujuh layar — buah dari dua perbaikan
pagi ini (`3d89e53`, `6e915ff`) yang baru kelihatan cakupannya setelah
polanya dikenali.

**`c493872`** (Izin) dan **`879c010`** (Lembur, Cuti, Dinas): `riwayat()`
di keempat service menelan `ApiException` jadi `[]`, jadi koneksi putus
tampil sebagai "Belum ada pengajuan ...". Ditambah `riwayatOrThrow()`
di masing-masing; method lama tetap ada dan mendelegasi.
`CutiService.kuota()` ikut, karena kuota yang gagal dimuat tampil
sebagai sisa 0 — menyesatkan justru saat orang hendak mengajukan.

`_batalkan` di keempatnya menghapus item sebelum request dan memanggil
`_loadData()` kalau gagal, yang mengembalikan item itu dengan `Key` yang
sama sehingga `Dismissible` yang sudah mati hidup lagi dan Flutter
melempar "A dismissed Dismissible widget is still part of the tree" —
terbukti di device pada Tukar Jadwal saat swipe offline. Semuanya pindah
ke `confirmDismiss`.

Guard FE diperiksa terhadap controller masing-masing dan ternyata sudah
benar, jadi tidak diubah: `status == 'pending'` di Lembur/Cuti/Dinas
cocok dengan `isPending()`; `jamKembali == null` di Izin cocok dengan
guard `jam_kembali === null` di `batalkan()` dan `isiJamKembali()`.
Pengecekan ini bukan formalitas — ia menggugurkan dua dari empat temuan
awal di Izin.

**`fbb0b1b`**: pola yang sama di Notifikasi, dengan satu beda —
`getNotifikasi()` sudah mengembalikan `success:false`, cuma flag-nya
diabaikan layar. Tidak perlu varian `OrThrow`. `_tandaiBaca` dan "Tandai
semua dibaca" juga mengabaikan nilai balik service sepenuhnya, jadi
menandai yang gagal tampak berhasil sampai daftar dimuat ulang.

**`727697d`**: regresi dari `3d89e53`. `getMe()` memanggil `logout()`
untuk setiap `ApiException` — benar untuk token yang ditolak server,
tapi sejak timeout pindah ke `ApiClient`, kegagalan koneksi juga datang
sebagai `ApiException`. Akibatnya membuka aplikasi tanpa sinyal
menghapus token, dan user harus login ulang padahal sesinya masih sah —
yang juga mustahil, karena dia sedang offline. Flag `isKoneksi` yang
disiapkan pagi ini dipakai persis untuk ini.

`tryAutoLogin()` berhenti mengembalikan `bool`: nilai `false`-nya
menyatukan "memang belum login" dengan "gagal konek padahal token masih
ada", dan `SplashScreen` tidak punya cara membedakannya. Diganti enum
`HasilAutoLogin`; splash berhenti di tempat dengan tombol Coba Lagi
untuk kasus ketiga. Diverifikasi di device: koneksi dimatikan lalu
aplikasi dibuka dari keadaan sudah login — berhenti di splash, dan
begitu koneksi hidup, Coba Lagi langsung masuk menu tanpa login ulang.

`LoginScreen` sekalian: controller di-`dispose()`, validasi lewat `Form`
+ `validator` (bukan menonaktifkan tombol — tombol mati tanpa
keterangan membuat orang menebak apa yang kurang), dibungkus
`SingleChildScrollView` supaya keyboard tidak bikin overflow, dan
`textInputAction` + `onFieldSubmitted` supaya tombol next/done di
keyboard berfungsi. Menutup dua item lama dari status 5 Nov.

Menutup seluruh urutan audit per-modul (level 1 & 2).

## fix: audit lintas-layar — timeout, gagal-vs-kosong, race ganti bulan

Commit: `3d89e53`, `6e915ff`, `42fd9a5`, `a0e71e0`, `e1bbdae`
(6 Nov 2026)

Lanjutan audit per-modul. Berangkat dari satu temuan lintas-modul di
sesi sebelumnya (timeout service), yang ternyata bercabang jadi dua
kelas bug yang sama berulang di tiga layar berbeda.

**`3d89e53`**: akar timeout bukan di service, tapi di `ApiClient` —
`http.get`/`post` di sana tidak punya batas waktu sama sekali, jadi
setiap request di seluruh aplikasi rentan menggantung kalau koneksi
putus di level socket. Future-nya tidak selesai dan tidak melempar,
sehingga service tidak pernah return dan layar memutar spinner
selamanya. Pola yang sama sudah ditutup di `JadwalScreen` (`624b911`)
dengan `.timeout()` di call site; cara itu tidak menskala ke sepuluh
service.

Pembungkus `_kirim()` baru dipakai `get`/`post`/`patch`/`delete`/
`postMultipart`. `TimeoutException`, `SocketException` dan
`http.ClientException` diterjemahkan jadi `ApiException`, sehingga
semua pemanggil yang sudah menangkapnya ikut terlindungi tanpa satu pun
file service disentuh. Tidak ada `catch` generik di sana — exception
lain berarti bug di kode kita. Batas 10 detik mengikuti nilai yang
sudah diuji di device untuk `JadwalScreen`; upload foto absen 45 detik,
karena gagal di sana berarti user mengulang seluruh flow wajah.

`ApiException` dapat flag `isKoneksi` untuk membedakan "tidak sampai ke
server" dari error validasi. Sekalian `_handle()` dijaga: `jsonDecode`
atas respons HTML (error 500 Laravel, 404 dari URL salah) melempar
`FormatException`, yang bukan `ApiException` dan karena itu lolos dari
semua `catch` di service.

**`6e915ff`**: `getRiwayat()`/`getRekap()` menelan `ApiException` jadi
`[]`/`null`, dan di `RiwayatScreen` akibatnya paling menyesatkan di
seluruh aplikasi — koneksi putus tampil sebagai "Belum ada data absensi
bulan ini", jadi user yang sinyalnya mati menyimpulkan dia tidak pernah
absen bulan itu. Ditambah varian `OrThrow` (pola
`sayaDalamRentangOrThrow()`, `624b911`); method lama tetap ada untuk
`home_screen.dart` yang memang tidak punya tempat menampilkan
kegagalan, tapi sekarang mendelegasi.

Tiga bug lain di layar yang sama, digabung karena menyentuh `_loadData()
dan struktur state yang sama: ganti bulan beruntun melepas beberapa
request tanpa penanda, sehingga hasil bulan lama bisa menimpa bulan di
header (ditutup dengan `_requestTerakhir`); rekap dan riwayat berjalan
berurutan padahal independen, jadi koneksi buruk berarti dua kali
timeout (digabung `Future.wait` — bukan record `.wait`, yang membungkus
penyebabnya jadi `ParallelWaitError` sehingga `on ApiException` tidak
kena); dan `ListView` tanpa `AlwaysScrollableScrollPhysics` membuat
pull-to-refresh mati justru saat daftar kosong.

**`42fd9a5`**: race ganti bulan yang sama di `JadwalScreen`, dan di sini
lebih mudah terpicu — satu swipe di kalender sudah satu halaman. Salahnya
juga tidak muncul sebagai error: titik warna di tanggal sekadar jadi
keliru tanpa tanda apa pun. `_focusedMonth` yang selama ini di-assign
tanpa `setState` dipindah ke dalam `setState` milik `_loadBulan` — bukan
dibungkus di `onPageChanged`, karena `table_calendar` bisa memicu
callback itu saat fase build masih berjalan. Pesan error tidak lagi
generik: sejak `3d89e53` kegagalan socket sampai sebagai `ApiException`,
jadi `e.message` memberi tahu user apa yang harus dilakukan.

**`a0e71e0`**: pola gagal-vs-kosong yang sama di `TukarJadwalScreen` —
koneksi putus tampil sebagai "Belum ada pengajuan" dan badge
menunggu-respon jadi 0, sehingga user bisa melewatkan permintaan rekan
yang sebenarnya menunggu dijawab. Dua request yang dipanggil terpisah
di `initState` digabung `Future.wait`, menghapus `_loadMenungguCount()`
beserta tiga pemanggilan terpisahnya.

Pembatalan pindah dari `onDismissed` ke `confirmDismiss`. Pendekatan
optimistis (hapus dulu, kembalikan kalau gagal) sempat ditulis dan
ternyata tidak bisa: Flutter mensyaratkan widget yang sudah di-dismiss
lenyap dari tree, jadi menyisipkannya kembali dengan `Key` yang sama
melempar "A dismissed Dismissible widget is still part of the tree" —
terbukti di device saat swipe dalam keadaan offline. Ongkos
`confirmDismiss`: kartu tertahan selama request berjalan.

**`e1bbdae`**: mode Pindah tidak pernah bisa dipakai karyawan umum.
`_tujuanPindahValidPredicate` mensyaratkan tanggal tujuan punya baris
`Jadwal` berjenis libur, padahal karyawan umum tidak punya baris untuk
libur mingguannya sama sekali — generator hanya membuat baris hari
kerja. Sementara `initState` memaksa semua karyawan umum ke mode Pindah,
jadi satu-satunya mode yang tersedia bagi mereka adalah mode yang tidak
bisa dipakai.

FE ternyata lebih ketat daripada backend: `ajukanPindah()` menolak hanya
kalau ada baris berjenis KERJA di tanggal tujuan; tidak ada baris sama
sekali justru diterima. Predicate disamakan. Konsekuensi yang disadari:
tanggal di luar periode assignment `KaryawanShift` ikut terbuka. Kalau
itu perlu dibatasi, batasnya harus datang dari backend — menebaknya di
FE berarti menduplikasi aturan periode assignment.

Sekalian `firstDate` di `_pilihTanggalBaru`, yang masih menyisakan
jendela mundur 30 hari; keputusan 30 Okt 2026 sudah mencabutnya dan
`_pilihTanggalAsal` sudah ikut waktu itu, yang ini terlewat.


## fix: batas waktu request service-wide + respons non-JSON

Commit: `3d89e53` (6 Nov 2026)

Temuan lintas-modul dari audit modul Absen: `getStatus()`, `getRiwayat()`
dan `getRekap()` tidak punya `.timeout()`. Akarnya bukan di service,
tapi di `ApiClient` — `http.get`/`post` di sana tidak punya batas waktu
sama sekali, jadi setiap request di seluruh aplikasi rentan menggantung
kalau koneksi putus di level socket. Future-nya tidak selesai dan tidak
melempar, sehingga service tidak pernah return dan layar memutar spinner
selamanya.

Pola yang sama sudah ditutup di `JadwalScreen` (`624b911`) dengan
`.timeout()` di call site. Cara itu benar untuk satu layar tapi tidak
menskala ke sepuluh service, dan tiap service baru harus ingat
menambahkannya sendiri — jadi di sini timeout dipindah ke lapisan HTTP.

Pembungkus `_kirim()` baru di `ApiClient` dipakai oleh `get`, `post`,
`patch`, `delete` dan `postMultipart`. `TimeoutException`,
`SocketException` dan `http.ClientException` diterjemahkan jadi
`ApiException`, sehingga semua pemanggil yang sudah menangkap
`ApiException` ikut terlindungi **tanpa satu pun file service
disentuh** — termasuk modul yang belum diaudit. Tidak ada `catch (e)`
generik di `_kirim()`: exception lain berarti bug di kode kita, dan
menelannya cuma menyulitkan pelacakan nanti.

`ApiException` dapat flag `isKoneksi` (plus konstruktor
`ApiException.koneksi()`) untuk membedakan "request tidak sampai ke
server" dari error validasi/bisnis. Belum ada pemakainya — disiapkan
untuk audit per-layar, di mana layar perlu memutuskan antara pesan
dengan tombol Coba Lagi atau pesan validasi biasa.

Batas 10 detik mengikuti nilai yang sudah diuji di device untuk
`JadwalScreen`. Upload foto absen (`postMultipart`) diberi 45 detik:
kirim JPEG lewat data seluler di dalam gedung bisa lama, dan gagal di
sana berarti user mengulang seluruh flow verifikasi wajah dari nol.

Sekalian: `_handle()` langsung `jsonDecode(res.body)` tanpa penjagaan.
Respons HTML — halaman error 500 Laravel, 404 dari URL salah, sisipan
proxy — melempar `FormatException`, yang bukan `ApiException` dan karena
itu lolos dari semua `catch` di service. Sekarang dibungkus jadi
`ApiException` dengan kode statusnya.

Diverifikasi di device dengan data seluler dan WiFi dimatikan:
`AbsenMenuScreen` mendarat di state "Gagal memuat status absen" +
tombol Coba Lagi, tidak lagi menggantung.

Belum selesai: `getStatus()`/`getRiwayat()`/`getRekap()` masih menelan
`ApiException` dan membalikkan `null`/`[]`, jadi layar belum bisa
membedakan gagal-request dari benar-benar-kosong. Untuk `getRiwayat()`
dan `getRekap()` ini lebih menyesatkan daripada di `getStatus()` —
layar menampilkan "belum ada data" seolah normal, padahal request
gagal. Perbaikannya per-layar (varian `...OrThrow()` seperti
`sayaDalamRentangOrThrow()`), menyusul di audit `riwayat_screen.dart`.

## fix: audit modul Absen — race kamera, navigator, dan masa tenggang gesture

Commit: `253a135`, `3b60b1c`, `cc15c3e`, `0adbe37`, `15fc835`,
`74d973c` (5 Nov 2026)

Audit UX modul Absen (sesi pertama dari rencana audit per-modul).
Temuan terbesar: dialog "tunggu 5-10 detik sebelum tap Absen lagi"
dari `905b9c3`/`e334d78` ternyata menutup gejala dari tiga bug
berbeda yang semuanya soal pelepasan kamera. Ketiganya dibereskan di
sini, dialognya dihapus.

**`253a135`**: dialog loading lokasi di `AbsenMenuScreen` di-pop tanpa
referensi route. Tombol back Android menutup dialog (`barrierDismissible`
tidak menahan back), lalu pop setelah GPS selesai mengenai route di
bawahnya — `AbsenMenuScreen` ikut tertutup sendiri tanpa sebab yang
jelas bagi user. Sebaliknya, kalau layar dilepas saat GPS masih
berjalan, pengecekan `mounted` mendahului pop sehingga barrier modal
menggantung di atas aplikasi. Perbaikan: `Navigator` disimpan sebelum
`await`, `PopScope(canPop: false)`, dan flag `dialogTampil` mencegah
pop ganda. Dialog sekalian diberi teks "Mencari lokasi Anda..." —
GPS di dalam gedung bisa 20-30 detik dan sebelumnya hanya spinner
tanpa keterangan. Di `StepWajah`, dialog sukses memanggil
`Navigator.of(context)` dua kali dengan context builder dialog yang
sudah tidak mounted setelah pop pertama; diganti cascade dari satu
resolusi.

**`3b60b1c`**: `IndexedStack` di kedua flow mem-build SELURUH children,
bukan cuma step aktif. Akibatnya `StepQr` sudah mounted dan memegang
kamera sejak step Lokasi, dan masih mounted saat `StepWajah` meminta
kamera depan; di flow pulang, `StepWajah` menyalakan kamera depan
sebelum layarnya terlihat. Diganti rendering kondisional lewat
`_buildStepAktif()`, sehingga step yang ditinggalkan benar-benar
ter-dispose. Selain itu `StepQr._onDetect` memanggil `_controller.stop()`
tanpa menunggunya lalu langsung `onSukses` — `StepWajah._initCamera()`
jalan sebelum `mobile_scanner` selesai melepas kamera. `stop()`
sekarang di-`await`. `_gagalDenganPeringatan` juga tidak menunggu
`_hentikanStream()`.

**`cc15c3e`**: sisa race di arah sebaliknya — keluar flow lalu masuk
lagi tanpa jeda memunculkan `MobileScannerErrorCode.controllerAlreadyInitialized`
("The scanner was already started"). `dispose()` Flutter tidak bisa
di-`await`, jadi race ini tidak bisa ditutup dari sisi pemanggil.
`autoStart` dimatikan dan `start()` dikendalikan manual: kalau kena
error itu, `stop()` dulu lalu coba lagi, maksimal 5 kali dengan jeda
400ms. Lewat dari itu baru tampil pesan dengan tombol "Coba Lagi",
jadi user tidak perlu keluar-masuk flow untuk memulihkannya. Pesan
error tidak lagi menampilkan `errorCode` mentah ke user.

**`0adbe37`**: efek samping tak terduga dari perbaikan di atas — karena
kamera sekarang didapat bersih sejak awal, image stream langsung
mengalir saat user masih memposisikan HP, sehingga kedipan refleks
biasa (sebelum instruksi sempat dibaca) langsung meloloskan verifikasi.
Dikonfirmasi lewat `git diff 752f889..HEAD` bahwa logika deteksi tidak
tersentuh sama sekali, jadi ini bukan regresi. Secara keamanan tidak
bocor (kedipan refleks tetap membuktikan ada orang hidup), tapi
kejelasannya rusak. Gesture sekarang baru dinilai 1,5 detik setelah
kamera siap; selama masa itu `_pernahTertutup` dan `_frameSenyumBerturut`
di-reset tiap frame. Masa tenggang ditambahkan ke timeout total supaya
tidak memakan jatah 20 detik. Ambang senyum sengaja dibiarkan 0.70 —
menaikkannya berdasar satu device berisiko membuat senyum tipis gagal
terus, dan kegagalan berulang lebih menyakitkan daripada lolos
kecepatan.

**`15fc835`**: dialog "tunggu 5-10 detik" dihapus dari kedua flow.
Diverifikasi di device pada dua jalur kegagalan — timeout verifikasi
wajah, dan QR salah yang ditolak backend — keduanya mendarat dengan
benar dan kamera langsung bisa dipakai lagi tanpa jeda. Keluar dari
flow sekarang `pop()` satu kali ke menu Absen, bukan `popUntil` ke
root: melempar user sampai Beranda hanya masuk akal selama kamera
butuh waktu bernapas, dan mendarat di menu Absen membuat retry cukup
satu tap.

**`74d973c`**: perbaikan UX setelah bug fungsional beres. `_StepIndicator`
ternyata punya daftar label sejak awal (`['Lokasi', 'Scan QR', 'Wajah']`)
tapi hanya dipakai `.length`-nya — user melihat lingkaran bernomor tanpa
keterangan dan tidak tahu angka 2 itu QR atau wajah. Label sekarang
dirender di bawah tiap lingkaran, dan garis penghubung ikut berwarna saat
step-nya sudah lewat (sebelumnya selalu abu). Judul AppBar
`AbsenFlowScreen` diubah 'Absen' → 'Absen Masuk'; sebelumnya identik
dengan judul menu Absen sehingga setelah masuk flow tidak ada penanda ini
masuk atau pulang.

Keluar dari flow di tengah jalan minta konfirmasi lewat `PopScope`, tapi
hanya kalau `_currentStep > _stepAwal` — ada progres yang benar-benar
hilang. Praktisnya dialog cuma muncul di flow masuk pada step wajah
(QR sudah ter-scan); flow pulang mulai langsung di step wajah sehingga
back tetap langsung keluar. `PopScope` hanya mencegat back sistem dan
tombol back AppBar, jadi dialog sukses dan `_kembaliKeMenu` tidak
terpengaruh.

Nilai konfirmasi ini diakui tipis (yang hilang cuma scan QR ulang,
beberapa detik) dan sempat dipertimbangkan untuk dihapus — diputuskan
dipertahankan karena biayanya nol di alur normal.

Menutup technical debt "retry QR/wajah rebutan hardware kamera".

## feat: statistik kehadiran di Beranda + restrukturisasi navigasi

Commit: `5b87ba1`, `439f89d`, `0bb3778`, `6f70fcb` (5 Nov 2026)

Empat commit merombak Beranda — dari grid menu datar tanpa informasi
apa pun jadi punya ringkasan kehadiran, dan navigasi dipindah dari
"semuanya di grid" ke pembagian app bar / bottom nav / grid.

**`5b87ba1`**: kartu profil dapat section statistik dari
`GET /api/absensi/rekap` (persentase tepat waktu, total hadir,
terlambat, alpha, label bulan). Backend sudah menghitung semuanya
termasuk persentase, jadi FE murni fetch & tampilkan — nol duplikasi
logic agregasi. Loading state sengaja tanpa spinner: section statistik
tidak muncul sama sekali selama fetching atau kalau gagal, kartu tetap
valid tanpanya (konsisten pola `?? '-'` yang sudah dipakai di file
ini). Terlambat diwarnai oranye dan alpha merah hanya kalau nilainya
> 0, supaya nol tidak ikut terbaca sebagai peringatan.

Catatan model: `RekapAbsen` berada di `models/riwayat_absen_model.dart`
satu file dengan `RiwayatAbsenItem`, bukan di `absensi_model.dart`
seperti dugaan awal — sempat bikin `undefined_class` di analyze.
Field `sakit` di model itu tidak pernah diisi backend (`rekap()` tidak
mengirimnya) sehingga selalu 0; sengaja tidak dipakai di tampilan
daripada menampilkan angka yang dijamin salah.

**`439f89d`**: ikon logout di app bar diganti ikon notifikasi, dan
`_MenuItem` "Notifikasi" dihapus dari grid — notifikasi adalah
informasi yang perlu terlihat terus, bukan tujuan yang dicari di
daftar menu. Logout pindah ke `PopupMenuButton` (ikon akun) bersama
"Profil" dan "Ubah Password". Dua item terakhir masih berupa snackbar
"Fitur ini akan segera hadir", bukan screen kosong atau dialog
setengah jadi — lebih jujur ke user daripada pura-pura fiturnya ada.
Endpoint backend untuk update email/password belum dipastikan ada,
dicatat di todo-fr.md (`620ad67`).

**`0bb3778`**: ikon notifikasi dapat `Badge.count` dari
`NotifikasiService.getJumlahBelumBaca()` — endpoint khusus yang sudah
ada, tidak perlu fetch seluruh list cuma untuk ambil angka. `onPressed`
dibuat async supaya badge di-refresh begitu user kembali dari
`NotifikasiScreen`; tanpa itu angkanya basi sampai Beranda rebuild.
Service sudah menelan `ApiException` dan mengembalikan 0, jadi gagal
fetch berarti badge tidak muncul, bukan crash. Belum di-refresh saat
berpindah antar tab bottom nav — technical debt kecil, dicatat.

**`6f70fcb`**: file baru `main_screen.dart` sebagai shell berisi
`NavigationBar` 3 tab (Beranda / Riwayat / Informasi) di atas
`IndexedStack`, supaya state tiap tab tidak reset saat berpindah.
Riwayat dihapus dari grid (grid jadi 7 item) dan `RiwayatScreen`
dipasang apa adanya sebagai tab — Scaffold+AppBar miliknya dibiarkan
utuh, tidak dibongkar, karena shell sengaja tidak punya AppBar sendiri.
Tab Informasi diisi `informasi_screen.dart` baru berupa empty state
("Belum ada informasi"), bukan placeholder "segera hadir": layar ini
memang bisa kosong nanti saat fiturnya sudah jalan tapi belum ada
pengumuman, jadi widget-nya tidak perlu diganti lagi. Model + endpoint
Informasi belum ada sama sekali di backend, dicatat di todo.md
backend (`absensi-app` commit `d97ace9`).

Titik masuk di `splash_screen.dart` dan `login_screen.dart` dialihkan
dari `HomeScreen` ke `MainScreen` — tanpa ini `MainScreen` jadi kode
mati dan bottom nav tidak pernah terpasang (sempat terjadi saat
testing). Logout tetap `pushAndRemoveUntil` ke `LoginScreen`, jadi
`MainScreen` beserta state ketiga tab ikut dibuang saat keluar.

Struktur navigasi mengikuti aplikasi absensi lama yang dipakai sebagai
referensi (Riwayat + Informasi di footer). Gaya visualnya belum
diikuti sama sekali — kartu melengkung, ikon bulat berwarna per
kategori, ring chart kehadiran, tombol Presensi di tengah bottom nav
— sengaja ditunda sampai audit UX per-modul selesai biar tidak nabrak
perubahan struktural. Dicatat sebagai item todo-fr.md tersendiri
(`ea998cc`).

## feat: layar Jadwal (kalender bulanan) + terhubung ke form Tukar/Pindah

Commit: `ebadafb`, `624b911`, `1bf42b0` (30 Okt 2026)

Tiga commit merombak akses ke jadwal — sebelumnya karyawan sama sekali
tidak punya cara melihat jadwalnya sendiri dalam bentuk kalender
(item lama todo-fr.md "Layar Jadwal belum ada sama sekali").

**`ebadafb`**: layar baru `lib/screens/jadwal/jadwal_screen.dart`,
dibuka lewat tile "Jadwal" di grid Beranda. Pakai package
`table_calendar` (baru ditambah ke pubspec) — tiap tanggal ditandai
titik warna sesuai `jenis` (hijau=reguler/piket "Kerja", abu=libur,
oranye=cuti, ungu=dinas), tap tanggal menampilkan detail card di bawah
kalender, geser bulan fetch ulang data. Sengaja tidak membuat
model/service baru — `JadwalItem`/`JadwalService` sudah ada duluan
(dipakai form TukarJadwal), layar ini cuma jadi consumer baru dari
`sayaDalamRentang()` yang sudah ada, tanpa mengubah kontraknya.

Parsing tanggal `'d M Y'` (format backend, nama bulan Inggris) dikunci
locale `en_US` eksplisit di parser lokal layar ini
(`DateFormat('d MMM yyyy', 'en_US')`) — tidak boleh ikut locale default
device yang `id_ID`, akan gagal mencocokkan nama bulan kalau tidak.

**`624b911`**: `sayaDalamRentang()` menelan `ApiException` dan
membalikkan `[]` (desain lama, wajar untuk prefetch form TukarJadwal),
sehingga di `JadwalScreen` gagal-request dan benar-benar-kosong tampil
identik — dan saat koneksi terputus total, loading indicator berjalan
tanpa batas (request HTTP tidak punya timeout, exception tidak pernah
terpicu). Fix: `JadwalService.sayaDalamRentangOrThrow()` baru (tidak
menelan exception, method lama tidak disentuh), dipakai dengan
`.timeout(10 detik)` + `catch` generik (bukan cuma `ApiException`,
supaya error koneksi level socket ikut tertangkap). State baru
menampilkan card merah "Gagal memuat jadwal bulan ini" + tombol Coba
Lagi. Dikonfirmasi di device: WiFi dimatikan saat buka/geser bulan,
card error muncul setelah ~10 detik.

**`1bf42b0`**: detail card di `JadwalScreen` dapat tombol "Ajukan
Tukar/Pindah" yang membuka `TukarJadwalFormScreen` dengan tanggal yang
dipilih sudah ter-prefill (`tanggalAwal` baru). Section "Jadwal Saya"
di form dibedakan tampilannya tergantung sumber: dari `JadwalScreen`,
tampil ringkas tanpa ikon kalender + keterangan "Tanggal dipilih dari
layar Jadwal" dan tombol teks "Ubah" (unlock balik ke date picker biasa
kalau salah tap) — sebelumnya menampilkan `ListTile` + ikon kalender
yang sama persis seperti user baru mau memilih tanggal, padahal sudah
dipilih di layar sebelumnya, terasa double. Form yang dibuka langsung
dari tile "Tukar Jadwal" di Beranda (floating action button, tanpa
`tanggalAwal`) tampilannya tidak berubah.

Menutup item lama todo-fr.md "Layar Jadwal belum ada sama sekali" dan
technical debt "JadwalScreen tidak bisa membedakan gagal-request dari
benar-benar-kosong".

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