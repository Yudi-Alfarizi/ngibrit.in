import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_session/d_session.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http; // Kita pakai HTTP untuk ke Cloudinary
import 'package:image_picker/image_picker.dart';
import 'package:ngibrit_in/common/info.dart';
import 'package:ngibrit_in/widgets/button_primary.dart';

class UploadKycPage extends StatefulWidget {
  const UploadKycPage({super.key});

  @override
  State<UploadKycPage> createState() => _UploadKycPageState();
}

class _UploadKycPageState extends State<UploadKycPage> {
  File? imageKtp;
  File? imageSelfie;
  final ImagePicker _picker = ImagePicker();

  // ==========================================
  // KONFIGURASI CLOUDINARY (GANTI INI!)
  // ==========================================
  final String cloudName = "diwa0mfnc"; 
  final String uploadPreset = "ngibrit_preset"; 
  // Contoh: cloudName = "dxyz123"; uploadPreset = "ngibrit_preset";

  // Fungsi Pilih Gambar
  Future<void> pickImage(bool isKtp) async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 30, // Kompresi agar cepat
    );

    if (photo != null) {
      setState(() {
        if (isKtp) {
          imageKtp = File(photo.path);
        } else {
          imageSelfie = File(photo.path);
        }
      });
    }
  }

  // Fungsi Upload ke Cloudinary (API)
  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      // URL API Cloudinary
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      // Siapkan Request
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset // Kunci akses
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      // Kirim Request
      final response = await request.send();

      // Baca Response
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonMap = jsonDecode(responseData);
        return jsonMap['secure_url']; // Ini Link Gambar yang sudah jadi
      } else {
        print("Gagal upload Cloudinary: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error upload: $e");
      return null;
    }
  }

  Future<void> submitKyc() async {
    if (imageKtp == null || imageSelfie == null) {
      Info.error("Wajib upload Foto KTP dan Selfie!");
      return;
    }

    // Validasi Config Cloudinary (Biar tidak lupa ganti)
    if (cloudName.contains("GANTI") || uploadPreset.contains("GANTI")) {
      Info.error("Config Cloudinary belum diisi di kodingan!");
      return;
    }

    Info.showLoading(context, message: "Mengunggah ke Cloud...");

    try {
      final userSession = await DSession.getUser();
      if (userSession == null) {
        Info.hideLoading();
        return;
      }
      String uid = userSession['uid'];

      // 1. Upload KTP ke Cloudinary
      String? ktpUrl = await _uploadToCloudinary(imageKtp!);
      if (ktpUrl == null) throw "Gagal upload KTP. Cek koneksi internet.";

      // 2. Upload Selfie ke Cloudinary
      String? selfieUrl = await _uploadToCloudinary(imageSelfie!);
      if (selfieUrl == null) throw "Gagal upload Selfie.";

      // 3. Simpan Link URL ke Firestore
      await FirebaseFirestore.instance.collection('User').doc(uid).update({
        'isVerified': true,
        'ktpUrl': ktpUrl,       // Link dari Cloudinary
        'selfieUrl': selfieUrl, // Link dari Cloudinary
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      // 4. Update Session Lokal
      Map<String, dynamic> newSession = Map.from(userSession);
      newSession['isVerified'] = true;
      await DSession.setUser(newSession);

      Info.hideLoading();
      
      if (mounted) {
        Navigator.pop(context, true); // Sukses & Kembali
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verifikasi Berhasil! Silakan lanjut sewa."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Info.hideLoading();
      Info.error("Terjadi kesalahan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verifikasi Identitas", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff070623))),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Color(0xff070623)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            "Upload Dokumen",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Gap(8),
          const Text(
            "Foto akan disimpan aman di server Cloudinary & Firestore.",
            style: TextStyle(color: Colors.grey),
          ),
          const Gap(30),

          _buildUploadBox(
            title: "Foto e-KTP",
            image: imageKtp,
            onTap: () => pickImage(true),
          ),
          const Gap(24),

          _buildUploadBox(
            title: "Selfie dengan KTP",
            image: imageSelfie,
            onTap: () => pickImage(false),
          ),
          const Gap(40),

          ButtonPrimary(
            text: "Kirim & Verifikasi",
            onTap: submitKyc,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBox({required String title, required File? image, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const Gap(12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xffF3F4F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              image: image != null 
                ? DecorationImage(image: FileImage(image), fit: BoxFit.cover)
                : null,
            ),
            child: image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                      const Gap(8),
                      Text("Ketuk untuk ambil foto", style: TextStyle(color: Colors.grey[600])),
                    ],
                  )
                : null,
          ),
        ),
      ],
    );
  }
}