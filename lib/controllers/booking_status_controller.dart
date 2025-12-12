import 'package:get/get.dart';

class BookingStatusController extends GetxController {
  final RxMap _bike = {}.obs;
  Map get bike => _bike;
  set bike(Map n) => _bike.value = n;

  final RxBool flashMessageActive = false.obs;

  void activateFlashMessage() {
    flashMessageActive.value = true;
  }

  void deactivateFlashMessage() {
    flashMessageActive.value = false;
  }
}
