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
import 'package:latlong2/latlong.dart' as latLng;
import 'package:ngibrit_in/controllers/booking_status_controller.dart';
import 'package:ngibrit_in/controllers/browse_featured_controller.dart';
import 'package:ngibrit_in/controllers/browse_newest_controller.dart';
import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/models/bike.dart';
import 'package:ngibrit_in/models/order_model.dart';
import 'package:ngibrit_in/source/order_source.dart';
import 'package:extended_image/extended_image.dart';
import 'package:ngibrit_in/widgets/failed_ui.dart';

// [IMPORTS BARU]
import 'package:ngibrit_in/models/hub.dart';
import 'package:ngibrit_in/source/hub_source.dart';

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

  String _displayAddress = "Mencari lokasi...";
  latLng.LatLng? _activeLocation;
  Map<String, dynamic>? _nearestHub;
  bool _isLocationLoading = true;

  String _selectedHubId = '';
  String _selectedCategory = 'Semua';

  // [PERBAIKAN DINAMIS]: Hub tidak di-hardcode lagi, hanya menyimpan index 0 sebagai filter "Semua"
  List<Hub> _dynamicHubs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHubsAndInit(); // Panggil fetch hub pertama kali
      _fetchUserDataAndActiveOrder();
      _checkFlashMessage();
    });
  }

  // [FUNGSI BARU]: Mengambil data dari Firebase lalu mengeksekusi GPS & Motor
  Future<void> _fetchHubsAndInit() async {
    final fetchedHubs = await HubSource.fetchHubs();
    if (mounted) {
      setState(() {
        _dynamicHubs = fetchedHubs;
      });
    }
    // Setelah data Hub berhasi dimuat, baru kita cari jarak GPS ke Hub terdekat
    await _initGPSLocation();
    _loadDataMotor();
  }

  void _loadDataMotor() {
    browseFeaturedController.fetchFeatured(
      hubId: _selectedHubId,
      category: _selectedCategory,
    );
    browseNewestController.fetchNewest(
      hubId: _selectedHubId,
      category: _selectedCategory,
    );
  }

  String _getHubNameDisplay(String hubId) {
    if (hubId.isEmpty) return "Pusat";
    // Cari nama hub dari data dinamis
    final hub = _dynamicHubs.firstWhere(
      (h) => h.id == hubId,
      orElse: () =>
          Hub(id: '', name: 'Pusat', latitude: 0, longitude: 0, address: ''),
    );
    return hub.name;
  }

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
      await _updateAddressText(gpsPos);
      if (mounted) {
        setState(() => _activeLocation = gpsPos);
        _calculateNearestHub();
      }
    } catch (e) {
      if (mounted) setState(() => _displayAddress = "Lokasi tidak terdeteksi");
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  void _openMapPicker() async {
    final result = await Navigator.pushNamed(
      context,
      '/map-picker',
      arguments: _activeLocation,
    );
    if (result != null && result is Map) {
      setState(() {
        _activeLocation = latLng.LatLng(
          result['lat'] ?? 0.0,
          result['lng'] ?? 0.0,
        );
        _displayAddress = result['address'] ?? "";
        _isLocationLoading = true;
      });
      await _calculateNearestHub();
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  Future<void> _updateAddressText(latLng.LatLng pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      Placemark place = placemarks[0];
      String formatted =
          "${place.thoroughfare ?? place.name ?? ''}, ${place.subLocality ?? place.locality ?? ''}";
      if (formatted.startsWith(", ")) formatted = formatted.substring(2);
      if (mounted) setState(() => _displayAddress = formatted);
    } catch (e) {
      if (mounted) setState(() => _displayAddress = "Lokasi terpilih");
    }
  }

  // [PERBAIKAN LOGIKA]: Menghitung dari _dynamicHubs
  Future<void> _calculateNearestHub() async {
    if (_activeLocation == null || _dynamicHubs.isEmpty) return;
    double minDistance = double.infinity;
    Map<String, dynamic>? closest;
    final distanceCalc = const latLng.Distance();

    for (var hub in _dynamicHubs) {
      double dist = distanceCalc.as(
        latLng.LengthUnit.Kilometer,
        _activeLocation!,
        latLng.LatLng(hub.latitude, hub.longitude),
      );
      if (dist < minDistance) {
        minDistance = dist;
        closest = {'id': hub.id, 'name': hub.name, 'distance_km': dist};
      }
    }
    if (mounted) setState(() => _nearestHub = closest);
  }

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
        await _fetchHubsAndInit(); // Mengambil ulang Hub jika ditarik kebawah
        _fetchActiveOrder();
      },
      child: Scaffold(
        backgroundColor: const Color(0xffFBFBFB),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverGap(20 + MediaQuery.of(context).padding.top),
            SliverToBoxAdapter(child: buildLocationHeader()),

            if (_isStatusVisible && activeOrder != null)
              SliverToBoxAdapter(child: buildBookingStatus())
            else
              const SliverGap(0),

            const SliverGap(24),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Text(
                  'Cari di Garasi (Hub)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff070623),
                  ),
                ),
              ),
            ),
            const SliverGap(12),
            SliverToBoxAdapter(child: buildCityFilter()),
            const SliverGap(24),

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
              if (list.isEmpty)
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        "Belum ada armada untuk filter ini.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );

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

  Widget buildCityFilter() {
    // Gabungkan filter "Semua Kota" dengan list dinamis dari firebase
    final List<Map<String, dynamic>> combinedFilters = [
      {'id': '', 'name': 'Semua Kota'},
      ..._dynamicHubs.map((e) => {'id': e.id, 'name': e.name}),
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: combinedFilters.length,
        padding: const EdgeInsets.only(left: 24),
        itemBuilder: (context, index) {
          final filter = combinedFilters[index];
          final isActive = _selectedHubId == filter['id'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedHubId = filter['id'] as String);
              _loadDataMotor();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: isActive ? const Color(0xff4A1DFF) : Colors.white,
                border: Border.all(
                  color: isActive
                      ? const Color(0xff4A1DFF)
                      : const Color(0xffF3F4F6),
                ),
              ),
              child: Text(
                filter['name'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xff070623),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildCategories() {
    final categories = [
      ['Semua', Icons.grid_view],
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
          final String catName = e[0] as String;
          final bool isActive = _selectedCategory == catName;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = catName);
              _loadDataMotor();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: isActive ? const Color(0xff4A1DFF) : Colors.white,
                border: Border.all(
                  color: isActive
                      ? const Color(0xff4A1DFF)
                      : const Color(0xffF3F4F6),
                ),
              ),
              child: Row(
                children: [
                  e[1] is IconData
                      ? Icon(
                          e[1] as IconData,
                          size: 16,
                          color: isActive ? Colors.white : Colors.grey,
                        )
                      : Image.asset(
                          e[1] as String,
                          width: 16,
                          height: 16,
                          color: isActive ? Colors.white : null,
                        ),
                  const Gap(8),
                  Text(
                    catName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : const Color(0xff070623),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildLocationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _openMapPicker,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Lokasi Saya",
                    style: TextStyle(fontSize: 10, color: Color(0xff838384)),
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xffFF2055),
                        size: 16,
                      ),
                      const Gap(6),
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Notifications')
                .where('userId', isEqualTo: account?.uid ?? '')
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              bool hasUnread =
                  snapshot.hasData && snapshot.data!.docs.isNotEmpty;

              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/notifications');
                },
                child: Container(
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
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset(
                        'assets/ic_notification.png',
                        fit: BoxFit.contain,
                      ),
                      if (hasUnread)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xffFF2055),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildNearestBikesList() {
    if (_nearestHub == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Bikes')
          .where('hub_id', isEqualTo: _nearestHub!['id'])
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
              "Tidak ada motor tersedia di hub terdekat ini.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          );
        }

        var bikes = snapshot.data!.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return Bike.fromJson(data);
        }).toList();

        if (_selectedCategory != 'Semua') {
          bikes = bikes
              .where(
                (b) =>
                    b.category.toLowerCase() == _selectedCategory.toLowerCase(),
              )
              .toList();
        }

        if (bikes.isEmpty) return const SizedBox();

        return SizedBox(
          height: 270,
          child: ListView.builder(
            itemCount: bikes.length,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final margin = EdgeInsets.only(
                left: index == 0 ? 24 : 12,
                right: index == bikes.length - 1 ? 24 : 12,
              );
              return buildVerticalCard(bikes[index], margin, false);
            },
          ),
        );
      },
    );
  }

  Widget buildFeatured() {
    return Obx(() {
      String status = browseFeaturedController.status;
      if (status == 'loading')
        return const Center(child: CircularProgressIndicator());
      if (status != 'success') return Center(child: FailedUi(message: status));

      List<Bike> list = browseFeaturedController.list;
      if (list.isEmpty)
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              "Belum ada unggulan di area ini.",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );

      return SizedBox(
        height: 270,
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

  // --- KARTU VERTIKAL (UNGGULAN / TERDEKAT) ---
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
            const Gap(4),
            Text(
              bike.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Color(0xff838384)),
            ),
            const Gap(4),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 10,
                  color: Color(0xffFF2055),
                ),
                const Gap(2),
                Expanded(
                  child: Text(
                    _getHubNameDisplay(bike.hubId),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xff838384),
                    ),
                  ),
                ),
              ],
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
                  symbol: 'Rp ',
                ).format(bike.price),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff4A1DFF),
                ),
                children: const [
                  TextSpan(
                    text: '/hari',
                    style: TextStyle(
                      fontSize: 12,
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

  // --- KARTU HORIZONTAL (SEMUA MOTOR) ---
  Widget buildHorizontalCard(Bike bike, EdgeInsetsGeometry margin) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/detail', arguments: bike.id),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
                  const Gap(4),
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
                  const Gap(4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Color(0xffFF2055),
                      ),
                      const Gap(2),
                      Expanded(
                        child: Text(
                          _getHubNameDisplay(bike.hubId),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff838384),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  RichText(
                    text: TextSpan(
                      text: NumberFormat.currency(
                        decimalDigits: 0,
                        locale: 'id_ID',
                        symbol: 'Rp ',
                      ).format(bike.price),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff4A1DFF),
                      ),
                      children: const [
                        TextSpan(
                          text: '/hari',
                          style: TextStyle(
                            fontSize: 12,
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
          ],
        ),
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
