import 'presentation/splash_screen.dart'; // Ubah ikut laluan folder Acap
import 'package:flutter/material.dart';

void main() {
  runApp(const SafeKeepApp());
}

class SafeKeepApp extends StatelessWidget {
  const SafeKeepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeKeep',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Tukar home kepada()
      home: const SplashScreen(),
    );
  }
}