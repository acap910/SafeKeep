import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

class AesEngine {
  // Kunci Rahsia 256-bit (Wajib 32 aksara)
  final _key = encrypt.Key.fromUtf8('SafeKeepSuperSecretKey1234567890');
  // Initialization Vector (IV) - 16 aksara
  final _iv = encrypt.IV.fromUtf8('SafeKeepInitVec1');

  // Mod Asal (Default)
  encrypt.AESMode currentMode = encrypt.AESMode.gcm;

  // Fungsi untuk tukar mod dari Skrin Settings
  void setMode(String modeName) {
    if (modeName == 'CBC') currentMode = encrypt.AESMode.cbc;
    else if (modeName == 'GCM') currentMode = encrypt.AESMode.gcm;
    else if (modeName == 'CTR') currentMode = encrypt.AESMode.ctr;
  }

  Future<Uint8List> encryptFile(Uint8List data) async {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: currentMode));

    // Mula Stopwatch ⏱️
    final stopwatch = Stopwatch()..start();

    final encrypted = encrypter.encryptBytes(data, iv: _iv);

    // Henti Stopwatch 🛑
    stopwatch.stop();

    // Cetak keputusan di Terminal VS Code
    debugPrint("\n====================================");
    debugPrint("📊 [EKSPERIMEN FYP - ENCRYPTION]");
    debugPrint("Mod AES     : ${currentMode.toString().split('.').last.toUpperCase()}");
    debugPrint("Saiz Fail   : ${(data.length / (1024 * 1024)).toStringAsFixed(2)} MB");
    debugPrint("Masa Diambil: ${stopwatch.elapsedMilliseconds} ms");
    debugPrint("====================================\n");

    return Uint8List.fromList(encrypted.bytes);
  }

  Future<Uint8List> decryptFile(Uint8List encryptedData) async {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: currentMode));
    final encrypted = encrypt.Encrypted(encryptedData);

    // Mula Stopwatch ⏱️
    final stopwatch = Stopwatch()..start();

    final decrypted = encrypter.decryptBytes(encrypted, iv: _iv);

    // Henti Stopwatch 🛑
    stopwatch.stop();

    // Cetak keputusan di Terminal VS Code
    debugPrint("\n====================================");
    debugPrint("📊 [EKSPERIMEN FYP - DECRYPTION]");
    debugPrint("Mod AES     : ${currentMode.toString().split('.').last.toUpperCase()}");
    debugPrint("Masa Diambil: ${stopwatch.elapsedMilliseconds} ms");
    debugPrint("====================================\n");

    return Uint8List.fromList(decrypted);
  }
}