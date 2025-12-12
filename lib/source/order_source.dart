import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngibrit_in/models/order_model.dart';

class OrderSource {
  static Future<OrderModel?> getActiveOrder(String uid) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('Orders')
          .where('userId', isEqualTo: uid)
          .where(
            'status',
            whereIn: ['Dikirim', 'Berlangsung', 'Menunggu Pembayaran'],
          )
          .orderBy(
            'createdAt',
            descending: true,
          )
          .limit(1);

      final queryDocs = await ref.get();
      if (queryDocs.docs.isNotEmpty) {
        return OrderModel.fromJson(
          queryDocs.docs.first.data(),
          queryDocs.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      print("Error fetching active order: $e");
      return null;
    }
  }

  static Stream<QuerySnapshot> getOrders(String uid, String status) {
    return FirebaseFirestore.instance
        .collection('Orders')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<bool> updateStatus(String orderId, String newStatus) async {
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
