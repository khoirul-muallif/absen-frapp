class UserModel {
  final int id;
  final String nama;
  final String nip;
  final String email;
  final String jabatan;
  final String unitKerja;
  final String statusPegawai;
  final String role;
  final String tipeJadwal; // 'umum' | 'rotasi'
  final String? fotoProfil;
  final int instansiId;
  final String instansiNama;

  UserModel({
    required this.id,
    required this.nama,
    required this.nip,
    required this.email,
    required this.jabatan,
    required this.unitKerja,
    required this.statusPegawai,
    required this.role,
    required this.tipeJadwal,
    this.fotoProfil,
    required this.instansiId,
    required this.instansiNama,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nama: json['nama'] ?? '',
      nip: json['nip'] ?? '',
      email: json['email'] ?? '',
      jabatan: json['jabatan'] ?? '',
      unitKerja: json['unit_kerja'] ?? '',
      statusPegawai: json['status_pegawai'] ?? '',
      role: json['role'] ?? 'karyawan',
      tipeJadwal: json['tipe_jadwal'] ?? 'umum',
      fotoProfil: json['foto_profil'],
      instansiId: json['instansi']?['id'] ?? 0,
      instansiNama: json['instansi']?['nama'] ?? '',
    );
  }
  /// Email bisa kosong: backend fase 81 membuat kolomnya nullable karena
  /// tidak semua karyawan RS punya email. Login memakai username, jadi
  /// kosong tidak mengunci siapa pun di luar.
  bool get punyaEmail => email.isNotEmpty;
}