import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:local_auth/local_auth.dart'; 
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

  Future<void> _viewEncryptedImage(FileSystemEntity file) async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Sila sahkan identiti untuk melihat fail rahsia',
      );

      if (didAuthenticate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sedang membuka fail...')),
          );
        }

        File encryptedFile = File(file.path);
        Uint8List encryptedBytes = await encryptedFile.readAsBytes();

        Uint8List decryptedBytes = await _aesEngine.decryptFile(encryptedBytes);

        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent, 
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Image.memory(decryptedBytes), 
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
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

        Uint8List encryptedBytes = await _aesEngine.encryptFile(fileBytes);

        Directory appDocDir = await getApplicationDocumentsDirectory();
        String safePath = '${appDocDir.path}/gambar_rahsia_${DateTime.now().millisecondsSinceEpoch}.enc';

        File encryptedFile = File(safePath);
        await encryptedFile.writeAsBytes(encryptedBytes);

        await _loadEncryptedFiles();

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

  // FUNGSI BARU: Padam fail dari storage
  Future<void> _deleteEncryptedFile(FileSystemEntity file, String fileName) async {
    try {
      await file.delete(); // Padam fail fizikal dari telefon
      await _loadEncryptedFiles(); // Refresh UI
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fileName telah dipadam.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal memadam fail: $e");
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

                // WIDGET BARU: Membolehkan kita swipe ke kiri untuk padam
                return Dismissible(
                  key: Key(file.path), // Kunci unik untuk setiap item
                  direction: DismissDirection.endToStart, // Swipe dari kanan ke kiri sahaja
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white, size: 30),
                  ),
                  onDismissed: (direction) {
                    _deleteEncryptedFile(file, fileName); // Panggil fungsi padam bila habis swipe
                  },
                  child: Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.lock, color: Colors.amber, size: 40),
                      title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('AES-256 Encrypted'),
                      trailing: const Icon(Icons.remove_red_eye, color: Colors.blue),
                      onTap: () => _viewEncryptedImage(file),
                    ),
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