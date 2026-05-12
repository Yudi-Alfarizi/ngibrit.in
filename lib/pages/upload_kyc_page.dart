import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_session/d_session.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
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

  String currentStatus = 'UNVERIFIED';
  String? rejectReason;

  // KONFIGURASI CLOUDINARY (SUDAH DISESUAIKAN)
  final String cloudName = "diwa0mfnc";
  final String uploadPreset = "ngibrit_preset";

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
  }

  void _checkCurrentStatus() async {
    final session = await DSession.getUser();
    if (session != null) {
      setState(() {
        currentStatus = session['kycStatus'] ?? 'UNVERIFIED';
        rejectReason = session['rejectReason'];
      });
    }
  }

  Future<void> pickImage(bool isKtp) async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 30, // Kompresi
    );

    if (photo != null) {
      setState(() {
        if (isKtp)
          imageKtp = File(photo.path);
        else
          imageSelfie = File(photo.path);
      });
    }
  }

  Future<String> _uploadToCloudinary(File imageFile) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(responseData);
      return jsonMap['secure_url'];
    } else {
      // Melemparkan error rinci agar mudah di-debug
      throw "Error Cloudinary [${response.statusCode}]: $responseData";
    }
  }

  Future<void> submitKyc() async {
    if (imageKtp == null || imageSelfie == null) {
      Info.error("Wajib upload Foto KTP dan Selfie!");
      return;
    }

    Info.showLoading(context, message: "Mengunggah Dokumen...");

    try {
      final userSession = await DSession.getUser();
      if (userSession == null) {
        throw "Sesi berakhir. Silakan login ulang.";
      }
      String uid = userSession['uid'];

      // 1. Upload KTP & Selfie ke Cloudinary
      String ktpUrl = await _uploadToCloudinary(imageKtp!);
      String selfieUrl = await _uploadToCloudinary(imageSelfie!);

      // 2. Simpan Link URL ke Firestore & Ubah Status ke PENDING
      await FirebaseFirestore.instance.collection('User').doc(uid).update({
        'kycStatus': 'PENDING',
        'ktpUrl': ktpUrl,
        'selfieUrl': selfieUrl,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      // 3. Update Session Lokal
      Map<String, dynamic> newSession = Map.from(userSession);
      newSession['kycStatus'] = 'PENDING';
      await DSession.setUser(newSession);

      Info.hideLoading();

      if (mounted) {
        Navigator.pop(context, true); // Sukses & Kembali
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Dokumen berhasil dikirim! Mohon tunggu validasi admin.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Info.hideLoading();
      // Pesan error spesifik akan muncul di sini (misal jika preset salah)
      Info.error(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Verifikasi Identitas",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff070623),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Color(0xff070623)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Jika status sebelumnya REJECTED, tampilkan peringatan & alasannya
          if (currentStatus == 'REJECTED')
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffFFF1F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      Gap(8),
                      Text(
                        "Verifikasi Ditolak",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  Text(
                    "Alasan: ${rejectReason ?? 'Data tidak valid'}",
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                  const Gap(4),
                  const Text(
                    "Silakan unggah ulang dokumen Anda dengan lebih jelas.",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

          const Text(
            "Panduan Upload",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Gap(8),
          const Text(
            "Posisikan KTP dan wajah Anda di tengah kamera. Pastikan pencahayaan cukup dan teks bisa dibaca.",
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

          ButtonPrimary(text: "Kirim Dokumen", onTap: submitKyc),
        ],
      ),
    );
  }

  Widget _buildUploadBox({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
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
                      const Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.grey,
                      ),
                      const Gap(8),
                      Text(
                        "Ketuk untuk ambil foto",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
