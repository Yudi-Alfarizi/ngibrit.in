import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_session/d_session.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:ngibrit_in/common/info.dart';
import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/models/order_model.dart';
import 'package:ngibrit_in/pages/fragments/browse_fragment.dart';
import 'package:ngibrit_in/pages/fragments/orders_fragment.dart';
import 'package:ngibrit_in/pages/fragments/settings_fragment.dart';
import 'package:ngibrit_in/services/notification_service.dart';
import 'package:ngibrit_in/source/chat_source.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ngibrit_in/models/chat.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  List<Widget> fragments = [];
  final fragmentIndex = 0.obs;
  late final Account account;
  bool isLoading = true;

  StreamSubscription? _chatSubscription;
  bool _isInitialChatLoad = true;
  final DateTime _appStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map && args.containsKey('initialIndex')) {
        fragmentIndex.value = args['initialIndex'];
      }
    });

    DSession.getUser().then((value) {
      if (value != null) {
        account = Account.fromJson(Map.from(value));
        _setupCSMessageListener(account.uid);

        setState(() {
          fragments = [
            const BrowseFragment(),
            const OrdersFragment(),
            const SettingsFragment(),
          ];
          isLoading = false;
        });
      }
    });
  }

  void _setupCSMessageListener(String uid) {
    _chatSubscription = FirebaseFirestore.instance
        .collection('CS')
        .doc(uid)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) {
            if (_isInitialChatLoad) {
              _isInitialChatLoad = false;
              return;
            }

            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data() as Map<String, dynamic>;
                final senderId = data['senderId'] ?? '';

                if (senderId != uid && senderId == 'cs') {
                  final timestamp = data['timestamp'] as Timestamp?;
                  if (timestamp != null &&
                      timestamp.toDate().isAfter(_appStartTime)) {
                    if (Get.currentRoute != '/chatting') {
                      NotificationService.showNotification(
                        id: DateTime.now().millisecondsSinceEpoch.remainder(
                          100000,
                        ),
                        title: "CS Ngibrit.in",
                        body: data['message'] ?? "Anda menerima balasan baru.",
                      );
                    }
                  }
                }
              }
            }
          },
          onError: (e) {
            debugPrint("Listener Chat Error: $e");
          },
        );
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleSOSClicked() async {
    Info.showLoading(context, message: "Memeriksa pesanan...");
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('userId', isEqualTo: account.uid)
          .where('status', isEqualTo: 'Berlangsung')
          .get();

      Info.hideLoading();

      if (querySnapshot.docs.isEmpty) {
        Info.error("Tidak ada pesanan yang sedang berlangsung.");
        return;
      }

      List<OrderModel> activeOrders = querySnapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data(), doc.id))
          .toList();

      _showSelectBikeModal(activeOrders);
    } catch (e) {
      Info.hideLoading();
      Info.error("Terjadi kesalahan: $e");
    }
  }

  void _showSelectBikeModal(List<OrderModel> orders) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Gap(24),
              const Text(
                'Pilih Kendaraan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff070623),
                ),
              ),
              const Gap(8),
              const Text(
                'Pilih pesanan motor mana yang sedang mengalami kendala.',
                style: TextStyle(fontSize: 14, color: Color(0xff838384)),
              ),
              const Gap(24),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                separatorBuilder: (context, index) => const Gap(12),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final bikeName = order.bikeSnapshot['name'] ?? 'Motor';
                  final safeOrderId = order.id.length >= 5
                      ? order.id.substring(0, 5).toUpperCase()
                      : order.id.toUpperCase();

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ExtendedImage.network(
                        order.bikeSnapshot['image'] ?? '',
                        fit: BoxFit.contain,
                      ),
                    ),
                    title: Text(
                      bikeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      "ID: $safeOrderId | ${order.startDate} - ${order.endDate}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      _showEmergencyIssueModal(order);
                    },
                  );
                },
              ),
              const Gap(30),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xffF8F8FA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: Color(0xff838384),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Gap(10),
            ],
          ),
        );
      },
    );
  }

  void _showEmergencyIssueModal(OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Gap(24),
              const Text(
                'Bantuan Darurat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff070623),
                ),
              ),
              const Gap(8),
              Text(
                'Kendala pada: ${order.bikeSnapshot['name'] ?? 'Motor'}\nPilih jenis kendala, lokasimu akan otomatis terkirim ke CS.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xff838384),
                  height: 1.5,
                ),
              ),
              const Gap(24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildEmergencyItem(Icons.tire_repair, 'Ban Bocor', order),
                  _buildEmergencyItem(Icons.build_circle, 'Mesin Mogok', order),
                  _buildEmergencyItem(
                    Icons.local_hospital,
                    'Kecelakaan',
                    order,
                  ),
                ],
              ),
              const Gap(30),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xffF8F8FA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: Color(0xff838384),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Gap(10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmergencyItem(
    IconData iconData,
    String label,
    OrderModel order,
  ) {
    return GestureDetector(
      onTap: () => _sendEmergencySignal(label, order),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xffFFF1F3),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: const Color(0xffFF2055), size: 24),
            ),
            const Gap(12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xff070623),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmergencySignal(String issue, OrderModel order) async {
    Navigator.pop(context);
    Info.showLoading(context, message: "Mendapatkan lokasi...");

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Info.hideLoading();
        Info.error("Mohon aktifkan GPS/Lokasi Anda");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Info.hideLoading();
          Info.error("Izin lokasi ditolak");
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // [PERBAIKAN] Menggunakan URL yang dikenali oleh Aplikasi CS (/2 di akhir)
      String mapsLink =
          "maps.google.com${position.latitude},${position.longitude}";

      String bikeName = order.bikeSnapshot['name'] ?? 'Motor';
      String safeOrderId = order.id.length >= 5
          ? order.id.substring(0, 5).toUpperCase()
          : order.id.toUpperCase();

      String messageText =
          "🚨 *DARURAT: $issue* 🚨\n\nMotor: $bikeName (ID: $safeOrderId)\nSaya butuh bantuan segera di lokasi ini:\n$mapsLink";

      await ChatSource.openChatRoom(account.uid, account.name);

      Map<String, dynamic> bikeDetailMap = {
        'isOrderSnapshot': true,
        'bikeName': bikeName,
        'bikeImage': order.bikeSnapshot['image'],
        'status': 'Darurat ($issue)',
        'orderId': order.id,
        'totalPrice': order.totalPrice,
        'startDate': order.startDate,
        'endDate': order.endDate,
      };

      Chat chat = Chat(
        roomId: account.uid,
        message: messageText,
        receiverId: 'cs',
        senderId: account.uid,
        bikeDetail: bikeDetailMap,
      );

      await ChatSource.send(chat, account.uid);

      Info.hideLoading();
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/chatting',
          arguments: {'uid': account.uid, 'userName': account.name},
        );
      }
    } catch (e) {
      Info.hideLoading();
      Info.error("Gagal mengirim sinyal: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      extendBody: true,
      body: Obx(() => fragments[fragmentIndex.value]),
      bottomNavigationBar: Obx(() {
        return Container(
          height: 78,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xff070623),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              buildItemNav(
                label: 'Cari',
                icon: 'assets/ic_browse.png',
                iconOn: 'assets/ic_browse_on.png',
                isActive: fragmentIndex.value == 0,
                onTap: () => fragmentIndex.value = 0,
              ),
              buildItemNav(
                label: 'Order',
                icon: 'assets/ic_orders.png',
                iconOn: 'assets/ic_orders_on.png',
                isActive: fragmentIndex.value == 1,
                onTap: () => fragmentIndex.value = 1,
              ),
              buildItemCircle(),
              buildItemNav(
                label: 'Pesan',
                icon: 'assets/ic_chats.png',
                iconOn: 'assets/ic_chats_on.png',
                hasDot: true,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/chatting',
                    arguments: {'uid': account.uid, 'userName': account.name},
                  );
                },
              ),
              buildItemNav(
                label: 'Opsi',
                icon: 'assets/ic_settings.png',
                iconOn: 'assets/ic_settings_on.png',
                isActive: fragmentIndex.value == 2,
                onTap: () => fragmentIndex.value = 2,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget buildItemNav({
    required String label,
    required String icon,
    required String iconOn,
    bool isActive = false,
    required VoidCallback onTap,
    bool hasDot = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          height: 46,
          child: Column(
            children: [
              Image.asset(isActive ? iconOn : icon, height: 24, width: 24),
              const Gap(4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(isActive ? 0xffFFBC1C : 0xffFFFFFF),
                    ),
                  ),
                  if (hasDot)
                    Container(
                      margin: const EdgeInsets.only(left: 2),
                      height: 6,
                      width: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xffFF2056),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildItemCircle() {
    return GestureDetector(
      onTap: () => _handleSOSClicked(),
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xffFF2055),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffFFBC1C).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const UnconstrainedBox(
          child: Icon(
            Icons.support_agent_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
