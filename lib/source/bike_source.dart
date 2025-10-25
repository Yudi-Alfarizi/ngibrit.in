import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngibrit_in/models/bike.dart';

class BikeSource {
  static Future<List<Bike>?> fetchFeaturedBikes() async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('Bikes')
          .where('rating', isGreaterThan: 4.5)
          .orderBy('rating',descending: true);
      final queryDocs = await ref.get();
      return queryDocs.docs.map((doc) => Bike.fromJson(doc.data())).toList();
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  static Future<List<Bike>?> fetchNewestBikes() async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('Bikes')
          .orderBy('release', descending: true)
          .limit(5);
      final queryDocs = await ref.get();
      return queryDocs.docs.map((doc) => Bike.fromJson(doc.data())).toList();
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  static Future<Bike?> fetchBikes(String bikeId) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('Bikes')
          .doc(bikeId);
      final doc = await ref.get();
      Bike? bike = doc.exists ? Bike.fromJson(doc.data()!) : null;
      return bike;
    } catch (e) {
      log(e.toString());
      return null;
    }
  }
}
