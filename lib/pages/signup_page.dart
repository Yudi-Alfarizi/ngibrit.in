import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ngibrit_in/common/info.dart';
import 'package:ngibrit_in/source/auth_source.dart';
import 'package:ngibrit_in/widgets/button_primary.dart';
import 'package:ngibrit_in/widgets/button_secondary.dart';
import 'package:ngibrit_in/widgets/input.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final edtName = TextEditingController();
  final edtEmail = TextEditingController();
  final edtPassword = TextEditingController();

  createNewAccount() {
    if (edtName.text == '') return Info.error('Nama harus diisi!');
    if (edtEmail.text == '') return Info.error('Email harus diisi!');
    if (edtPassword.text == '') return Info.error('Password harus diisi!');

    Info.showLoading(context, message: 'Membuat akun...');

    AuthSource.signUp(
      edtName.text,
      edtEmail.text,
      edtPassword.text
    ).then((message){
      Info.hideLoading(); // tutup loading saat proses selesai
      if(message != 'success')return Info.error(message);

      // success
      Info.success('Sukses Mendaftar');
      Future.delayed(const Duration(milliseconds: 1500),() {
        Navigator.pushReplacementNamed(context, '/signin');
      });

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        children: [
          const Gap(80),
          Image.asset('assets/logo_text.png', height: 36, width: 149),
          const Gap(70),
          const Text(
            'Buat Akun Baru',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xff070623),
            ),
          ),
          const Gap(30),
          const Text(
            'Nama Lengkap',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff070623),
            ),
          ),
          const Gap(12),
          Input(
            icon: 'assets/ic_profile.png',
            hint: 'Masukkan nama lengkap',
            editingController: edtName,
          ),
          const Gap(20),
          const Text(
            'Alamat Email',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff070623),
            ),
          ),
          const Gap(12),
          Input(
            icon: 'assets/ic_email.png',
            hint: 'Masukkan email aktif',
            editingController: edtEmail,
          ),
          const Gap(20),
          const Text(
            'Kata Sandi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff070623),
            ),
          ),
          const Gap(12),
          Input(
            icon: 'assets/ic_key.png',
            hint: 'Masukkan kata sandi',
            editingController: edtPassword,
            obsecure: true,
          ),
          Gap(30),
          ButtonPrimary(text: 'Buat Akun Baru', onTap: createNewAccount),
          Gap(30),
          const DottedLine(
            dashLength: 6,
            dashGapLength: 6,
            dashColor: Color(0xffCECED5),
          ),
          Gap(30),
          ButtonSecondary(text: 'Sudah Punya Akun?', onTap: () {
            Navigator.pushReplacementNamed(context, '/signin');
          }),
          Gap(30),
        ],
      ),
    );
  }
}
