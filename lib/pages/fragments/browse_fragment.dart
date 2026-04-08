import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_session/d_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:gap/gap.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latLng; // Alias agar tidak bentrok
import 'package:ngibrit_in/controllers/booking_status_controller.dart';
import 'package:ngibrit_in/controllers/browse_featured_controller.dart';
import 'package:ngibrit_in/controllers/browse_newest_controller.dart';
import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/models/bike.dart';
import 'package:ngibrit_in/models/order_model.dart';
import 'package:ngibrit_in/source/order_source.dart';
import 'package:extended_image/extended_image.dart';
import 'package:ngibrit_in/widgets/failed_ui.dart';

class BrowseFragment extends StatefulWidget {
  const BrowseFragment({super.key});

  @override
  State<BrowseFragment> createState() => _BrowseFragmentState();
}

class _BrowseFragmentState extends State<BrowseFragment> {
  final browseFeaturedController = Get.put(BrowseFeaturedController());
  final browseNewestController = Get.put(BrowseNewestController());
  final bookingStatusController = Get.put(BookingStatusController());

  OrderModel? activeOrder;
  Account? account;
  bool _isStatusVisible = false;
  Timer? _statusTimer;

  // --- STATE LOKASI ---
  String _displayAddress = "Mencari lokasi...";
  latLng.LatLng? _activeLocation; // Lokasi aktif untuk filter
  Map<String, dynamic>? _nearestHub;
  bool _isLocationLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      browseFeaturedController.fetchFeatured();
      browseNewestController.fetchNewest();
      _fetchUserDataAndActiveOrder();
      _checkFlashMessage();
      _initGPSLocation(); // Start awal pakai GPS
    });
  }

  // --- 1. LOGIC LOKASI (GPS START) ---
  Future<void> _initGPSLocation() async {
    if (mounted) setState(() => _isLocationLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'GPS mati';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Izin ditolak';
      }

      Position position = await Geolocator.getCurrentPosition();
      latLng.LatLng gpsPos = latLng.LatLng(
        position.latitude,
        position.longitude,
      );

      // Ambil nama jalan (Reverse Geo) untuk display awal
      await _updateAddressText(gpsPos);

      if (mounted) {
        setState(() {
          _activeLocation = gpsPos;
        });
        _calculateNearestHub(); // Hitung hub dari lokasi GPS
      }
    } catch (e) {
      if (mounted) setState(() => _displayAddress = "Lokasi tidak terdeteksi");
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  // --- 2. LOGIC BUKA MAP PICKER (MANUAL) ---
  void _openMapPicker() async {
    // Navigasi ke MapPickerPage (pastikan route '/map-picker' ada di main.dart)
    // Kirim lokasi terakhir agar peta tidak reset ke default
    final result = await Navigator.pushNamed(
      context,
      '/map-picker',
      arguments: _activeLocation,
    );

    // Terima balikan data Map {'lat':..., 'lng':..., 'address':...}
    if (result != null && result is Map) {
      double rLat = result['lat'] ?? 0.0;
      double rLng = result['lng'] ?? 0.0;
      String rAddr = result['address'] ?? "";

      setState(() {
        _activeLocation = latLng.LatLng(rLat, rLng);
        _displayAddress = rAddr;
        _isLocationLoading = true; // Loading saat hitung ulang hub
      });

      // Hitung ulang hub berdasarkan lokasi pilihan user
      await _calculateNearestHub();

      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  // Helper: Reverse Geocoding Text
  Future<void> _updateAddressText(latLng.LatLng pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      Placemark place = placemarks[0];
      String street = place.thoroughfare ?? '';
      String district = place.subLocality ?? place.locality ?? '';

      if (street.isEmpty) street = place.name ?? '';

      // Format: "Jalan Anggrek Rosliana, Jakarta Barat"
      String formatted = "$street, $district";
      if (formatted.startsWith(", ")) formatted = formatted.substring(2);

      if (mounted) setState(() => _displayAddress = formatted);
    } catch (e) {
      if (mounted) setState(() => _displayAddress = "Lokasi terpilih");
    }
  }

  // Helper: Hitung Hub Terdekat
  Future<void> _calculateNearestHub() async {
    if (_activeLocation == null) return;

    try {
      final hubsSnapshot = await FirebaseFirestore.instance
          .collection('hubs')
          .get();
      if (hubsSnapshot.docs.isNotEmpty) {
        double minDistance = double.infinity;
        Map<String, dynamic>? closest;
        final distanceCalc = const latLng.Distance();

        for (var doc in hubsSnapshot.docs) {
          Map<String, dynamic> data = doc.data();
          double hubLat = (data['lat'] ?? 0).toDouble();
          double hubLng = (data['lng'] ?? 0).toDouble();

          double dist = distanceCalc.as(
            latLng.LengthUnit.Kilometer,
            _activeLocation!,
            latLng.LatLng(hubLat, hubLng),
          );

          if (dist < minDistance) {
            minDistance = dist;
            closest = data;
            closest['id'] = doc.id;
            closest['distance_km'] = dist;
          }
        }
        if (mounted) setState(() => _nearestHub = closest);
      }
    } catch (e) {
      print("Error calculating hub: $e");
    }
  }

  // --- LOGIC STANDARD ---
  void _checkFlashMessage() {
    if (bookingStatusController.flashMessageActive.value) {
      setState(() => _isStatusVisible = true);
      bookingStatusController.deactivateFlashMessage();
      _statusTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) setState(() => _isStatusVisible = false);
      });
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _fetchUserDataAndActiveOrder() async {
    final userSession = await DSession.getUser();
    if (userSession != null) {
      setState(() => account = Account.fromJson(Map.from(userSession)));
      _fetchActiveOrder();
    }
  }

  void _fetchActiveOrder() async {
    if (account == null) return;
    final order = await OrderSource.getActiveOrder(account!.uid);
    if (mounted) setState(() => activeOrder = order);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _initGPSLocation(); // Reset ke GPS saat pull refresh
        browseFeaturedController.fetchFeatured();
        browseNewestController.fetchNewest();
        _fetchActiveOrder();
      },
      child: Scaffold(
        backgroundColor: const Color(0xffFBFBFB),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverGap(20 + MediaQuery.of(context).padding.top),

            // [HEADER BARU: LOCATION PICKER]
            SliverToBoxAdapter(child: buildLocationHeader()),

            if (_isStatusVisible && activeOrder != null)
              SliverToBoxAdapter(child: buildBookingStatus())
            else
              const SliverGap(0),

            const SliverGap(24),

            // Kategori
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff070623),
                  ),
                ),
              ),
            ),
            const SliverGap(12),
            SliverToBoxAdapter(child: buildCategories()),
            const SliverGap(24),

            // Section Terdekat (Dinamis)
            if (_nearestHub != null) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Terdekat Darimu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff070623),
                        ),
                      ),
                      const Gap(4),
                      Text(
                        "Jarak lokasi anda dengan ${_nearestHub!['name']} sejauh ${_nearestHub!['distance_km'].toStringAsFixed(1)} km",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xff838384),
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SliverGap(16),
              SliverToBoxAdapter(child: buildNearestBikesList()),
              const SliverGap(24),
            ],

            // Section Unggulan
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Text(
                  'Unggulan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff070623),
                  ),
                ),
              ),
            ),
            const SliverGap(16),
            SliverToBoxAdapter(child: buildFeatured()),
            const SliverGap(24),

            // Section Semua Motor
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Text(
                  'Semua Motor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff070623),
                  ),
                ),
              ),
            ),
            const SliverGap(16),

            Obx(() {
              String status = browseNewestController.status;
              if (status == 'loading')
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              if (status != 'success')
                return SliverToBoxAdapter(
                  child: Center(child: FailedUi(message: status)),
                );

              List<Bike> list = browseNewestController.list;
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  Bike bike = list[index];
                  final margin = EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: index == 0 ? 0 : 16,
                    bottom: index == list.length - 1 ? 120 : 0,
                  );
                  return buildHorizontalCard(bike, margin);
                }, childCount: list.length),
              );
            }),
          ],
        ),
      ),
    );
  }

  // --- HEADER UI: LOCATION PICKER STYLE ---
  Widget buildLocationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _openMapPicker, // KLIK -> BUKA MAP PICKER
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Lokasi Pengambilan",
                    style: TextStyle(fontSize: 10, color: Color(0xff838384)),
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      // Icon Pin Merah
                      const Icon(
                        Icons.location_on,
                        color: Color(0xffFF2055),
                        size: 16,
                      ),
                      const Gap(6),
                      // Teks Alamat (Bold)
                      Expanded(
                        child: _isLocationLoading
                            ? const Text(
                                "Mengupdate...",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              )
                            : Text(
                                _displayAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff070623),
                                ),
                              ),
                      ),
                      const Gap(4),
                      // Chevron
                      const Icon(
                        Icons.keyboard_arrow_right,
                        color: Color(0xff070623),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Notification Icon
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xffF3F4F6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset('assets/ic_notification.png'),
          ),
        ],
      ),
    );
  }

  // --- WIDGET LIST MOTOR ---
  Widget buildNearestBikesList() {
    if (_nearestHub == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Bikes')
          .where('hub_id', isEqualTo: _nearestHub!['id'])
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Text(
              "Tidak ada motor tersedia di hub ini.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          );
        }

        final bikes = snapshot.data!.docs;
        return SizedBox(
          height: 260,
          child: ListView.builder(
            itemCount: bikes.length,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              Map<String, dynamic> data =
                  bikes[index].data() as Map<String, dynamic>;
              data['id'] = bikes[index].id;
              Bike bike = Bike.fromJson(data);

              final margin = EdgeInsets.only(
                left: index == 0 ? 24 : 12,
                right: index == bikes.length - 1 ? 24 : 12,
              );

              return buildVerticalCard(bike, margin, false);
            },
          ),
        );
      },
    );
  }

  // --- CARD & CATEGORIES WIDGETS ---
  // (Sama seperti sebelumnya untuk menjaga desain konsisten)

  Widget buildFeatured() {
    return Obx(() {
      String status = browseFeaturedController.status;
      if (status == 'loading')
        return const Center(child: CircularProgressIndicator());
      if (status != 'success') return Center(child: FailedUi(message: status));

      List<Bike> list = browseFeaturedController.list;
      return SizedBox(
        height: 260,
        child: ListView.builder(
          itemCount: list.length,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            Bike bike = list[index];
            final margin = EdgeInsets.only(
              left: index == 0 ? 24 : 12,
              right: index == list.length - 1 ? 24 : 12,
            );
            return buildVerticalCard(bike, margin, index == 0);
          },
        ),
      );
    });
  }

  Widget buildVerticalCard(
    Bike bike,
    EdgeInsetsGeometry margin,
    bool isTrending,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/detail', arguments: bike.id),
      child: Container(
        width: 180,
        margin: margin,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ExtendedImage.network(
                  bike.image,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.contain,
                  cache: true,
                ),
                if (isTrending)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffFF2055),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "TRENDING",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Gap(12),
            Text(
              bike.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xff070623),
              ),
            ),
            Text(
              bike.category,
              style: const TextStyle(fontSize: 10, color: Color(0xff838384)),
            ),
            const Gap(6),
            RatingBar.builder(
              initialRating: bike.rating.toDouble(),
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 12,
              ignoreGestures: true,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Color(0xffFFBC1C)),
              onRatingUpdate: (rating) {},
            ),
            const Spacer(),
            RichText(
              text: TextSpan(
                text: NumberFormat.currency(
                  decimalDigits: 0,
                  locale: 'id_ID',
                  symbol: 'Rp',
                ).format(bike.price),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff4A1DFF),
                ),
                children: const [
                  TextSpan(
                    text: '/day',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff838384),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHorizontalCard(Bike bike, EdgeInsetsGeometry margin) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/detail', arguments: bike.id),
      child: Container(
        height: 110,
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ExtendedImage.network(
              bike.image,
              width: 100,
              height: 80,
              fit: BoxFit.contain,
              cache: true,
            ),
            const Gap(16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bike.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff070623),
                    ),
                  ),
                  const Gap(4),
                  Text(
                    bike.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff838384),
                    ),
                  ),
                  const Gap(8),
                  Text(
                    NumberFormat.currency(
                      decimalDigits: 0,
                      locale: 'id_ID',
                      symbol: 'Rp ',
                    ).format(bike.price),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff4A1DFF),
                    ),
                  ),
                ],
              ),
            ),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "/day",
                  style: TextStyle(fontSize: 10, color: Color(0xff838384)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCategories() {
    final categories = [
      ['Ekonomis', 'assets/ic_insurance.png'],
      ['Premium', 'assets/ic_diamond.png'],
      ['Sport', 'assets/ic_sport.png'],
      ['Moge', 'assets/ic_moge.png'],
      ['Lifestyle', 'assets/ic_beach.png'],
    ];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.only(left: 24),
        itemBuilder: (context, index) {
          final e = categories[index];
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.white,
              border: Border.all(color: const Color(0xffF3F4F6)),
            ),
            child: Row(
              children: [
                Image.asset(e[1], width: 16, height: 16),
                const Gap(8),
                Text(
                  e[0],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff070623),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildBookingStatus() {
    if (activeOrder == null) return const SizedBox.shrink();
    final bike = activeOrder!.bikeSnapshot;
    return Container(
      height: 100,
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff4A1DFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 16),
            blurRadius: 20,
            color: const Color(0xff4A1DFF).withOpacity(0.25),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ExtendedImage.network(
              bike['image'] ?? '',
              width: 80,
              height: 80,
              fit: BoxFit.fitWidth,
              cache: true,
              color: Colors.white,
              colorBlendMode: BlendMode.dstOver,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pesanan Anda',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(4),
                Text(
                  bike['name'] ?? 'Motor',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xffFFBC1C),
                    height: 1.2,
                  ),
                ),
                const Gap(4),
                Text(
                  'Status: ${activeOrder!.status}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
