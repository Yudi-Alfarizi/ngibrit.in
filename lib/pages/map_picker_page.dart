// lib/pages/map_picker_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../widgets/button_primary.dart';
import 'search_location_page.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng? initialPosition;
  final Function(LatLng position, String address) onLocationPicked;

  const MapPickerPage({
    super.key,
    required this.onLocationPicked,
    this.initialPosition,
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final MapController _mapController = MapController();

  LatLng? selectedLatLng;
  String selectedAddress = "";
  Timer? debounceTimer;
  StreamSubscription<MapEvent>? _mapSub;

  @override
  void initState() {
    super.initState();
    selectedLatLng = widget.initialPosition ?? LatLng(-6.200000, 106.816666);
    // subscribe safely after a frame so mapController is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // register single subscription
      _mapSub = _mapController.mapEventStream.listen((event) {
        try {
          // Try to extract center dynamically from the event
          final dyn = event as dynamic;
          final center = dyn.center as LatLng?;
          if (center != null) _onMapMoveEnd(center);
        } catch (e) {
          // ignore; some event types don't have center
        }
      });
      // optionally move to initial position if provided
      if (widget.initialPosition != null) {
        _mapController.move(widget.initialPosition!, 16);
        _reverseGeocode(widget.initialPosition!);
      } else {
        // try to get device location (optional)
        // caller may prefer to supply initialPosition; we leave it as is
      }
    });
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    _mapSub?.cancel();
    super.dispose();
  }

  // AUTO UPDATE SAAT MAP BERHENTI BERGERAK
  void _onMapMoveEnd(LatLng center) {
    if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();

    debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      selectedLatLng = center;

      await _reverseGeocode(center);

      if (mounted) setState(() {});
    });
  }

  // REVERSE GEOCODING
  Future<void> _reverseGeocode(LatLng latLng) async {
    final url =
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&accept-language=id";

    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'MyFlutterApp'},
      );

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        final display = data["display_name"] as String?;
        selectedAddress = (display != null && display.isNotEmpty)
            ? display
            : "Alamat tidak ditemukan";
      } else {
        selectedAddress = "Alamat tidak ditemukan";
      }
    } catch (_) {
      selectedAddress = "Alamat tidak ditemukan";
    }
    if (mounted) setState(() {});
  }

  // DARI HALAMAN SEARCH → MAP AUTO MOVE
  void _moveToSearchedLocation(LatLng latLng, String address) {
    try {
      _mapController.move(latLng, 17);
    } catch (_) {}
    selectedLatLng = latLng;
    selectedAddress = address;
    if (mounted) setState(() {});
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
              // We already listen to mapEventStream (safer subscription),
              // so no need to set onPositionChanged here.
            ),
            children: [
              TileLayer(
                // Use subdomains and provide a custom User-Agent header so OSM tiles are not blocked.
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                tileProvider: NetworkTileProvider(
                  headers: {
                    // identify the app per OSM tile usage policy; include a contact if possible
                    'User-Agent':
                        'ngibrit_in/1.0 (contact: dev@yourdomain.com)',
                  },
                ),
              ),
            ],
          ),

          // PIN TENGAH (use built-in Icon to avoid missing asset crashes)
          Center(
            child: IgnorePointer(
              child: SizedBox(
                width: 55,
                height: 55,
                child: Icon(
                  Icons.location_on_rounded,
                  size: 48,
                  color: Colors.red,
                ),
              ),
            ),
          ),

          // SEARCH BAR
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      // buka search page, hasil akan dipanggil kembali melalui onSelected
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SearchLocationPage(
                            onSelected: _moveToSearchedLocation,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        selectedAddress.isEmpty
                            ? "Cari lokasi…"
                            : selectedAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BUTTON
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: ButtonPrimary(
              text: "Gunakan Lokasi Ini",
              onTap: () {
                if (selectedLatLng != null) {
                  // PENTING: hanya panggil callback — jangan pop di sini.
                  // Pemilik route (main.dart) akan melakukan Navigator.pop(ctx, ...)
                  widget.onLocationPicked(selectedLatLng!, selectedAddress);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
