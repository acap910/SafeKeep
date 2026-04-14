import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Panggil pakej animation
import 'vault_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  Future<void> _authenticate(BuildContext context) async {
    final LocalAuthentication auth = LocalAuthentication();
    
    try {
      // Format versi lama yang stabil (biometricOnly terus di sini)
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access SafeKeep',
        biometricOnly: true, 
      );

      if (didAuthenticate) {
        debugPrint("Authentication successful!");
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const VaultScreen()),
          );
        }
      } else {
        debugPrint("Authentication failed or canceled.");
      }
    } catch (e) {
      debugPrint("Biometric error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[800],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const Text('SafeKeep', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            const Text('AES-256 Secure Vault', style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 80),
            
            GestureDetector(
              onTap: () => _authenticate(context),
              child: Column(
                children: [
                  // --- BAHAGIAN ANIMATION GEMPAK BERMULA DI SINI ---
                  SizedBox(
                    height: 150, 
                    width: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1. Gelombang radar berdegup kat belakang (SpinKitPulse)
                        const SpinKitPulse(
                          color: Colors.amber,
                          size: 150.0,
                        ),
                        // 2. Butang cap jari kekal kat tengah
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue[900], // Warna gelap sikit untuk nampak timbul
                          ),
                          child: const Icon(Icons.fingerprint, size: 60, color: Colors.amber),
                        ),
                      ],
                    ),
                  ),
                  // --- BAHAGIAN ANIMATION TAMAT ---
                  
                  const SizedBox(height: 15),
                  const Text('Touch to Authenticate', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text('Hardware-Backed Keystore', style: TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}