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
  bool _isValidLocation = true;
  bool _isAddressLoading = false;

  @override
  void initState() {
    super.initState();
    selectedLatLng =
        widget.initialPosition ?? const LatLng(-6.175392, 106.827153);

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
      setState(() => selectedLatLng = newPos);
      _reverseGeocode(newPos);
    } catch (e) {
      debugPrint("Error location: $e");
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();

      setState(() {
        selectedLatLng = camera.center;
        _isAddressLoading = true;
      });

      debounceTimer = Timer(const Duration(milliseconds: 800), () {
        _reverseGeocode(camera.center);
      });
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    final url =
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&accept-language=id&addressdetails=1";
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'ngibrit_in_app'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        String displayName = data["display_name"] ?? "Lokasi tidak diketahui";

        Map<String, dynamic> addressDetails = data['address'] ?? {};
        String state = (addressDetails['state'] ?? '').toString().toLowerCase();

        // [PERBAIKAN] Cakupan Seluruh Pulau Jawa
        List<String> javaProvinces = [
          'banten',
          'jakarta',
          'jawa barat',
          'jawa tengah',
          'yogyakarta',
          'jawa timur',
        ];

        bool isInJava =
            javaProvinces.any((prov) => state.contains(prov)) ||
            displayName.toLowerCase().contains('jawa');

        if (mounted) {
          setState(() {
            selectedAddress = displayName;
            _isValidLocation = isInJava;
            _isAddressLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          selectedAddress = "Gagal memuat alamat";
          _isAddressLoading = false;
        });
      }
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
              _isAddressLoading = true;
            });
            _mapController.move(latLng, 17);
            _reverseGeocode(latLng);
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
                userAgentPackageName: 'com.example.ngibrit_in',
              ),
            ],
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(
                Icons.location_on,
                size: 50,
                color: Color(0xffFF2055),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(blurRadius: 5, color: Colors.black12),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
                const Gap(10),
                Expanded(
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
                        boxShadow: [
                          const BoxShadow(
                            blurRadius: 10,
                            color: Colors.black12,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const Gap(10),
                          Expanded(
                            child: Text(
                              _isAddressLoading
                                  ? "Memuat alamat..."
                                  : selectedAddress,
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
              ],
            ),
          ),
          Positioned(
            bottom: 240,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _locateUser,
              child: _isLocating
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: Color(0xff4A1DFF)),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black12)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Lokasi Terpilih:",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Gap(4),
                  Text(
                    _isAddressLoading
                        ? "Sedang memvalidasi..."
                        : selectedAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff070623),
                    ),
                  ),
                  const Gap(16),
                  if (_isValidLocation)
                    ButtonPrimary(
                      text: "Gunakan Lokasi Ini",
                      onTap: _isAddressLoading
                          ? () {}
                          : () {
                              if (selectedLatLng != null) {
                                Navigator.pop(context, {
                                  'lat': selectedLatLng!.latitude,
                                  'lng': selectedLatLng!.longitude,
                                  'address': selectedAddress,
                                });
                              }
                            },
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffFFF1F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xffFF2055).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xffFF2055),
                          ),
                          const Gap(10),
                          const Expanded(
                            child: Text(
                              "Lokasi di luar jangkauan. Silakan pilih area Pulau Jawa.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xffFF2055),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
