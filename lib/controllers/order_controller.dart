import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_session/d_session.dart';
import 'package:get/get.dart';
import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/models/bike.dart';
import 'package:ngibrit_in/models/order_model.dart';
import 'package:ngibrit_in/services/payment_service.dart';

class OrderController extends GetxController {
  Future<Map<String, dynamic>> createOrder({
    required Bike bike,
    required String startDate,
    required String endDate,
    required int duration,
    required num totalPrice,
    required String paymentMethod,
    required String userPhone,
    required String renterName,
    required String pickupLocation,
    required String returnLocation,
    required String agency,
    required String insuranceName,
    required num insurancePrice,
    required num tax,
    required num subTotal,
    // [BARU] Parameter Tambahan
    required num deliveryFee,
    required num securityDeposit,
    required bool isDelivery,
  }) async {
    try {
      final userSession = await DSession.getUser();
      if (userSession == null)
        return {'success': false, 'message': 'Session expired'};
      final account = Account.fromJson(Map.from(userSession));

      final docRef = FirebaseFirestore.instance.collection('Orders').doc();
      final orderId = docRef.id;

      // Status Awal
      String initialStatus =
          (paymentMethod == 'Lainnya' || paymentMethod == 'Transfer')
          ? 'Menunggu Pembayaran'
          : 'Dikirim';

      final newOrder = OrderModel(
        id: orderId,
        userId: account.uid,
        userName: renterName,
        userEmail: account.email,
        userPhone: userPhone,

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

        status: initialStatus,
        createdAt: Timestamp.now(),

        // [BARU] Simpan Data Tambahan
        deliveryFee: deliveryFee,
        securityDeposit: securityDeposit,
        isDelivery: isDelivery,
      );

      await docRef.set(newOrder.toJson());

      // --- Logika MIDTRANS ---
      if (paymentMethod == 'Lainnya') {
        final paymentData = await PaymentService.createTransaction(
          orderId: orderId,
          amount: totalPrice.toInt(),
          itemName: "Sewa ${bike.name} ($duration Hari)",
          customerName: renterName,
          customerEmail: account.email,
          customerPhone: userPhone,
        );

        if (paymentData != null && paymentData['redirect_url'] != null) {
          return {
            'success': true,
            'isMidtrans': true,
            'redirectUrl': paymentData['redirect_url'],
            'orderId': orderId,
            'bike': bike,
          };
        } else {
          return {'success': false, 'message': 'Gagal koneksi ke pembayaran'};
        }
      }

      return {'success': true, 'isMidtrans': false};
    } catch (e) {
      print("Error di OrderController: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Fungsi Update Status Manual (Dipanggil setelah WebView Sukses)
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('Orders').doc(orderId).update(
        {'status': newStatus},
      );

      return true;
    } catch (e) {
      print("Error updating status: $e");
      return false;
    }
  }
}
