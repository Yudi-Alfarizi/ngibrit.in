import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String _baseUrl =
      'https://ngibrit-backend-gtogk4jbd-alfarizis-projects-433387c5.vercel.app';

  static Future<Map<String, dynamic>?> createTransaction({
    required String orderId,
    required int amount,
    required String itemName,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    final url = Uri.parse('$_baseUrl/api/charge');

    print("--- MULAI REQUEST KE BACKEND ---");
    print("URL: $url");
    print("Data dikirim: OrderID: $orderId, Amount: $amount");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "orderId": orderId,
          "amount": amount,
          "itemDetails": [
            {
              "id": "motor-rent",
              "price": amount,
              "quantity": 1,
              "name": itemName.length > 50
                  ? itemName.substring(0, 49)
                  : itemName,
            },
          ],
          "customerDetails": {
            "first_name": customerName,
            "email": customerEmail,
            "phone": customerPhone,
          },
        }),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print("GAGAL: Backend menolak request.");
        return null;
      }
    } catch (e) {
      print("EXCEPTION (Koneksi Gagal): $e");
      return null;
    }
  }
}
