import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
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
              onTap: () {},
              isActive: true,
            ),
            buildItemNav(
              label: 'Order',
              icon: 'assets/ic_orders.png',
              iconOn: 'assets/ic_orders_on.png',
              onTap: () {},
            ),
            buildItemCircle(),
            buildItemNav(
              label: 'Pesan',
              icon: 'assets/ic_chats.png',
              iconOn: 'assets/ic_chats_on.png',
              onTap: () {},
              hasDot: true,
            ),
            buildItemNav(
              label: 'Opsi',
              icon: 'assets/ic_settings.png',
              iconOn: 'assets/ic_settings_on.png',
              onTap: () {},
            ),
          ],
        ),
      ),
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
              Image.asset(
                isActive ? iconOn : icon,
                height: 24,
                width: 24
              ),
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

  Widget buildItemCircle(){
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xffFFBC1C),
      ),
      child: UnconstrainedBox(
        child: Image.asset(
          'assets/ic_status.png',
          height: 24,
          width: 24,
        ),
      ),
    );
  }
}
