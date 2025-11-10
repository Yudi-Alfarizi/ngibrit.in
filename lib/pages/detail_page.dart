import 'package:d_session/d_session.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ngibrit_in/common/info.dart';
import 'package:ngibrit_in/controllers/detail_controller.dart';
import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/models/bike.dart';
import 'package:ngibrit_in/models/chat.dart';
import 'package:ngibrit_in/source/chat_source.dart';
import 'package:ngibrit_in/widgets/button_primary.dart';
import 'package:ngibrit_in/widgets/failed_ui.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.bikeId});
  final String bikeId;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final detailController = Get.put(DetailController());

  late final Account account;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      detailController.fetchBike(widget.bikeId);
    });
    DSession.getUser().then((value) {
      account = Account.fromJson(Map.from(value!));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          Gap(20 + MediaQuery.of(context).padding.top),
          buildHeader(context),
          const Gap(30),
          Obx(() {
            String status = detailController.status;
            if (status == '') return const SizedBox();
            if (status == 'loading') {
              return const Center(child: CircularProgressIndicator());
            }
            if (status != 'success') {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: FailedUi(message: status),
              );
            }
            Bike bike = detailController.bike;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      bike.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff070623),
                      ),
                    ),
                  ),
                  const Gap(10),
                  buildStats(bike),
                  const Gap(30),
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Image.asset('assets/ellipse.png', fit: BoxFit.fitWidth),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ExtendedImage.network(
                          bike.image,
                          height: 200,
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                    ],
                  ),
                  const Gap(30),
                  const Text(
                    'Tentang',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff070623),
                    ),
                  ),
                  const Gap(10),
                  Text(
                    bike.about,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff070623),
                    ),
                  ),
                  const Gap(40),
                  buildPrice(bike),
                  const Gap(16),
                  buildSendMessage(bike),
                  const Gap(30),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildSendMessage(Bike bike) {
    return Material(
      borderRadius: BorderRadius.circular(50),
      color: Color(0xffffffff),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () async {
          String uid = account.uid;
          Chat chat = Chat(
            roomId: uid,
            message: 'Ready?',
            receiverId: 'cs',
            senderId: uid,
            bikeDetail: {
              'image': bike.image,
              'name': bike.name,
              'category': bike.category,
              'id': bike.id,
            },
          );
          Info.showLoading(context, message: 'Loading..');
          try {
            await ChatSource.openChatRoom(uid, account.name);
            await ChatSource.send(chat, uid);
            Info.hideLoading();
            Navigator.pushNamed(
              context,
              '/chatting',
              arguments: {'uid': uid, 'userName': account.name},
            );
          } catch (e) {
            Info.hideLoading();
            Info.error("Gagal membuka pesan");
          }
        },
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/ic_message.png', width: 24, height: 24),
              const Gap(10),
              Text(
                'Kirim Pesan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff070623),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPrice(Bike bike) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Color(0xff070623),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  NumberFormat.currency(
                    decimalDigits: 0,
                    locale: 'id_ID',
                    symbol: 'Rp ',
                  ).format(bike.price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xffFFFFFF),
                  ),
                ),
                const Text(
                  '/hari',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xffFFFFFF),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 140,
            child: ButtonPrimary(
              text: 'Pesan Sekarang',
              fontSize : 14,
              onTap: () {
                Navigator.pushNamed(context, '/booking', arguments: bike);
              },
            ),
          ),
        ],
      ),
    );
  }

  Row buildStats(Bike bike) {
    final stats = [
      ['assets/ic_beach.png', bike.level],
      [],
      ['assets/ic_downhill.png', bike.category],
      [],
      ['assets/ic_star.png', '${bike.rating}/5'],
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: stats.map((e) {
        if (e.isEmpty) return Gap(20);
        return Row(
          children: [
            Image.asset(e[0], width: 24, height: 24),
            const Gap(4),
            Text(
              e[1],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xff070623),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 46,
              width: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/ic_arrow_back.png',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Detail',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xff070623),
              ),
            ),
          ),
          Container(
            height: 46,
            width: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: Image.asset('assets/ic_favorite.png', width: 24, height: 24),
          ),
        ],
      ),
    );
  }
}
