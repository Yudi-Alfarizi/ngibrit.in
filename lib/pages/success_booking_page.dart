import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:ngibrit_in/controllers/booking_status_controller.dart';
import 'package:ngibrit_in/models/bike.dart';
import 'package:ngibrit_in/widgets/button_primary.dart';
import 'package:ngibrit_in/widgets/button_secondary.dart';

class SuccessBookingPage extends StatelessWidget {
  const SuccessBookingPage({super.key, required this.bike});
  final Bike bike;

  @override
  Widget build(BuildContext context) {
    final bookingStatusCtrl = Get.put(BookingStatusController());

    return Scaffold(
      backgroundColor: const Color(0xffF8F8FA),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const Gap(60),
          const Text(
            'Success Booking\nHave a Great Ride!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: Color(0xff070623),
            ),
          ),
          const Gap(50),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Image.asset('assets/ellipse.png', fit: BoxFit.fitWidth),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ExtendedImage.network(
                  bike.image,
                  height: 200,
                  fit: BoxFit.fitHeight,
                  cache: true,
                ),
              ),
            ],
          ),
          const Gap(40),
          Text(
            bike.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Color(0xff070623),
            ),
          ),
          Text(
            bike.category,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Color(0xff838384),
            ),
          ),
          const Gap(50),
          ButtonPrimary(
            text: 'Pemesanan Motor Lainnya',
            onTap: () {
              bookingStatusCtrl.activateFlashMessage();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/discover',
                (route) => false,
                arguments: {'initialIndex': 0},
              );
            },
          ),
          const Gap(12),

          ButtonSecondary(
            text: 'Lihat Pesanan Saya',
            onTap: () {
              bookingStatusCtrl.activateFlashMessage();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/discover',
                (route) => false,
                arguments: {'initialIndex': 1},
              );
            },
          ),
          const Gap(30),
        ],
      ),
    );
  }
}
