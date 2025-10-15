import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ngibrit_in/widgets/button_primary.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Gap(70),
          Image.asset('assets/logo_text.png', height: 36, width: 149),
          const Gap(10),
          const Text(
            'Ngibrit Tanpa Ribet!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Color(0xff070623),
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(-50, 0), 
              child: Image.asset('assets/splash_vespa.png'),
            )),
          const Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              textAlign: TextAlign.center,
              'Sewa motor cepat, mudah, dan siap jalan kapan aja! Tinggal klik, langsung ngibrit!',
              style: TextStyle(
                height: 1.7,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xff070623),
              ),
            ),
          ),
          const Gap(30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ButtonPrimary(text: 'Explore Now', onTap: () {
              Navigator.pushReplacementNamed(context, '/signup');
            }),
          ),
          const Gap(50),
        ],
      ),
    );
  }
}
