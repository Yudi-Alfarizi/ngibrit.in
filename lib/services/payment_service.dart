import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  // TODO: Ganti URL di bawah ini dengan URL Vercel Anda yang baru!
  // Pastikan JANGAN ADA garis miring (/) di akhir URL.
  static const String _baseUrl = 'https://backend-ngibrit.vercel.app';

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
      // [PERBAIKAN] Penambahan Timeout 15 detik agar UI tidak stuck jika server mati
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              "orderId": orderId,
              "amount": amount,
              "itemDetails": [
                {
                  "id": "motor-rent",
                  "price": amount,
                  "quantity": 1,
                  // Mencegah error karakter panjang dari Midtrans
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
          )
          .timeout(const Duration(seconds: 15));

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
