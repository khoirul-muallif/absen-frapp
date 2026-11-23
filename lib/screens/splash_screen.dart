import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import '../services/instansi_storage.dart';
import '../widgets/logo_instansi.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _instansiStorage = InstansiStorage();
  String? _logoInstansi;
  bool _gagalKoneksi = false;

  @override
  void initState() {
    super.initState();
    _muatIdentitasInstansi();
    _checkLogin();
  }

  /// Logo dari login sebelumnya. Instalasi baru menampilkan placeholder.
  Future<void> _muatIdentitasInstansi() async {
    final tersimpan = await _instansiStorage.baca();
    if (!mounted) return;
    setState(() => _logoInstansi = tersimpan.logo);
  }

  Future<void> _checkLogin() async {
    if (_gagalKoneksi) setState(() => _gagalKoneksi = false);

    final authProvider = context.read<AuthProvider>();
    final hasil = await authProvider.tryAutoLogin();

    if (!mounted) return;

    // Gagal konek bukan berarti belum login. Melempar user ke LoginScreen
    // di sini percuma — dia juga tidak bisa login tanpa koneksi, dan
    // sesinya sebenarnya masih sah.
    if (hasil == HasilAutoLogin.gagalKoneksi) {
      setState(() => _gagalKoneksi = true);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => hasil == HasilAutoLogin.berhasil
            ? const MainScreen()
            : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LogoInstansi(url: _logoInstansi, ukuran: 64),
              const SizedBox(height: 16),
              if (_gagalKoneksi) ...[
                const Text(
                  'Tidak bisa terhubung ke server.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Periksa koneksi Anda, lalu coba lagi.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: _checkLogin,
                  child: const Text('Coba Lagi'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Masuk dengan akun lain'),
                ),
              ] else
                const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}