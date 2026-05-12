import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngibrit_in/models/hub.dart';

class HubSource {
  // Fungsi untuk mengambil semua cabang untuk filter Browse
  static Future<List<Hub>> fetchHubs() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('hubs')
          .orderBy('name')
          .get();
      return snapshot.docs
          .map((doc) => Hub.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Fungsi untuk mengambil detail 1 cabang saat halaman Checkout/Booking
  static Future<Hub?> getHub(String id) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('hubs')
          .doc(id)
          .get();
      if (doc.exists) return Hub.fromJson(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
    return null;
  }
}
