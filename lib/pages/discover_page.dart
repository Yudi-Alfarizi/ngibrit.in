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

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final fragments = [
    const BrowseFragment(),
    const OrdersFragment(),
    const SettingsFragment(),
  ];
  final fragmentIndex = 0.obs;

  late final Account account;

  @override
  void initState() {
    DSession.getUser().then((value) {
      account = Account.fromJson(Map.from(value!));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                onTap: () {
                  fragmentIndex.value = 0;
                },
              ),
              buildItemNav(
                label: 'Order',
                icon: 'assets/ic_orders.png',
                iconOn: 'assets/ic_orders_on.png',
                isActive: fragmentIndex.value == 1,
                onTap: () {
                  fragmentIndex.value = 1;
                },
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
                onTap: () {
                  fragmentIndex.value = 2;
                },
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
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xffFFBC1C),
      ),
      child: UnconstrainedBox(
        child: Image.asset('assets/ic_status.png', height: 24, width: 24),
      ),
    );
  }
}
