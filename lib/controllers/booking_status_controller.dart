import 'package:get/get.dart';

class BookingStatusController extends GetxController {
  // Variable existing (jika ada logika lain)
  final RxMap _bike = {}.obs;
  Map get bike => _bike;
  set bike(Map n) => _bike.value = n;

  // [BARU] Variable untuk mengontrol Flash Message 10 Detik
  // Default false. Hanya jadi true saat user klik tombol di Success Page.
  final RxBool flashMessageActive = false.obs;

  void activateFlashMessage() {
    flashMessageActive.value = true;
  }

  void deactivateFlashMessage() {
    flashMessageActive.value = false;
  }
}
