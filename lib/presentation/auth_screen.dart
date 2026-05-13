import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:ui'; // Diperlukan untuk efek blur/kaca
import 'vault_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Teks terminal yang akan berubah ikut situasi
  String _authStatus = "> SYSTEM LOCKED. AWAITING BIOMETRIC...";
  Color _statusColor = Colors.grey;

  Future<void> _authenticate(BuildContext context) async {
    // Bila jari ditekan, tukar teks jadi scanning
    setState(() {
      _authStatus = "> SCANNING IDENTITY...";
      _statusColor = Colors.cyanAccent;
    });

    final LocalAuthentication auth = LocalAuthentication();

    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access SafeKeep',
        biometricOnly: true,
      );

      if (didAuthenticate) {
        // Jika berjaya, tukar teks hijau dan tunggu 0.6 saat sblm masuk vault
        setState(() {
          _authStatus = "> IDENTITY VERIFIED. ACCESS GRANTED.";
          _statusColor = Colors.greenAccent;
        });
        await Future.delayed(const Duration(milliseconds: 600)); 
        
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const VaultScreen()),
          );
        }
      } else {
        // Jika batal/salah, tukar teks merah
        setState(() {
          _authStatus = "> ACCESS DENIED. PLEASE TRY AGAIN.";
          _statusColor = Colors.redAccent;
        });
      }
    } catch (e) {
      setState(() {
        _authStatus = "> BIOMETRIC SENSOR ERROR.";
        _statusColor = Colors.redAccent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21), // Latar belakang Cyberpunk (Biru sangat gelap)
      body: Stack(
        children: [
          // =========================================================
          // 1. EFEK CAHAYA HOLOGRAM (GLASSMORPHISM)
          // =========================================================
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.cyanAccent.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Filter blur untuk bagi efek cermin wasap (Glass effect)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60.0, sigmaY: 60.0),
            child: Container(color: Colors.transparent),
          ),

          // =========================================================
          // 2. KONTEN UTAMA
          // =========================================================
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo & Tajuk 
                  const Icon(Icons.security, size: 70, color: Colors.cyanAccent),
                  const SizedBox(height: 15),
                  const Text(
                    'SafeKeep',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'AES-256 ENCRYPTED NETWORK',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // =========================================================
                  // 3. PENGIMBAS CAP JARI (FUTURISTIC SCANNER)
                  // =========================================================
                  GestureDetector(
                    onTap: () => _authenticate(context),
                    child: SizedBox(
                      height: 220,
                      width: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Gelombang radar luar
                          const SpinKitRipple(
                            color: Colors.cyanAccent,
                            size: 220.0,
                            borderWidth: 3.0,
                          ),
                          // Gelombang denyut dalam 
                          SpinKitPulse(
                            color: Colors.cyanAccent.withValues(alpha: 0.5),
                            size: 150.0,
                          ),
                          // Bulatan butang cap jari bersinar
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF111A3A), 
                              border: Border.all(
                                color: Colors.cyanAccent,
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyanAccent.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.fingerprint,
                              size: 60,
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // =========================================================
                  // 4. TEKS STATUS TERMINAL 
                  // =========================================================
                  Text(
                    _authStatus,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Footer
                  const Text(
                    'HARDWARE-BACKED KEYSTORE',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white38,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}