import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  /// Minta izin + ambil lokasi perangkat
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception("Location service disable");
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw Exception("Permission denied");
      }
    }

    if (perm == LocationPermission.deniedForever) {
      throw Exception("Permission denied forever");
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Reverse geocoding GRATIS via Nominatim (OpenStreetMap)
  static Future<String> getAddressFromLatLng(double lat, double lon) async {
    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/reverse"
      "?lat=$lat&lon=$lon&format=json&zoom=18&addressdetails=1",
    );

    final response = await http.get(
      url,
      headers: {"User-Agent": "Flutter-App"},
    );

    if (response.statusCode != 200) return "Alamat tidak ditemukan";

    final data = jsonDecode(response.body);
    return data["display_name"] ?? "Alamat tidak ditemukan";
  }
}
