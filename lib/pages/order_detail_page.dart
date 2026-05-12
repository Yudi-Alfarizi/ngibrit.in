import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_session/d_session.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:ngibrit_in/common/info.dart';
import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/models/chat.dart';
import 'package:ngibrit_in/models/order_model.dart';
import 'package:ngibrit_in/source/chat_source.dart';
import 'package:ngibrit_in/source/order_source.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderModel});
  final OrderModel orderModel;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late OrderModel order;

  @override
  void initState() {
    super.initState();
    order = widget.orderModel;
  }

  void _refreshData() async {
    final doc = await FirebaseFirestore.instance
        .collection('Orders')
        .doc(order.id)
        .get();
    if (doc.exists) {
      setState(() => order = OrderModel.fromJson(doc.data()!, doc.id));
    }
  }

  void onReceiveOrder() async {
    Info.showLoading(context, message: "Konfirmasi penerimaan...");
    bool success = await OrderSource.updateStatus(order.id, 'Berlangsung');
    Info.hideLoading();
    if (success) {
      Info.success("Motor diterima!");
      _refreshData();
    } else {
      Info.error("Gagal update status");
    }
  }

  void onContactCS() async {
    Info.showLoading(context, message: 'Menghubungkan...');
    try {
      final userSession = await DSession.getUser();
      if (userSession == null) {
        Info.hideLoading();
        Info.error("Sesi habis, silakan login kembali.");
        return;
      }
      final account = Account.fromJson(Map.from(userSession));

      await ChatSource.openChatRoom(account.uid, account.name);

      final snapshotData = {
        'isOrderSnapshot': true,
        'orderId': order.id,
        'bikeName': order.bikeSnapshot['name'],
        'bikeImage': order.bikeSnapshot['image'],
        'userName': order.userName,
        'totalPrice': order.totalPrice,
        'status': order.status,
        'startDate': order.startDate,
        'endDate': order.endDate,
      };

      String messageText =
          'Halo CS, saya butuh bantuan untuk pesanan ini.\n'
          'ID Pesanan : ${order.id.substring(0, 8).toUpperCase()}';

      Chat chat = Chat(
        roomId: account.uid,
        message: messageText,
        receiverId: 'cs',
        senderId: account.uid,
        bikeDetail: snapshotData,
      );

      await ChatSource.send(chat, account.uid);
      Info.hideLoading();
      Navigator.pushNamed(
        context,
        '/chatting',
        arguments: {'uid': account.uid, 'userName': account.name},
      );
    } catch (e) {
      Info.hideLoading();
      Info.error("Gagal membuka chat: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xff070623),
                      size: 22,
                    ),
                  ),
                ),
              ),
              const Text(
                'Pesanan',
                style: TextStyle(
                  color: Color(0xff070623),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          _buildCard1_MainDetail(),
          const Gap(20),
          _buildCard2_StatusTimeline(),
          const Gap(20),
          _buildCard3_Insurance(),
          const Gap(20),
          _buildCard4_PriceDetails(),
          const Gap(20),
          _buildCard5_PaymentMethod(),
          const Gap(30),
          _buildActionButtons(),
          const Gap(30),
        ],
      ),
    );
  }

  Widget _buildCard1_MainDetail() {
    Color headerColor = Colors.grey;
    String headerText = "Sedang Dikirim";
    if (order.status == 'Berlangsung') {
      headerColor = const Color(0xff070623);
      headerText = "Sedang Berlangsung";
    } else if (order.status == 'Selesai') {
      headerColor = const Color(0xff1AC75A);
      headerText = "Pesanan Selesai";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Text(
              headerText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ExtendedImage.network(
                        order.bikeSnapshot['image'] ?? '',
                        width: 60,
                        height: 50,
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
                            order.bikeSnapshot['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xff070623),
                            ),
                          ),
                          Text(
                            order.bikeSnapshot['category'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xff838384),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                Row(
                  children: const [
                    Icon(Icons.error, color: Color(0xffFF2055), size: 18),
                    Gap(8),
                    Text(
                      "Tidak bisa reschedule",
                      style: TextStyle(fontSize: 12, color: Color(0xff838384)),
                    ),
                  ],
                ),
                const Gap(20),
                const Text(
                  "Data Penyewa",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xff070623),
                  ),
                ),
                const Gap(8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xffEFEEF7)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff070623),
                        ),
                      ),
                      const Gap(4),
                      Text(
                        "${order.userEmail} • ${order.userPhone}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff838384),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(20),
                _buildLabelValue("Lokasi Pengambilan *", order.pickupLocation),
                const Gap(16),
                _buildLabelValue("Lokasi Pengembalian *", order.returnLocation),
                const Gap(16),
                RichText(
                  text: const TextSpan(
                    text: "Durasi Sewa",
                    style: TextStyle(
                      color: Color(0xff070623),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                    children: [
                      TextSpan(
                        text: " *",
                        style: TextStyle(color: Color(0xffFF2055)),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Pengambilan :",
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xff838384),
                          ),
                        ),
                        Text(
                          order.startDate,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff070623),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Pengembalian :",
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xff838384),
                          ),
                        ),
                        Text(
                          order.endDate,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff070623),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard2_StatusTimeline() {
    int level = 1;
    if (order.status == 'Berlangsung') level = 2;
    if (order.status == 'Selesai') level = 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Status Pesanan",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xff070623),
            ),
          ),
          const Gap(20),
          Row(
            children: [
              _buildTimelineStep(
                icon: Icons.local_shipping_outlined,
                label: "Sedang\nDikirim",
                isActive: level >= 1,
                isCurrent: level == 1,
                isCheck: false,
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color: level >= 2
                      ? const Color(0xffE5E7EB)
                      : const Color(0xffF3F4F6),
                ),
              ),
              _buildTimelineStep(
                icon: Icons.calendar_today_outlined,
                label: "Sedang\nBerlangsung",
                isActive: level >= 2,
                isCurrent: level == 2,
                isCheck: false,
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color: level >= 3
                      ? const Color(0xffE5E7EB)
                      : const Color(0xffF3F4F6),
                ),
              ),
              _buildTimelineStep(
                icon: Icons.check,
                label: "Pesanan\nSelesai",
                isActive: level >= 3,
                isCurrent: level == 3,
                isCheck: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isCurrent,
    required bool isCheck,
  }) {
    Color circleColor = const Color(0xffF3F4F6);
    Color iconColor = const Color(0xff9CA3AF);
    if (isActive) {
      if (isCurrent || (isCheck && isActive)) {
        circleColor = const Color(0xffFFBC1C);
        iconColor = const Color(0xff070623);
      } else {
        circleColor = const Color(0xffE5E7EB);
        iconColor = const Color(0xff6B7280);
      }
    }
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const Gap(8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? const Color(0xff070623) : const Color(0xff9CA3AF),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildCard3_Insurance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Asuransi",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xff070623),
            ),
          ),
          const Gap(12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified_user,
                    color: Color(0xff4A1DFF),
                    size: 20,
                  ),
                  const Gap(8),
                  Text(
                    order.insuranceName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff070623),
                    ),
                  ),
                ],
              ),
              Text(
                NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(order.insurancePrice),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff4A1DFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard4_PriceDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Rincian Harga",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xff070623),
            ),
          ),
          const Gap(16),
          _buildPriceRow("Harga Sewa (${order.duration} hari)", order.subTotal),
          _buildPriceRow("Asuransi", order.insurancePrice),
          _buildPriceRow("Pajak 11%", order.tax),
          const Divider(height: 24, color: Color(0xffEFEEF7)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Harga",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xff070623),
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
                  fontSize: 16,
                  color: Color(0xff4A1DFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard5_PaymentMethod() {
    String method = order.paymentMethod.toLowerCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Metode Pembayaran",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xff070623),
            ),
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPaymentIcon(
                'assets/wallet.png',
                'My Wallet',
                method.contains('wallet'),
              ),
              // [PERBAIKAN] Tambahkan pengecekan string 'lainnya' untuk deteksi pembayaran via Midtrans
              _buildPaymentIcon(
                'assets/cards.png',
                'Lainnya',
                method.contains('transfer') || method.contains('lainnya'),
              ),
              _buildPaymentIcon(
                'assets/cash.png',
                'Cash',
                method.contains('cash'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentIcon(String asset, String label, bool isSelected) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xffF3E8FF) : const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xff4A1DFF) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Image.asset(
            asset,
            width: 24,
            height: 24,
            color: isSelected ? const Color(0xff4A1DFF) : Colors.grey,
          ),
          const Gap(8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? const Color(0xff4A1DFF) : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    Widget yellowButton(String text, VoidCallback onTap) {
      return Material(
        color: const Color(0xffFFBC1C),
        borderRadius: BorderRadius.circular(50),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    Widget whiteButton(String text, VoidCallback onTap) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: const Color(0xffE5E7EB), width: 1),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xff070623),
              ),
            ),
          ),
        ),
      );
    }

    if (order.status == 'Dikirim') {
      return Column(
        children: [
          yellowButton("Konfirmasi Pesanan", onReceiveOrder),
          const Gap(12),
          whiteButton("Hubungi Customer Service", onContactCS),
        ],
      );
    } else if (order.status == 'Berlangsung') {
      return yellowButton("Hubungi Customer Service", onContactCS);
    } else {
      return Column(
        children: [
          yellowButton("Hubungi Customer Service", onContactCS),
          const Gap(12),
          whiteButton("Pemesanan Motor Lainnya", () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/discover',
              (route) => false,
              arguments: {'initialIndex': 0},
            );
          }),
        ],
      );
    }
  }

  Widget _buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label.replaceAll('*', ''),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff838384),
              fontFamily: 'Poppins',
            ),
            children: const [
              TextSpan(
                text: " *",
                style: TextStyle(color: Color(0xffFF2055)),
              ),
            ],
          ),
        ),
        const Gap(4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xff070623),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, num value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xff838384)),
          ),
          Text(
            NumberFormat.currency(
              locale: 'id',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(value),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xff070623),
            ),
          ),
        ],
      ),
    );
  }
}
