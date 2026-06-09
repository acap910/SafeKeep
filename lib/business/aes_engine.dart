import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AesEngine {
  final secureStorage = const FlutterSecureStorage();

  // 1. make main key (keystore)
  Future<enc.Key> getOrCreateKey() async {
    // Check kalau kunci dah wujud dalam cip selamat telefon
    String? storedKey = await secureStorage.read(key: 'master_key');
    
    if (storedKey != null) {
      return enc.Key.fromBase64(storedKey); // Guna kunci yang sedia ada
    } else {
      final newKey = enc.Key.fromSecureRandom(32); // Cipta kunci 256-bit baru
      await secureStorage.write(key: 'master_key', value: newKey.base64); // Simpan terus
      return newKey;
    }
  }

  // 2. Fungsi ENCRYPT fail gambar
  Future<Uint8List> encryptFile(Uint8List fileBytes) async {
    final key = await getOrCreateKey();
    final iv = enc.IV.fromSecureRandom(16); // IV wajib rawak untuk setiap fail
    
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

    // Gabungkan IV (16 bytes) dengan Data Sulit supaya kita boleh guna IV ni untuk Decrypt nanti
    final result = BytesBuilder();
    result.add(iv.bytes);
    result.add(encrypted.bytes);
    return result.toBytes();
  }

  // 3. Fungsi DECRYPT fail gambar
  Future<Uint8List> decryptFile(Uint8List encryptedDataWithIv) async {
    final key = await getOrCreateKey();

    // Asingkan 16 bytes pertama sebagai IV, dan bakinya sebagai Data Sulit
    final iv = enc.IV(encryptedDataWithIv.sublist(0, 16));
    final encryptedBytes = encryptedDataWithIv.sublist(16);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encryptedData = enc.Encrypted(encryptedBytes);

    final decrypted = encrypter.decryptBytes(encryptedData, iv: iv);
    return Uint8List.fromList(decrypted); // Pulangkan data gambar asal
  }
}