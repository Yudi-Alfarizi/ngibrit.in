import 'package:d_session/d_session.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:ngibrit_in/common/info.dart';
import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/pages/fragments/browse_fragment.dart';
import 'package:ngibrit_in/pages/fragments/orders_fragment.dart';
import 'package:ngibrit_in/pages/fragments/settings_fragment.dart';
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

  void _showEmergencyModal(BuildContext context) {
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
              const Text(
                'Pilih kendala yang kamu alami. Lokasimu akan dikirim otomatis ke CS.',
                style: TextStyle(fontSize: 14, color: Color(0xff838384)),
              ),
              const Gap(24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildEmergencyItem(Icons.tire_repair, 'Ban Bocor'),
                  _buildEmergencyItem(Icons.build_circle, 'Mesin Mogok'),
                  _buildEmergencyItem(Icons.local_hospital, 'Kecelakaan'),
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

  Widget _buildEmergencyItem(IconData iconData, String label) {
    return GestureDetector(
      onTap: () => _sendEmergencySignal(label),
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
              decoration: BoxDecoration(
                color: const Color(0xffFFF1F3),
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

  Future<void> _sendEmergencySignal(String issue) async {
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

      String mapsLink =
          "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

      String messageText =
          "🚨 *DARURAT: $issue* 🚨\n\n"
          "Saya butuh bantuan di lokasi ini:\n$mapsLink";

      await ChatSource.openChatRoom(account.uid, account.name);

      Chat chat = Chat(
        roomId: account.uid,
        message: messageText,
        receiverId: 'cs',
        senderId: account.uid,
        bikeDetail: null,
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
                onTap: () async {
                  Info.showLoading(context, message: 'Loading..');
                  try {
                    await ChatSource.openChatRoom(account.uid, account.name);
                    Info.hideLoading();
                    Navigator.pushNamed(
                      context,
                      '/chatting',
                      arguments: {'uid': account.uid, 'userName': account.name},
                    );
                  } catch (e) {
                    Info.hideLoading();
                    Info.error("Gagal membuka pesan");
                  }
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
      onTap: () {
        _showEmergencyModal(context);
      },
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
        child: UnconstrainedBox(
          child: const Icon(
            Icons.support_agent_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
