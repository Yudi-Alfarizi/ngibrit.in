import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ngibrit_in/common/info.dart';
import 'package:ngibrit_in/source/auth_source.dart';
import 'package:ngibrit_in/widgets/button_primary.dart';
import 'package:ngibrit_in/widgets/button_secondary.dart';
import 'package:ngibrit_in/widgets/input.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final edtEmail = TextEditingController();
  final edtPassword = TextEditingController();

  signIn() {
    if (edtEmail.text == '') return Info.error('Email harus diisi!');
    if (edtPassword.text == '') return Info.error('Password harus diisi!');

    Info.showLoading(context, message: 'Loading..');

    AuthSource.signIn(edtEmail.text, edtPassword.text).then((
      message,
    ) {
      Info.hideLoading(); // tutup loading saat proses selesai
      if (message != 'success') return Info.error(message);

      // success
      Info.success('Sukses Masuk');
      Future.delayed(const Duration(milliseconds: 1500), () {
        Navigator.pushReplacementNamed(context, '/discover');
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
            'Masuk ke Akun',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xff070623),
            ),
          ),
          const Gap(30),
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
          ButtonPrimary(text: 'Masuk', onTap: signIn),
          Gap(30),
          const DottedLine(
            dashLength: 6,
            dashGapLength: 6,
            dashColor: Color(0xffCECED5),
          ),
          Gap(30),
          ButtonSecondary(
            text: 'Buat Akun Baru',
            onTap: () {
              Navigator.pushReplacementNamed(context, '/signup');
            },
          ),
          Gap(30),
        ],
      ),
    );
  }
}
