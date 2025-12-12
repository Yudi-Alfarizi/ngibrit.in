import 'dart:async';
import 'package:d_session/d_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      browseFeaturedController.fetchFeatured();
      browseNewestController.fetchNewest();
      _fetchUserDataAndActiveOrder();
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

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _fetchUserDataAndActiveOrder() async {
    final userSession = await DSession.getUser();
    if (userSession != null) {
      setState(() {
        account = Account.fromJson(Map.from(userSession));
      });
      _fetchActiveOrder();
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        browseFeaturedController.fetchFeatured();
        browseNewestController.fetchNewest();
        _fetchActiveOrder();
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverGap(30 + MediaQuery.of(context).padding.top),

          SliverToBoxAdapter(child: buildHeader()),

          
          if (_isStatusVisible && activeOrder != null)
            SliverToBoxAdapter(child: buildBookingStatus())
          else
            const SliverGap(0),

          const SliverGap(30),
          SliverToBoxAdapter(child: buildCategories()),
          const SliverGap(30),

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
          const SliverGap(10),
          SliverToBoxAdapter(child: buildFeatured()),
          const SliverGap(30),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Text(
                'Motor Terbaru',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff070623),
                ),
              ),
            ),
          ),
          const SliverGap(10),

          Obx(() {
            String status = browseNewestController.status;
            if (status == 'loading') {
              return const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (status != 'success') {
              return SliverToBoxAdapter(
                child: Center(child: FailedUi(message: status)),
              );
            }

            List<Bike> list = browseNewestController.list;
            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                Bike bike = list[index];
                final margin = EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: index == 0 ? 0 : 12,
                  bottom: index == list.length - 1 ? 100 : 0,
                );
                return buildItemNewest(bike, margin);
              }, childCount: list.length),
            );
          }),
        ],
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
            // ignore: deprecated_member_use
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
              color:
                  Colors.white,
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

  Widget buildItemNewest(Bike bike, EdgeInsetsGeometry margin) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/detail', arguments: bike.id);
      },
      child: Container(
        height: 98,
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ExtendedImage.network(
              bike.image,
              width: 90,
              height: 70,
              fit: BoxFit.contain,
              cache: true,
              enableMemoryCache: true,
            ),
            const Gap(10),
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
                      fontWeight: FontWeight.w600,
                      color: Color(0xff070623),
                    ),
                  ),
                  const Gap(4),
                  Text(
                    bike.category,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff838384),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(
                    decimalDigits: 0,
                    locale: 'id_ID',
                    symbol: 'Rp ',
                  ).format(bike.price),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff6747E9),
                  ),
                ),
                const Text(
                  '/hari',
                  style: TextStyle(fontSize: 12, color: Color(0xff838384)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFeatured() {
    return Obx(() {
      String status = browseFeaturedController.status;
      if (status == 'loading')
        return const Center(child: CircularProgressIndicator());
      if (status != 'success') return Center(child: FailedUi(message: status));

      List<Bike> list = browseFeaturedController.list;
      return SizedBox(
        height: 295,
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
            bool isTrending = index == 0;
            return buildItemFeatured(bike, margin, isTrending);
          },
        ),
      );
    });
  }

  Widget buildItemFeatured(
    Bike bike,
    EdgeInsetsGeometry margin,
    bool isTrending,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/detail', arguments: bike.id);
      },
      child: Container(
        width: 252,
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ExtendedImage.network(
                  bike.image,
                  width: 220,
                  height: 170,
                  fit: BoxFit.contain,
                  cache: true,
                ),
                if (isTrending)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xffFF2055),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                            color: const Color(0xffFF2055).withOpacity(0.5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 14,
                      ),
                      child: const Text(
                        'Trending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bike.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff070623),
                        ),
                      ),
                      const Gap(4),
                      Text(
                        bike.category,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff838384),
                        ),
                      ),
                    ],
                  ),
                ),
                RatingBar.builder(
                  initialRating: bike.rating.toDouble(),
                  itemSize: 16,
                  unratedColor: Colors.grey[300],
                  allowHalfRating: true,
                  itemBuilder: (context, index) =>
                      const Icon(Icons.star, color: Color(0xffFFBC1C)),
                  ignoreGestures: true,
                  onRatingUpdate: (value) {},
                ),
              ],
            ),
            const Gap(16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(
                    decimalDigits: 0,
                    locale: 'id_ID',
                    symbol: 'Rp ',
                  ).format(bike.price),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff6747E9),
                  ),
                ),
                const Text(
                  '/hari',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff838384),
                  ),
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
      ['Moge', 'assets/ic_moge.png'],
      ['Ekonomis', 'assets/ic_insurance.png'],
      ['Lifestyle', 'assets/ic_beach.png'],
      ['Premium', 'assets/ic_diamond.png'],
      ['Sport', 'assets/ic_sport.png'],
    ];

    return SizedBox(
      height: 52,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.only(left: 24),
        itemBuilder: (context, index) {
          final e = categories[index];
          return Container(
            margin: const EdgeInsets.only(right: 24),
            padding: const EdgeInsets.fromLTRB(16, 14, 30, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Image.asset(e[1], width: 24, height: 24),
                const Gap(10),
                Text(
                  e[0],
                  style: const TextStyle(
                    fontSize: 16,
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

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/logo_text.png',
            height: 30,
            fit: BoxFit.fitHeight,
          ),
          Container(
            height: 46,
            width: 46,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/ic_notification.png',
              height: 24,
              width: 24,
            ),
          ),
        ],
      ),
    );
  }
}
