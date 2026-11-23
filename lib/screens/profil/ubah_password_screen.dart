import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/snackbar_helper.dart';

class UbahPasswordScreen extends StatefulWidget {
  const UbahPasswordScreen({super.key});

  @override
  State<UbahPasswordScreen> createState() => _UbahPasswordScreenState();
}

class _UbahPasswordScreenState extends State<UbahPasswordScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _lamaCtrl = TextEditingController();
  final _baruCtrl = TextEditingController();
  final _konfirmasiCtrl = TextEditingController();

  bool _lamaTersembunyi = true;
  bool _baruTersembunyi = true;
  bool _konfirmasiTersembunyi = true;
  bool _mengirim = false;

  // Pesan dari backend, ditaruh di field yang tepat. Null berarti tidak
  // ada penolakan server untuk field itu.
  String? _errorLama;
  String? _errorBaru;

  @override
  void dispose() {
    _lamaCtrl.dispose();
    _baruCtrl.dispose();
    _konfirmasiCtrl.dispose();
    super.dispose();
  }

  String? _ambilError(Map<String, dynamic>? errors, String key) {
    final nilai = errors?[key];
    if (nilai is List && nilai.isNotEmpty) return nilai.first.toString();
    return null;
  }

  Future<void> _submit() async {
    // Buang penolakan server sebelumnya, kalau tidak pesan lama menempel
    // di field yang sudah dibetulkan user.
    setState(() {
      _errorLama = null;
      _errorBaru = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _mengirim = true);
    final hasil = await _authService.ubahPassword(
      passwordLama: _lamaCtrl.text,
      passwordBaru: _baruCtrl.text,
    );
    if (!mounted) return;
    setState(() => _mengirim = false);

    if (hasil['success'] == true) {
      showAppSnackBar(
        context,
        hasil['message'],
        type: AppSnackBarType.success,
      );
      Navigator.of(context).pop();
      return;
    }

    final errors = hasil['errors'] as Map<String, dynamic>?;
    final lama = _ambilError(errors, 'password_lama');
    final baru = _ambilError(errors, 'password');

    if (lama != null || baru != null) {
      setState(() {
        _errorLama = lama;
        _errorBaru = baru;
      });
      // Jalankan ulang validator supaya pesan server langsung tampil.
      _formKey.currentState!.validate();
      return;
    }

    showAppSnackBar(
      context,
      hasil['message'] ?? 'Gagal mengubah password',
      type: AppSnackBarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Password')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Password Saat Ini',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lamaCtrl,
                        obscureText: _lamaTersembunyi,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: 'Password lama',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_lamaTersembunyi
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _lamaTersembunyi = !_lamaTersembunyi),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password lama wajib diisi';
                          }
                          return _errorLama;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Password Baru',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _baruCtrl,
                        obscureText: _baruTersembunyi,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: 'Password baru',
                          helperText: 'Minimal 8 karakter',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_baruTersembunyi
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _baruTersembunyi = !_baruTersembunyi),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password baru wajib diisi';
                          }
                          if (v.length < 8) {
                            return 'Password baru minimal 8 karakter';
                          }
                          if (v == _lamaCtrl.text) {
                            return 'Password baru harus berbeda dari yang lama';
                          }
                          return _errorBaru;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _konfirmasiCtrl,
                        obscureText: _konfirmasiTersembunyi,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: 'Ulangi password baru',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_konfirmasiTersembunyi
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(() =>
                                _konfirmasiTersembunyi =
                                    !_konfirmasiTersembunyi),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Konfirmasi wajib diisi';
                          }
                          if (v != _baruCtrl.text) {
                            return 'Konfirmasi tidak cocok';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Dikunci selama request berjalan. Tombol Setuju/Tolak yang
              // bisa ditekan dua kali (d7db39e) menghasilkan kotak merah
              // yang terlihat seperti kegagalan padahal aksinya berhasil.
              FilledButton(
                onPressed: _mengirim ? null : _submit,
                child: _mengirim
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan Password Baru'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}