import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:ngibrit_in/common/info.dart';
import 'package:ngibrit_in/models/chat.dart';
import 'package:ngibrit_in/models/order_model.dart';
import 'package:ngibrit_in/pages/order_detail_page.dart';
import 'package:ngibrit_in/source/chat_source.dart';

class ChattingPage extends StatefulWidget {
  const ChattingPage({super.key, required this.uid, required this.userName});
  final String uid;
  final String userName;

  @override
  State<ChattingPage> createState() => _ChattingPageState();
}

class _ChattingPageState extends State<ChattingPage> {
  final edtInput = TextEditingController();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> streamChats;

  String formatTimestamp(Timestamp timestamp) {
    return DateFormat('HH:mm').format(timestamp.toDate());
  }

  // Helper Format Currency
  String formatCurrency(num price) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  @override
  void initState() {
    // Path Firestore untuk User: CS -> uid -> chats
    streamChats = FirebaseFirestore.instance
        .collection('CS')
        .doc(widget.uid)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots();
    super.initState();
  }

  // [LOGIC] Navigasi ke Detail Order
  void _navigateToDetail(String orderId) async {
    Info.showLoading(context, message: "Memuat pesanan...");
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Orders')
          .doc(orderId)
          .get();
      Info.hideLoading();

      if (doc.exists && mounted) {
        // Parsing ke OrderModel User
        final orderData = OrderModel.fromJson(doc.data()!, doc.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailPage(orderModel: orderData),
          ),
        );
      } else {
        Info.error("Data pesanan tidak ditemukan");
      }
    } catch (e) {
      Info.hideLoading();
      Info.error("Gagal memuat pesanan");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Gap(20 + MediaQuery.of(context).padding.top),
          buildHeader(context),
          Expanded(child: buildChats()),
          buildInputChat(),
        ],
      ),
    );
  }

  Widget buildChats() {
    return StreamBuilder(
      stream: streamChats,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Belum ada pesan'));
        }

        final list = snapshot.data!.docs;
        return ListView.builder(
          reverse: true,
          itemCount: list.length,
          padding: const EdgeInsets.only(top: 20),
          itemBuilder: (context, index) {
            Chat chat = Chat.fromJson(list[index].data());
            // Jika pengirim 'cs' -> Tampilkan di Kiri (chatCS)
            if (chat.senderId == 'cs') {
              return chatCS(chat);
            }
            // Jika pengirim User -> Tampilkan di Kanan (chatUser)
            return chatUser(chat);
          },
        );
      },
    );
  }

  Widget chatUser(Chat chat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (chat.bikeDetail != null)
          Column(
            children: [
              const Gap(16),
              buildSnippetBike(chat.bikeDetail!),
              // [UI] Garis Putus di bawah Snippet User
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: DottedLine(dashColor: Color(0xffCECED5)),
              ),
            ],
          ),
        Container(
          margin: const EdgeInsets.only(left: 49, right: 24),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xff070623),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                chat.message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.8,
                ),
              ),
              const Gap(4),
              if (chat.timestamp != null)
                Text(
                  formatTimestamp(chat.timestamp!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xffCECED5),
                  ),
                ),
            ],
          ),
        ),
        const Gap(12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              widget.userName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xff070623),
              ),
            ),
            const Gap(8),
            Image.asset('assets/profile.png', height: 40, width: 40),
            const Gap(24),
          ],
        ),
        const Gap(20),
      ],
    );
  }

  Widget chatCS(Chat chat) {
    // Cek apakah ini snippet order
    bool isOrderSnapshot =
        chat.bikeDetail != null &&
        (chat.bikeDetail!['isOrderSnapshot'] ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chat.bikeDetail != null)
          Column(
            children: [
              const Gap(16),
              // [FIX] Tampilkan Snippet dari CS
              buildSnippetBike(chat.bikeDetail!),

              // [UI] Garis Putus di bawah Snippet CS
              if (isOrderSnapshot)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: DottedLine(dashColor: Color(0xffCECED5)),
                ),
            ],
          ),

        Container(
          margin: const EdgeInsets.only(right: 49, left: 24),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chat.message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xff070623),
                  height: 1.8,
                ),
              ),
              const Gap(4),
              if (chat.timestamp != null)
                Text(
                  formatTimestamp(chat.timestamp!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff838384),
                  ),
                ),
            ],
          ),
        ),
        const Gap(12),
        Row(
          children: [
            const Gap(24),
            Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: Image.asset('assets/logo_ngibritin.png'), // Atau Asset CS
            ),
            const Gap(8),
            const Text(
              'CS Ngibrit.in',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xff070623),
              ),
            ),
          ],
        ),
        const Gap(20),
      ],
    );
  }

  Widget buildInputChat() {
    return Container(
      height: 52,
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 30),
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: edtInput,
              onChanged: (value) => setState(() {}),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xff070623),
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(0),
                isDense: true,
                border: InputBorder.none,
                hintText: 'Tulis pesan kamu disini...',
                hintStyle: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff838384),
                ),
              ),
            ),
          ),
          if (edtInput.text.trim().isNotEmpty)
            IconButton(
              onPressed: () {
                Chat chat = Chat(
                  roomId: widget.uid,
                  message: edtInput.text.trim(),
                  receiverId: 'cs',
                  senderId: widget.uid,
                  bikeDetail: null,
                );
                ChatSource.send(chat, widget.uid).then((value) {
                  edtInput.clear();
                  setState(() {});
                });
              },
              icon: Image.asset('assets/ic_send.png', height: 24, width: 24),
            ),
        ],
      ),
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
                height: 24,
                width: 24,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Customer Service',
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
            child: Image.asset('assets/ic_more.png', height: 24, width: 24),
          ),
        ],
      ),
    );
  }

  // [PERBAIKAN] Widget Snippet untuk Aplikasi User
  // Support format lama (Detail Motor) dan format baru (Snapshot Order)
  // [FIX 1B] Update Tampilan & Logika Klik Snippet
  Widget buildSnippetBike(Map bike) {
    bool isOrderSnapshot = bike['isOrderSnapshot'] ?? false;

    // Data Extraction
    String title = isOrderSnapshot
        ? (bike['bikeName'] ?? 'Motor')
        : (bike['name'] ?? 'Motor');
    String imageUrl = isOrderSnapshot
        ? (bike['bikeImage'] ?? '')
        : (bike['image'] ?? '');
    String statusOrCategory = isOrderSnapshot
        ? (bike['status'] ?? '-')
        : (bike['category'] ?? '-');
    String orderId = isOrderSnapshot
        ? (bike['orderId'] ?? '')
        : (bike['id'] ?? '');

    // [BARU] Ambil data tambahan
    num totalPrice = isOrderSnapshot ? (bike['totalPrice'] ?? 0) : 0;
    String dateRange = isOrderSnapshot
        ? '${bike['startDate']} - ${bike['endDate']}'
        : '';

    String safeOrderId = (orderId.length >= 5)
        ? orderId.substring(0, 5).toUpperCase()
        : orderId.toUpperCase();

    // Warna Status
    Color statusColor = const Color(0xff838384);
    Color statusBg = const Color(0xffF3F4F6);
    if (statusOrCategory == 'Dikirim') {
      statusColor = const Color(0xffFFBC1C);
      statusBg = const Color(0xffFFF8E1);
    } else if (statusOrCategory == 'Berlangsung') {
      statusColor = const Color(0xff4A1DFF);
      statusBg = const Color(0xffEFEEF7);
    } else if (statusOrCategory == 'Selesai') {
      statusColor = const Color(0xff1AC75A);
      statusBg = const Color(0xffE8F9EE);
    }

    return GestureDetector(
      onTap: () {
        if (orderId.isNotEmpty) {
          if (isOrderSnapshot) {
            // [FIX] Navigasi ke Detail Order jika diklik
            _navigateToDetail(orderId);
          } else {
            // Jika info motor biasa -> Navigasi ke Detail Motor
            Navigator.pushNamed(context, '/detail', arguments: orderId);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: const Color(0xffE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ExtendedImage.network(
                    imageUrl,
                    width: 70,
                    height: 60,
                    fit: BoxFit.contain,
                    cache: true,
                    loadStateChanged: (state) =>
                        state.extendedImageLoadState == LoadState.failed
                        ? const Icon(Icons.broken_image, color: Colors.grey)
                        : null,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff070623),
                        ),
                      ),
                      const Gap(4),
                      if (isOrderSnapshot) ...[
                        Text(
                          "ID: $safeOrderId",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xff838384),
                          ),
                        ),
                        // [BARU] Tampilkan Tanggal Sewa di Snippet User
                        Text(
                          dateRange,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xff838384),
                          ),
                        ),
                      ] else
                        Text(
                          statusOrCategory,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff838384),
                          ),
                        ),
                    ],
                  ),
                ),

                // Tombol Detail untuk Motor Biasa
                if (!isOrderSnapshot)
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/detail',
                        arguments: orderId,
                      );
                    },
                    child: const Text(
                      "Detail",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff4A1DFF),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),

            // Footer Khusus Order Snapshot
            if (isOrderSnapshot) ...[
              const Gap(12),
              const Divider(height: 1, color: Color(0xffF3F4F6)),
              const Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total: ${formatCurrency(totalPrice)}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff070623),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusOrCategory,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
