import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_session/d_session.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:ngibrit_in/common/info.dart';
import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/widgets/button_primary.dart';
import 'package:ngibrit_in/widgets/input.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final edtName = TextEditingController();
  final edtPhone = TextEditingController();
  Account? account;

  File? imageProfile;
  final ImagePicker _picker = ImagePicker();

  // KONFIGURASI CLOUDINARY
  final String cloudName = "diwa0mfnc";
  final String uploadPreset = "ngibrit_preset";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final data = await DSession.getUser();
    if (data != null) {
      setState(() {
        account = Account.fromJson(Map.from(data));
        edtName.text = account?.name ?? '';
        edtPhone.text = account?.phoneNumber ?? '';
      });
    }
  }

  Future<void> pickImage() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery, // Pakai galeri untuk profil
      imageQuality: 30,
    );

    if (photo != null) {
      setState(() {
        imageProfile = File(photo.path);
      });
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(await response.stream.bytesToString());
        return jsonMap['secure_url'];
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveProfile() async {
    if (edtName.text.isEmpty) {
      Info.error("Nama tidak boleh kosong");
      return;
    }

    Info.showLoading(context, message: "Menyimpan...");

    try {
      String? newProfileUrl = account?.profileUrl;

      // Jika user memilih gambar baru, upload ke Cloudinary dulu
      if (imageProfile != null) {
        String? uploadedUrl = await _uploadToCloudinary(imageProfile!);
        if (uploadedUrl != null) {
          newProfileUrl = uploadedUrl;
        } else {
          throw "Gagal mengunggah foto profil";
        }
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('User')
          .doc(account!.uid)
          .update({
            'name': edtName.text.trim(),
            'phoneNumber': edtPhone.text.trim(),
            if (newProfileUrl != null) 'profileUrl': newProfileUrl,
          });

      // Update Session Lokal
      final oldSession = await DSession.getUser();
      Map<String, dynamic> newSession = Map.from(oldSession!);
      newSession['name'] = edtName.text.trim();
      newSession['phoneNumber'] = edtPhone.text.trim();
      if (newProfileUrl != null) newSession['profileUrl'] = newProfileUrl;

      await DSession.setUser(newSession);

      Info.hideLoading();

      if (mounted) {
        Info.success("Profil berhasil diperbarui");
        Navigator.pop(context, true); // Kembali & berikan sinyal sukses
      }
    } catch (e) {
      Info.hideLoading();
      Info.error("Gagal menyimpan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Profil",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff070623),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xff070623)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // FOTO PROFIL
          Center(
            child: Stack(
              children: [
                ClipOval(
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: imageProfile != null
                        ? Image.file(imageProfile!, fit: BoxFit.cover)
                        : (account?.profileUrl != null
                              ? Image.network(
                                  account!.profileUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/profile.png',
                                  fit: BoxFit.cover,
                                )),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xff4A1DFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(30),

          // FORM NAMA & HP
          const Text(
            "Nama Lengkap",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const Gap(8),
          Input(
            icon: 'assets/ic_profile.png',
            hint: 'Nama Lengkap',
            editingController: edtName,
          ),
          const Gap(20),

          const Text(
            "Nomor Handphone",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const Gap(8),
          Input(
            icon: 'assets/ic_telephone.png',
            hint: '628...',
            editingController: edtPhone,
            keyboardType: TextInputType.number,
          ),
          const Gap(40),

          ButtonPrimary(text: "Simpan Perubahan", onTap: _saveProfile),
        ],
      ),
    );
  }
}
