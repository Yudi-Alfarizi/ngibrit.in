import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngibrit_in/models/bike.dart';

class BikeSource {
  static Future<List<Bike>?> fetchFeaturedBikes({
    String? hubId,
    String? category,
  }) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('Bikes')
          .where('rating', isGreaterThan: 4.5)
          .orderBy('rating', descending: true);

      final queryDocs = await ref.get();
      List<Bike> bikes = queryDocs.docs
          .map((doc) => Bike.fromJson(doc.data()))
          .toList();

      // Filter Multi-kondisi di Dart (Mencegah error Firebase Index)
      if (hubId != null && hubId.isNotEmpty && hubId != 'Semua') {
        bikes = bikes.where((bike) => bike.hubId == hubId).toList();
      }
      if (category != null && category.isNotEmpty && category != 'Semua') {
        bikes = bikes
            .where(
              (bike) => bike.category.toLowerCase() == category.toLowerCase(),
            )
            .toList();
      }
      return bikes;
    } catch (e) {
      log("Error BikeSource Featured: $e");
      return null;
    }
  }

  static Future<List<Bike>?> fetchNewestBikes({
    String? hubId,
    String? category,
  }) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('Bikes')
          .orderBy('release', descending: true);

      final queryDocs = await ref.get();
      List<Bike> bikes = queryDocs.docs
          .map((doc) => Bike.fromJson(doc.data()))
          .toList();

      if (hubId != null && hubId.isNotEmpty && hubId != 'Semua') {
        bikes = bikes.where((bike) => bike.hubId == hubId).toList();
      }
      if (category != null && category.isNotEmpty && category != 'Semua') {
        bikes = bikes
            .where(
              (bike) => bike.category.toLowerCase() == category.toLowerCase(),
            )
            .toList();
      }

      return bikes.take(5).toList(); // Batasi hanya 5 terbaru setelah filter
    } catch (e) {
      log("Error BikeSource Newest: $e");
      return null;
    }
  }

  static Future<Bike?> fetchBike(String bikeId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Bikes')
          .doc(bikeId)
          .get();
      return doc.exists ? Bike.fromJson(doc.data()!) : null;
    } catch (e) {
      return null;
    }
  }
}
