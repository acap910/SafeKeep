import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'vault_screen.dart'; // Memanggil fail skrin Vault yang kita buat tadi

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  // Fungsi untuk panggil pop-up cap jari
  Future<void> _authenticate(BuildContext context) async {
    final LocalAuthentication auth = LocalAuthentication();
    
    try {
      // Panggil fungsi biometrik (Cap jari/Face ID/PIN)
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Sila sahkan identiti untuk masuk ke SafeKeep',
      );

      // Kalau cap jari SAH dan berjaya
      if (didAuthenticate) {
        debugPrint("Fuhh berjaya masuk! Cap jari sah.");
        
        // Pastikan context masih ada sebelum melompat ke skrin lain
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const VaultScreen()),
          );
        }
      } else {
        // Kalau batal atau cap jari salah
        debugPrint("Gagal! Sila cuba lagi.");
      }
    } catch (e) {
      debugPrint("Ada error biometrik: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[800], // Latar belakang biru gelap
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikon Shield (Perisai)
            const Icon(
              Icons.security,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            
            // Tajuk SafeKeep
            const Text(
              'SafeKeep',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            
            // Subtajuk AES-256
            const Text(
              'AES-256 Secure Vault',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 80), // Jarak ke butang cap jari
            
            // Butang Biometrik (Cap Jari)
            GestureDetector(
              onTap: () => _authenticate(context), // Panggil fungsi biometrik bila ditekan
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      size: 60,
                      color: Colors.amber, // Warna ikon kuning
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Touch to Authenticate',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Teks bawah
            const Text(
              'Hardware-Backed Keystore',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}