import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart'; 
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
  
  int _failedAttempts = 0; 
  int _currentIndex = 0;

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

  // =========================================================
  // FUNGSI UI & LOGIK SEDIA ADA (Dikekalkan 100%)
  // =========================================================
  void _showPremiumToast(String message, IconData icon, Color bgColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2), 
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        elevation: 10, 
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, 
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SpinKitRipple(color: Colors.amber, size: 120.0),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDecoyImage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, 
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Image.asset('assets/decoy.jpg'), 
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

  Future<void> _viewEncryptedImage(FileSystemEntity file) async {
    if (_failedAttempts >= 3) {
      if (mounted) {
        _showPremiumToast('Decrypting file... Please wait.', Icons.lock_open, Colors.blue);
      }
      _showDecoyImage();
      return; 
    }

    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to view this secure file',
        biometricOnly: true, 
      );

      if (didAuthenticate) {
        setState(() { _failedAttempts = 0; });
        if (mounted) { _showLoadingDialog("Decrypting with AES-256...\nUnlocking file"); }
        await Future.delayed(const Duration(milliseconds: 1500)); 

        File encryptedFile = File(file.path);
        var encryptedBytes = await encryptedFile.readAsBytes();
        var decryptedBytes = await _aesEngine.decryptFile(encryptedBytes);

        if (mounted) {
          Navigator.of(context).pop(); 
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
        setState(() { _failedAttempts++; });
        if (mounted) {
          _showPremiumToast('Authentication Failed. Attempt $_failedAttempts/3', Icons.warning_amber_rounded, Colors.orange);
        }
        if (_failedAttempts >= 3) { _showDecoyImage(); }
      }
    } on PlatformException catch (e) {
      if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        if (mounted) { _showPremiumToast('Decrypting file... Please wait.', Icons.lock_open, Colors.blue); }
        _showDecoyImage();
      } else {
        setState(() { _failedAttempts++; });
        if (mounted) { _showPremiumToast('Biometric Error: ${e.message}', Icons.error_outline, Colors.red); }
      }
    } catch (e) {
      if (mounted) { _showPremiumToast('Error: $e', Icons.error_outline, Colors.red); }
    }
  }

  Future<void> _pickAndEncryptImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        if (mounted) { _showLoadingDialog("Encrypting with AES-256...\nSecuring your file"); }
        await Future.delayed(const Duration(milliseconds: 1500));

        File originalFile = File(image.path);
        var fileBytes = await originalFile.readAsBytes();
        var encryptedBytes = await _aesEngine.encryptFile(fileBytes);

        Directory appDocDir = await getApplicationDocumentsDirectory();
        String safePath = '${appDocDir.path}/secure_img_${DateTime.now().millisecondsSinceEpoch}.enc';

        File encryptedFile = File(safePath);
        await encryptedFile.writeAsBytes(encryptedBytes);

        await _loadEncryptedFiles();

        setState(() { _currentIndex = 0; });

        if (mounted) {
          Navigator.of(context).pop(); 
          _showPremiumToast('Success! File securely locked.', Icons.verified_user, Colors.green.shade700);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); 
        _showPremiumToast('Error: $e', Icons.error_outline, Colors.red);
      }
    }
  }

  Future<void> _deleteEncryptedFile(FileSystemEntity file, String fileName) async {
    try {
      await file.delete(); 
      await _loadEncryptedFiles(); 
      if (mounted) {
        _showPremiumToast('File permanently deleted.', Icons.delete_forever, Colors.redAccent);
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
          title: const Text("Delete File?", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Are you sure you want to permanently delete this encrypted file?"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); 
                _deleteEncryptedFile(file, fileName); 
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // FUNGSI WIDGET TAB VIEWS
  // =========================================================
  Widget _buildImageGallery() {
    return _encryptedFiles.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 15),
                const Text(
                  'No secure images found.\nTap + to encrypt a new image.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 80),
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
                              const Icon(Icons.lock, color: Colors.amber, size: 50),
                              const SizedBox(height: 15),
                              Text(
                                fileName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis, 
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('AES-256', style: TextStyle(fontSize: 9, color: Colors.black54, fontWeight: FontWeight.bold)),
                              ),
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
          );
  }

  Widget _buildComingSoon(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("Coming Soon", style: TextStyle(fontSize: 14, color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BINAAN UTAMA UI (SCAFFOLD)
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      
      // HEADER BARU: Gradient Premium (Versi Security Dashboard Tanpa Nama)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110.0), // Tinggi sikit untuk dashboard look
        child: Container(
          padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)], // Deep Purple ke Magenta
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Kiri: Ikon Perisai & Teks Log
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield, color: Colors.amber, size: 28),
                      const SizedBox(width: 10),
                      const Text(
                        "SafeKeep Vault",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const Text(
                    "Advanced AES-256 Protection",
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              // Kanan: Status Animation
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SpinKitPulse( // Guna animation sedia ada
                    color: Colors.greenAccent,
                    size: 30.0,
                  ),
                  const Text("SYSTEM", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 8),),
                  const Text("SECURE", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 10),)
                ],
              ),
            ],
          ),
        ),
      ),

      body: _currentIndex == 0 ? _buildImageGallery() :
            _currentIndex == 1 ? _buildComingSoon("Video Vault", Icons.video_library) :
            _currentIndex == 2 ? _buildComingSoon("PDF Vault", Icons.picture_as_pdf) :
            _buildComingSoon("Settings", Icons.settings),

      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndEncryptImage,
        backgroundColor: Colors.pinkAccent, 
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.image, "Images", 0),
              _buildNavItem(Icons.play_circle_fill, "Videos", 1),
              const SizedBox(width: 40), 
              _buildNavItem(Icons.picture_as_pdf, "PDFs", 2),
              _buildNavItem(Icons.settings, "Settings", 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            color: isSelected ? const Color(0xFF4A00E0) : Colors.grey[400],
            size: isSelected ? 28 : 24,
          ),
          const SizedBox(height: 2),
          Text(
            label, 
            style: TextStyle(
              fontSize: 10, 
              color: isSelected ? const Color(0xFF4A00E0) : Colors.grey[400],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}