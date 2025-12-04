import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_session/d_session.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:ngibrit_in/controllers/booking_status_controller.dart';
import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/models/order_model.dart';
import 'package:ngibrit_in/pages/order_detail_page.dart';
import 'package:ngibrit_in/source/order_source.dart';
import 'package:ngibrit_in/widgets/failed_ui.dart';
import 'package:get/get.dart';

class OrdersFragment extends StatefulWidget {
  const OrdersFragment({super.key});

  @override
  State<OrdersFragment> createState() => _OrdersFragmentState();
}

class _OrdersFragmentState extends State<OrdersFragment>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Account? account;

  final bookingStatusController = Get.put(BookingStatusController());
  bool _isStatusVisible = false;
  Timer? _statusTimer;
  OrderModel? activeOrder;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    DSession.getUser().then((value) {
      if (value != null) {
        setState(() => account = Account.fromJson(Map.from(value)));
        _fetchActiveOrder();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFlashMessage();
    });
  }

  void _checkFlashMessage() {
    if (bookingStatusController.flashMessageActive.value) {
      setState(() {
        _isStatusVisible = true;
      });
      bookingStatusController.deactivateFlashMessage();
      _statusTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _isStatusVisible = false;
          });
        }
      });
    }
  }

  void _fetchActiveOrder() async {
    if (account == null) return;
    final order = await OrderSource.getActiveOrder(account!.uid);
    if (mounted) {
      setState(() {
        activeOrder = order;
      });
    }
  }

  // [LOGIC BARU] Cek apakah tanggal pengembalian adalah HARI INI
  bool _isOrderEndingToday(String endDateStr) {
    try {
      // Format tanggal di database: "dd MMM yyyy" (contoh: 30 Nov 2025)
      final endDate = DateFormat('dd MMM yyyy').parse(endDateStr);
      final now = DateTime.now();

      // Bandingkan Tahun, Bulan, dan Hari
      return endDate.year == now.year &&
          endDate.month == now.month &&
          endDate.day == now.day;
    } catch (e) {
      return false; // Jika format error, anggap bukan hari ini
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (account == null)
      return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xffF8F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(
            color: Color(0xff070623),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xff4A1DFF),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              unselectedLabelColor: const Color(0xff838384),
              indicatorColor: const Color(0xff4A1DFF),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Dikirim'),
                Tab(text: 'Berlangsung'),
                Tab(text: 'Selesai'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isStatusVisible && activeOrder != null) buildBookingStatus(),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildOrderList('Dikirim'),
                buildOrderList('Berlangsung'),
                buildOrderList('Selesai'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBookingStatus() {
    final bike = activeOrder!.bikeSnapshot;
    return Container(
      height: 100,
      margin: const EdgeInsets.all(24),
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
              fit: BoxFit.contain,
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
                  'Pesanan Anda ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const Gap(4),
                Text(
                  bike['name'] ?? 'Motor',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xffFFBC1C),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const Gap(4),
                Text(
                  'Status: ${activeOrder!.status}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOrderList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: OrderSource.getOrders(account!.uid, status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: FailedUi(message: "Belum ada pesanan"));
        }

        return ListView.separated(
          // [UI FIX 1] Bottom Padding 120 agar tidak tertutup nav bar
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (c, i) => const Gap(20),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final order = OrderModel.fromJson(data, doc.id);

            return buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget buildOrderCard(OrderModel order) {
    final bike = order.bikeSnapshot;

    // Logic Warna Status
    Color statusColor = const Color(0xff838384);
    if (order.status == 'Selesai') statusColor = const Color(0xffFF2055);
    if (order.status == 'Berlangsung') statusColor = Color(0xff070623);
    if (order.status == 'Dikirim') statusColor = const Color(0xff838384);

    // [LOGIC BARU] Cek Hari Terakhir
    bool isEndingToday = false;
    if (order.status == 'Berlangsung') {
      isEndingToday = _isOrderEndingToday(order.endDate);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailPage(orderModel: order)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff070623).withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xffEFEFF0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ExtendedImage.network(
                          bike['image'] ?? '',
                          fit: BoxFit.contain,
                          cache: true,
                        ),
                      ),
                    ),
                    const Gap(12),
                    const Text(
                      "Total Harga",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff070623),
                      ),
                    ),
                    const Gap(2),
                    Text(
                      NumberFormat.currency(
                        locale: 'id',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(order.totalPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xff4A1DFF),
                      ),
                    ),
                  ],
                ),

                const Gap(16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bike['name'] ?? 'Motor',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xff070623),
                        ),
                      ),
                      const Gap(6),

                      Text(
                        'No. Pesanan: ${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff838384),
                        ),
                      ),
                      const Gap(4),

                      Text(
                        order.startDate,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff838384),
                        ),
                      ),
                      const Gap(4),

                      Text(
                        order.agency,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff838384),
                        ),
                      ),

                      const Gap(16),

                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _getDisplayStatus(order.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // [UI FIX 2] Notifikasi Hari Terakhir (Hanya Muncul Jika Logic True)
            if (isEndingToday)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffFFF8E1), // Background Kuning Muda
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xffFFBC1C).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_filled,
                      color: Color(0xffF9A825),
                      size: 18,
                    ),
                    const Gap(8),
                    const Expanded(
                      child: Text(
                        "Hari Terakhir! Segera siapkan pengembalian.",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffF9A825), // Text Kuning Tua
                        ),
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

  String _getDisplayStatus(String status) {
    if (status == 'Dikirim') return 'Sedang Dikirim';
    if (status == 'Berlangsung') return 'Sedang Berlangsung';
    return 'Pesanan Selesai';
  }
}
