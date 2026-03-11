import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:local_auth/local_auth.dart'; // Panggil biometrik
import '../business/aes_engine.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final ImagePicker _picker = ImagePicker();
  final AesEngine _aesEngine = AesEngine();
  List<FileSystemEntity> _encryptedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadEncryptedFiles();
  }

  Future<void> _loadEncryptedFiles() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> files = appDocDir.listSync().where((file) => file.path.endsWith('.enc')).toList();
    setState(() {
      _encryptedFiles = files;
    });
  }

  // FUNGSI BARU: Buka dan Decrypt Gambar
  Future<void> _viewEncryptedImage(FileSystemEntity file) async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      // 1. Minta cap jari sebelum benarkan file decrypt
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Sila sahkan identiti untuk melihat fail rahsia',
      );

      if (didAuthenticate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sedang membuka fail...')),
          );
        }

        // 2. Baca data mangga (encrypted)
        File encryptedFile = File(file.path);
        Uint8List encryptedBytes = await encryptedFile.readAsBytes();

        // 3. Buka mangga (Decrypt) guna enjin AES
        Uint8List decryptedBytes = await _aesEngine.decryptFile(encryptedBytes);

        // 4. Paparkan gambar secara Pop-up (Volatile Memory)
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent, // Belakang kosong
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Image.memory(decryptedBytes), // Papar gambar dari memori (tak save ke phone)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.of(context).pop(), // Tutup gambar
                    ),
                  ],
                ),
              );
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat Decrypt: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickAndEncryptImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sedang mengunci gambar... Sila tunggu.')),
          );
        }

        File originalFile = File(image.path);
        Uint8List fileBytes = await originalFile.readAsBytes();

        // Guna enjin AES yang baru dikemas kini
        Uint8List encryptedBytes = await _aesEngine.encryptFile(fileBytes);

        Directory appDocDir = await getApplicationDocumentsDirectory();
        String safePath = '${appDocDir.path}/gambar_rahsia_${DateTime.now().millisecondsSinceEpoch}.enc';

        File encryptedFile = File(safePath);
        await encryptedFile.writeAsBytes(encryptedBytes);

        await _loadEncryptedFiles(); // Refresh senarai

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Berjaya dikunci!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ralat: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Secure Vault'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _encryptedFiles.isEmpty
          ? const Center(
              child: Text(
                'Tiada fail disulitkan setakat ini.\nTekan butang + untuk tambah gambar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _encryptedFiles.length,
              itemBuilder: (context, index) {
                final file = _encryptedFiles[index];
                final fileName = file.path.split('/').last;

                return Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.lock, color: Colors.amber, size: 40),
                    title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('AES-256 Encrypted'),
                    trailing: const Icon(Icons.remove_red_eye, color: Colors.blue),
                    onTap: () => _viewEncryptedImage(file), // Buka fungsi Pop-up bila ditekan!
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndEncryptImage,
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}