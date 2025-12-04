import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngibrit_in/models/order_model.dart';

class OrderSource {
  // 1. Simpan Order Baru
  static Future<bool> addOrder(OrderModel order) async {
    try {
      await FirebaseFirestore.instance.collection('Orders').add(order.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  // 2. Ambil List Order berdasarkan Status
  static Stream<QuerySnapshot> getOrders(String userId, String status) {
    return FirebaseFirestore.instance
        .collection('Orders')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 3. Update Status Order
  static Future<bool> updateStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('Orders')
          .doc(docId)
          .update({'status': newStatus});
      return true;
    } catch (e) {
      return false;
    }
  }

  // 4. [FIX] Tambahkan Method ini: Ambil Pesanan Aktif untuk Home
  static Future<OrderModel?> getActiveOrder(String userId) async {
    try {
      // Cari pesanan yang statusnya BUKAN Selesai (artinya Dikirim atau Berlangsung)
      final snap = await FirebaseFirestore.instance
          .collection('Orders')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['Dikirim', 'Berlangsung'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      if (snap.docs.isNotEmpty) {
        return OrderModel.fromJson(snap.docs.first.data(), snap.docs.first.id);
      }
      return null;
    } catch (e) {
      print("Error getActiveOrder: $e");
      return null;
    }
  }
}