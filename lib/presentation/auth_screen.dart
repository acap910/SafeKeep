import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'vault_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  Future<void> _authenticate(BuildContext context) async {
    final LocalAuthentication auth = LocalAuthentication();
    
    try {
      final bool didAuthenticate = await auth.authenticate(
        // Tukar ayat biometrik ke Bahasa Inggeris
        localizedReason: 'Please authenticate to access SafeKeep',
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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: const Icon(Icons.fingerprint, size: 60, color: Colors.amber),
                  ),
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