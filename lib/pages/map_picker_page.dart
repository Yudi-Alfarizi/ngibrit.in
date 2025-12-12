import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gap/gap.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:ngibrit_in/widgets/button_primary.dart';
import 'package:ngibrit_in/pages/search_location_page.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng? initialPosition;
  const MapPickerPage({super.key, this.initialPosition});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final MapController _mapController = MapController();
  LatLng? selectedLatLng;
  String selectedAddress = "Mencari lokasi...";
  Timer? debounceTimer;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    selectedLatLng =
        widget.initialPosition ?? const LatLng(-6.200000, 106.816666);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPosition != null) {
        _reverseGeocode(widget.initialPosition!);
      } else {
        _locateUser();
      }
    });
  }
  Future<void> _locateUser() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position pos = await Geolocator.getCurrentPosition();
      LatLng newPos = LatLng(pos.latitude, pos.longitude);

      _mapController.move(newPos, 17);
      selectedLatLng = newPos;
      _reverseGeocode(newPos);
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 800), () {
        selectedLatLng = camera.center;
        _reverseGeocode(camera.center);
      });
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    final url =
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&accept-language=id";
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'ngibrit_in_app'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted)
          setState(
            () => selectedAddress =
                data["display_name"] ?? "Lokasi tidak diketahui",
          );
      }
    } catch (_) {
      if (mounted) setState(() => selectedAddress = "Gagal memuat alamat");
    }
  }
  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchLocationPage(
          onSelected: (latLng, address) {
            setState(() {
              selectedLatLng = latLng;
              selectedAddress = address;
            });
            _mapController.move(latLng, 17);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: selectedLatLng!,
              initialZoom: 16,
              onPositionChanged: _onMapPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
            ],
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_on, size: 50, color: Colors.red),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: _openSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        selectedAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _locateUser,
              child: _isLocating
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ButtonPrimary(
              text: "Gunakan Lokasi Ini",
              onTap: () {
                if (selectedLatLng != null) {
                  Navigator.pop(context, {
                    'lat': selectedLatLng!.latitude,
                    'lng': selectedLatLng!.longitude,
                    'address': selectedAddress,
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
