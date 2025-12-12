import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_session/d_session.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ngibrit_in/controllers/booking_status_controller.dart';
import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/models/order_model.dart';
import 'package:ngibrit_in/pages/order_detail_page.dart';
import 'package:ngibrit_in/source/order_source.dart';
import 'package:ngibrit_in/widgets/failed_ui.dart';

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
  final TextEditingController _searchController = TextEditingController();

  bool _isStatusVisible = false;
  Timer? _statusTimer;
  OrderModel? activeOrder;
  String _searchText = "";

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
      _fetchActiveOrder();
      setState(() => _isStatusVisible = true);

      bookingStatusController.deactivateFlashMessage();
      _statusTimer?.cancel();
      _statusTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) setState(() => _isStatusVisible = false);
      });
    }
  }

  void _fetchActiveOrder() async {
    if (account == null) return;
    final order = await OrderSource.getActiveOrder(account!.uid);
    if (mounted) setState(() => activeOrder = order);
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (account == null)
      return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        Scaffold(
          backgroundColor:Theme.of(context).scaffoldBackgroundColor,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gap(20 + MediaQuery.of(context).padding.top),

              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Pesanan',
                        style: TextStyle(
                          color: Color(0xff070623),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const Gap(20),
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchText = value.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Cari ID, motor, atau penyewa...',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xff838384),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xff838384),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Color(0xffE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Color(0xff4A1DFF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Gap(16),

              
              Container(
                height: 45,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  labelPadding: EdgeInsets.zero,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xff838384),
                  indicator: BoxDecoration(
                    color: const Color(0xff4A1DFF),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Dikirim'),
                    Tab(text: 'Berlangsung'),
                    Tab(text: 'Selesai'),
                  ],
                ),
              ),

              const Gap(16),

              
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
        ),

        // NOTIFICATION OVERLAY
        if (_isStatusVisible && activeOrder != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: buildBookingStatus(),
            ),
          ),
      ],
    );
  }

  
  Widget buildBookingStatus() {
    final bike = activeOrder!.bikeSnapshot;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff4A1DFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 10),
            blurRadius: 30,
            color: Colors.black.withOpacity(0.25),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ExtendedImage.network(
              bike['image'] ?? '',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              cache: true,
              color: Colors.white,
              colorBlendMode: BlendMode.dstOver,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Update Pesanan',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
                const Gap(2),
                Text(
                  bike['name'] ?? 'Motor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xffFFBC1C),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(2),
                Text(
                  _getDisplayStatus(activeOrder!.status),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

        final allDocs = snapshot.data!.docs;

        
        final filteredList = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final bikeName = (data['bikeSnapshot']['name'] ?? '')
              .toString()
              .toLowerCase();
          final id = doc.id.toLowerCase();
          final renterName = (data['userName'] ?? '').toString().toLowerCase();

          return bikeName.contains(_searchText) ||
              id.contains(_searchText) ||
              renterName.contains(_searchText);
        }).toList();

        if (filteredList.isEmpty) {
          return const Center(child: Text('Pesanan tidak ditemukan'));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
          itemCount: filteredList.length,
          separatorBuilder: (c, i) => const Gap(16),
          itemBuilder: (context, index) {
            final doc = filteredList[index];
            final order = OrderModel.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            return buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget buildOrderCard(OrderModel order) {
    final bike = order.bikeSnapshot;

    
    String displayStatus = _getDisplayStatus(order.status);
    Color statusColor = const Color(0xff838384);
    Color statusBg = const Color(0xffF3F4F6);

    if (displayStatus == 'Dikirim') {
      statusColor = const Color(0xffFFBC1C);
      statusBg = const Color(0xffFFF8E1);
    } else if (displayStatus == 'Berlangsung') {
      statusColor = const Color(0xff4A1DFF);
      statusBg = const Color(0xffEFEEF7);
    } else if (displayStatus == 'Selesai') {
      statusColor = const Color(0xff1AC75A);
      statusBg = const Color(0xffE8F9EE);
    }

    
    String createdDateStr = DateFormat(
      'dd MMM yyyy HH:mm',
    ).format(order.createdAt.toDate());

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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ExtendedImage.network(
                    bike['image'] ?? '',
                    width: 70,
                    height: 70,
                    fit: BoxFit.contain,
                    cache: true,
                  ),
                ),
                const Gap(12),
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
                      const Gap(4),
                      Text(
                        'ID : ${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xff838384),
                        ),
                      ),
                      const Gap(2),
                      Text(
                        'Penyewa : ${order.userName}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xff838384),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(2),
                      Text(
                        'Dipesan : $createdDateStr',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xff838384),
                        ),
                      ),
                      const Gap(2),
                      Text(
                        'Sewa : ${order.startDate} - ${order.endDate}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xff838384),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(16),
            const DottedLine(
              dashColor: Color(0xffE5E7EB),
              lineThickness: 1,
              dashLength: 6,
              dashGapLength: 4,
            ),
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/wallet.png', width: 24, height: 24),
                    const Gap(8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Harga',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xff838384),
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(order.totalPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xff070623),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayStatus(String status) {
    if (status == 'Sedang Dikirim' || status == 'Dikirim') {
      return 'Dikirim';
    }
    if (status == 'Sedang Berlangsung' || status == 'Berlangsung') {
      return 'Berlangsung';
    }
    if (status == 'Pesanan Selesai' || status == 'Selesai') {
      return 'Selesai';
    }
    return status;
  }
}
