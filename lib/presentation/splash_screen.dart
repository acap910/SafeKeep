import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';
import 'auth_screen.dart'; // Pastikan ia panggil fail auth_screen Acap

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Teks awal yang akan dipaparkan
  String _terminalText = "> SYSTEM BOOTING...";

  @override
  void initState() {
    super.initState();
    _startHackerAnimation();
  }

  // Fungsi untuk tukar teks ala-ala hacker sedang menaip
  void _startHackerAnimation() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _terminalText = "> CHECKING HARDWARE...");
    
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _terminalText = "> INITIATING AES-256 ENGINE...");
    
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _terminalText = "> SECURE CONNECTION ESTABLISHED.");
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Lepas 3 saat, automatik lompat ke skrin Log Masuk Cap Jari
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Latar belakang gelap (Hacker Vibe)
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation Radar Berpusing (Spinning Lines)
            const SpinKitSpinningLines(
              color: Colors.greenAccent,
              size: 120.0,
            ),
            const SizedBox(height: 50),
            // Teks Terminal Matrix
            Text(
              _terminalText,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 16,
                fontFamily: 'monospace', // Font ala-ala coding/mesin taip
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}