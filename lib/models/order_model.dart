import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final Map<String, dynamic> bikeSnapshot;
  final String startDate;
  final String endDate;
  final int duration;
  final String pickupLocation;
  final String returnLocation;
  final String insuranceName;
  final num insurancePrice;
  final num tax;
  final num subTotal;
  final num totalPrice;
  final String paymentMethod;
  final String status;
  final Timestamp createdAt;
  final num deliveryFee;
  final num securityDeposit;
  final bool isDelivery;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.bikeSnapshot,
    required this.startDate,
    required this.endDate,
    required this.duration,
    required this.pickupLocation,
    required this.returnLocation,
    required this.insuranceName,
    required this.insurancePrice,
    required this.tax,
    required this.subTotal,
    required this.totalPrice,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.deliveryFee = 0,
    this.securityDeposit = 0,
    this.isDelivery = false,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json, String docId) {
    return OrderModel(
      id: docId,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userPhone: json['userPhone'] ?? '',
      bikeSnapshot: json['bikeSnapshot'] ?? {},
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      duration: json['duration'] ?? 0,
      pickupLocation: json['pickupLocation'] ?? '-',
      returnLocation: json['returnLocation'] ?? '-',
      insuranceName: json['insuranceName'] ?? '-',
      insurancePrice: json['insurancePrice'] ?? 0,
      tax: json['tax'] ?? 0,
      subTotal: json['subTotal'] ?? 0,
      totalPrice: json['totalPrice'] ?? 0,
      paymentMethod: json['paymentMethod'] ?? '',
      status: json['status'] ?? 'Dikirim',
      createdAt: json['createdAt'] ?? Timestamp.now(),
      deliveryFee: json['deliveryFee'] ?? 0,
      securityDeposit: json['securityDeposit'] ?? 0,
      isDelivery: json['isDelivery'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'bikeSnapshot': bikeSnapshot,
      'startDate': startDate,
      'endDate': endDate,
      'duration': duration,
      'pickupLocation': pickupLocation,
      'returnLocation': returnLocation,
      'insuranceName': insuranceName,
      'insurancePrice': insurancePrice,
      'tax': tax,
      'subTotal': subTotal,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt,
      'deliveryFee': deliveryFee,
      'securityDeposit': securityDeposit,
      'isDelivery': isDelivery,
    };
  }
}
