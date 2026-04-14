import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; 
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

  // FUNGSI BUKA FAIL (VERSI ASAL YANG STABIL)
  Future<void> _viewEncryptedImage(FileSystemEntity file) async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to view this secure file',
        biometricOnly: true, 
      );

      if (didAuthenticate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Decrypting file... Please wait.')),
          );
        }

        File encryptedFile = File(file.path);
        var encryptedBytes = await encryptedFile.readAsBytes();
        var decryptedBytes = await _aesEngine.decryptFile(encryptedBytes);

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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication canceled.'), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // FUNGSI ENCRYPT GAMBAR (DENGAN ANIMATION SPINKIT)
  Future<void> _pickAndEncryptImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false, 
            builder: (BuildContext context) {
              return const Dialog(
                backgroundColor: Colors.transparent, 
                elevation: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitRipple(color: Colors.amber, size: 120.0),
                    SizedBox(height: 20),
                    Text(
                      "Encrypting with AES-256...\nSecuring your file",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              );
            },
          );
        }

        await Future.delayed(const Duration(milliseconds: 1500));

        File originalFile = File(image.path);
        var fileBytes = await originalFile.readAsBytes();
        var encryptedBytes = await _aesEngine.encryptFile(fileBytes);

        Directory appDocDir = await getApplicationDocumentsDirectory();
        String safePath = '${appDocDir.path}/secure_img_${DateTime.now().millisecondsSinceEpoch}.enc';

        File encryptedFile = File(safePath);
        await encryptedFile.writeAsBytes(encryptedBytes);

        await _loadEncryptedFiles();

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Success! Image encrypted and saved.'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteEncryptedFile(FileSystemEntity file, String fileName) async {
    try {
      await file.delete(); 
      await _loadEncryptedFiles(); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fileName has been deleted.'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      debugPrint("Failed to delete file: $e");
    }
  }

  Future<void> _confirmDelete(BuildContext context, FileSystemEntity file, String fileName) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete File?"),
          content: const Text("Are you sure you want to permanently delete this encrypted file?"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
                _deleteEncryptedFile(file, fileName); 
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Secure Vault'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: _encryptedFiles.isEmpty
          ? const Center(
              child: Text(
                'No encrypted files found.\nTap the + button to add an image.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.85, 
              ),
              itemCount: _encryptedFiles.length,
              itemBuilder: (context, index) {
                final file = _encryptedFiles[index];
                final fileName = file.path.split('/').last;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: InkWell(
                    onTap: () => _viewEncryptedImage(file), 
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock, color: Colors.amber, size: 60),
                                const SizedBox(height: 15),
                                Text(
                                  fileName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis, 
                                ),
                                const SizedBox(height: 5),
                                const Text('AES-256', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _confirmDelete(context, file, fileName),
                          ),
                        ),
                      ],
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