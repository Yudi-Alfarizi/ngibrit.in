import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:ngibrit_in/controllers/browse_featured_controller.dart';
import 'package:ngibrit_in/models/bike.dart';
import 'package:extended_image/extended_image.dart';
import 'package:ngibrit_in/widgets/failed_ui.dart';

class BrowseFragment extends StatefulWidget {
  const BrowseFragment({super.key});

  @override
  State<BrowseFragment> createState() => _BrowseFragmentState();
}

class _BrowseFragmentState extends State<BrowseFragment> {
  final browseFeaturedController = Get.put(BrowseFeaturedController());

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      browseFeaturedController.fetchFeatured();
    });
    super.initState();
  }

  @override
  void dispose() {
    Get.delete<BrowseFeaturedController>(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        Gap(30 + MediaQuery.of(context).padding.top),
        buildheader(),
        Gap(30),
        buildCategories(),
        Gap(30),
        buildFeatured(),
      ],
    );
  }

  Widget buildFeatured() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Unggulan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xff070623),
            ),
          ),
        ),
        const Gap(10),
        Obx(() {
          String status = browseFeaturedController.status;
          if (status == '') return const SizedBox();
          if (status == 'loading') {
            return const Center(
              child: CircularProgressIndicator()
            );
          }
          if (status != 'success') {
            return Center(
              child: FailedUi(message: status));
          }
          List<Bike> list = browseFeaturedController.list;

          return SizedBox(
            height: 295,
            child: ListView.builder(
              itemCount: list.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                Bike bike = list[index];
                final margin = EdgeInsets.only(
                  left: index==0?24:12,
                  right: index==list.length-1?24:12,
                );
                bool isTrending = index == 0;
                return buildItemFeatured(bike, margin, isTrending);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget buildItemFeatured(
    Bike bike,
    EdgeInsetsGeometry margin,
    bool isTrending,
  ) {
    return Container(
      width: 252,
      margin: margin,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ExtendedImage.network(
                bike.image,
                width: 220,
                height: 170,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget buildCategories() {
    final categories = [
      ['City', 'assets/ic_city.png'],
      ['Downhill', 'assets/ic_downhill.png'],
      ['Beach', 'assets/ic_beach.png'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Kategori',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xff070623),
            ),
          ),
        ),
        const Gap(10),
        SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Row(
              children: categories
                  .map(
                    (e) => Container(
                      height: 52,
                      margin: EdgeInsets.only(right: 24),
                      padding: EdgeInsets.fromLTRB(16, 14, 30, 14),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff070623),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildheader() {
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
            decoration: BoxDecoration(
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
