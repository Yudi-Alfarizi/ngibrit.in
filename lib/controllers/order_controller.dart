import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_session/d_session.dart';
import 'package:get/get.dart';
import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/models/bike.dart';
import 'package:ngibrit_in/models/order_model.dart';
import 'package:ngibrit_in/source/order_source.dart';

class OrderController extends GetxController {
  /// Fungsi untuk membuat order baru
  Future<bool> createOrder({
    required Bike bike,
    required String startDate,
    required String endDate,
    required int duration,
    required num totalPrice,
    required String paymentMethod,
    required String userPhone,
    required String renterName, // [FIX] Wajib: Nama Penyewa dari Input Booking
    
    // Parameter opsional dengan default value
    String pickupLocation = '-',
    String returnLocation = '-',
    String agency = '-',
    String insuranceName = 'Standard',
    num insurancePrice = 0,
    num tax = 0,
    num subTotal = 0,
  }) async {
    try {
      // 1. Ambil data user yang sedang login dari Session (Hanya untuk ID & Email)
      final userSession = await DSession.getUser();
      if (userSession == null) return false;

      final account = Account.fromJson(Map.from(userSession));

      // 2. Buat Object OrderModel
      final newOrder = OrderModel(
        id: '', // ID akan digenerate otomatis oleh Firestore
        userId: account.uid,
        userName: renterName, // [FIX] Gunakan nama dari input booking, BUKAN account.name
        userEmail: account.email,
        userPhone: userPhone, 
        
        // Simpan Snapshot Data Motor
        bikeSnapshot: {
          'id': bike.id,
          'name': bike.name,
          'image': bike.image,
          'category': bike.category,
          'price': bike.price,
          'rating': bike.rating,
        },

        startDate: startDate,
        endDate: endDate,
        duration: duration,

        pickupLocation: pickupLocation,
        returnLocation: returnLocation,
        agency: agency,

        insuranceName: insuranceName,
        insurancePrice: insurancePrice,
        tax: tax,
        subTotal: subTotal,

        totalPrice: totalPrice,
        paymentMethod: paymentMethod,

        status: 'Dikirim', // Status Awal
        createdAt: Timestamp.now(),
      );

      // 3. Kirim ke OrderSource untuk disimpan ke Firestore
      bool success = await OrderSource.addOrder(newOrder);

      return success;
    } catch (e) {
      print("Error di OrderController: $e");
      return false;
    }
  }
}