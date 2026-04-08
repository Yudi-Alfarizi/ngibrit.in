import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_session/d_session.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
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

  Future<void> _saveProfile() async {
    if (edtName.text.isEmpty) {
      Info.error("Nama tidak boleh kosong");
      return;
    }

    Info.showLoading(context, message: "Menyimpan...");

    try {
      // 1. Update Firestore
      await FirebaseFirestore.instance
          .collection('User')
          .doc(account!.uid)
          .update({
            'name': edtName.text.trim(),
            'phoneNumber': edtPhone.text.trim(),
          });

      // 2. Update Session Lokal
      // Kita perlu ambil data lama, lalu timpa dengan yang baru
      final oldSession = await DSession.getUser();
      Map<String, dynamic> newSession = Map.from(oldSession!);
      newSession['name'] = edtName.text.trim();
      newSession['phoneNumber'] = edtPhone.text.trim();

      await DSession.setUser(newSession);

      Info.hideLoading();

      if (mounted) {
        Info.success("Profil berhasil diperbarui");
        Navigator.pop(context, true); // Kembali dengan sinyal sukses
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
