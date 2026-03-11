import 'package:flutter/material.dart';
import 'presentation/auth_screen.dart'; // Kita panggil fail skrin log masuk tadi

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
      // Tukar home kepada AuthScreen()
      home: const AuthScreen(),
    );
  }
}