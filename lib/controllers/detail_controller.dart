import 'package:get/get.dart';
import 'package:ngibrit_in/models/bike.dart';
import 'package:ngibrit_in/source/bike_source.dart';

class DetailController extends GetxController {
  final Rx<Bike> _bike = Bike.empty.obs;
  Bike get bike => _bike.value;
  set bike(Bike n) => _bike.value = n;

  final _status = ''.obs;
  String get status => _status.value;
  set status(String n) => _status.value = n;

  fetchBike(String bikeId) async {
    status = 'loading';

    final bikeDetail = await BikeSource.fetchBike(bikeId);
    if (bikeDetail == null) {
      status = 'Ada Masalah';
      return;
    }

    status = 'success';
    bike = bikeDetail;
  }
}
