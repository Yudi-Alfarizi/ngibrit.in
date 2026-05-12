import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
  Stream<QuerySnapshot<Map<String, dynamic>>>? streamChats;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChatNetwork();
    });
  }

  void _initializeChatNetwork() async {
    ChatSource.openChatRoom(widget.uid, widget.userName).catchError((_) {});

    setState(() {
      streamChats = FirebaseFirestore.instance
          .collection('CS')
          .doc(widget.uid)
          .collection('chats')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots();
    });
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return DateFormat('HH:mm').format(DateTime.now());
    return DateFormat('HH:mm').format(timestamp.toDate());
  }

  String formatCurrency(num price) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  void _navigateToDetail(String orderId) async {
    Info.showLoading(context, message: "Memuat pesanan...");
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Orders')
          .doc(orderId)
          .get();
      Info.hideLoading();

      if (doc.exists && mounted) {
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

  // [PERBAIKAN LOGIKA MAPS] Sanitasi URL otomatis
  Future<void> _launchMapsUrl(String url) async {
    String cleanUrl = url.trim();

    // Jika URL berupa format aneh (cth: maps.google.com-6.14...,106.77...)
    // Kita ekstrak titik koordinatnya agar Google Maps tidak error
    if (!cleanUrl.startsWith('http')) {
      RegExp coordExp = RegExp(r"(-?\d+\.\d+,-?\d+\.\d+)");
      var match = coordExp.firstMatch(cleanUrl);
      if (match != null) {
        cleanUrl =
            'https://www.google.com/maps/search/?api=1&query=${match.group(0)}';
      } else {
        cleanUrl = 'https://$cleanUrl';
      }
    }

    final Uri uri = Uri.parse(cleanUrl);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      Info.error("Tidak dapat membuka peta: $e");
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
          ChatInputWidget(uid: widget.uid),
        ],
      ),
    );
  }

  Widget buildChats() {
    if (streamChats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: streamChats,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Terjadi kesalahan koneksi memuat pesan.",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

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
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          itemBuilder: (context, index) {
            try {
              Chat chat = Chat.fromJson(list[index].data());
              if (chat.senderId == 'cs') {
                return chatCS(chat);
              }
              return chatUser(chat);
            } catch (e) {
              return const SizedBox();
            }
          },
        );
      },
    );
  }

  // --- DESAIN KARTU PETA SEPERTI APP CS ---
  Widget _buildLocationBubble(String message, bool isSender) {
    String textContent = message;
    String url = "";

    // [PERBAIKAN REGEX] Menangkap link yang pakai HTTP atau khusus maps.google.com (walau tanpa HTTP)
    RegExp exp = RegExp(r"(https?:\/\/[^\s]+|maps\.google\.com[^\s]*)");
    Iterable<RegExpMatch> matches = exp.allMatches(message);

    if (matches.isNotEmpty) {
      url = matches.first.group(0)!;
      // Membuang URL dari pesan teks utama
      textContent = message.replaceAll(url, '').trim();
    }

    return Column(
      crossAxisAlignment: isSender
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        // BUBBLE TEXT UTAMA (Pesan Darurat)
        if (textContent.isNotEmpty)
          Container(
            margin: EdgeInsets.only(
              left: isSender ? 49 : 24,
              right: isSender ? 24 : 49,
              bottom: 8,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSender ? const Color(0xff070623) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isSender
                  ? null
                  : Border.all(color: const Color(0xffE5E7EB)),
            ),
            child: Text(
              textContent,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 1.5,
                color: isSender ? Colors.white : const Color(0xff070623),
              ),
            ),
          ),

        // KARTU PETA INTERAKTIF
        if (url.isNotEmpty)
          GestureDetector(
            onTap: () => _launchMapsUrl(url),
            child: Container(
              width: 240,
              margin: EdgeInsets.only(
                left: isSender ? 0 : 24,
                right: isSender ? 24 : 0,
              ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Container(
                          height: 130,
                          width: double.infinity,
                          color: const Color(0xffEFEFF0),
                          child: const Icon(
                            Icons.map_outlined,
                            color: Colors.grey,
                            size: 60,
                          ),
                        ),
                      ),
                      Container(
                        height: 130,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          color: Colors.black.withOpacity(0.05),
                        ),
                      ),
                      // Ikon Pin Peta
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xffFF2055),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Lokasi Terkini",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xff070623),
                          ),
                        ),
                        const Gap(4),
                        Row(
                          children: const [
                            Text(
                              "Ketuk untuk buka Google Maps",
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xff838384),
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.open_in_new,
                              size: 14,
                              color: Color(0xff838384),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget chatUser(Chat chat) {
    // [PERBAIKAN] Regex mendeteksi http atau string 'maps.google.com'
    bool isLocationMessage = RegExp(
      r"(https?:\/\/[^\s]+|maps\.google\.com[^\s]*)",
    ).hasMatch(chat.message);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (chat.bikeDetail != null)
          Column(
            children: [
              const Gap(16),
              buildSnippetBike(chat.bikeDetail!),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: DottedLine(dashColor: Color(0xffCECED5)),
              ),
            ],
          ),

        // Jika terdeteksi URL Maps/HTTP, buka bubble khusus
        if (isLocationMessage)
          _buildLocationBubble(chat.message, true)
        else
          Container(
            margin: const EdgeInsets.only(left: 49, right: 24),
            padding: const EdgeInsets.all(12),
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
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
                const Gap(4),
                Text(
                  formatTimestamp(chat.timestamp),
                  style: const TextStyle(
                    fontSize: 10,
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
                fontSize: 12,
                color: Color(0xff070623),
              ),
            ),
            const Gap(8),
            Image.asset('assets/profile.png', height: 32, width: 32),
            const Gap(24),
          ],
        ),
        const Gap(20),
      ],
    );
  }

  Widget chatCS(Chat chat) {
    bool isOrderSnapshot =
        chat.bikeDetail != null &&
        (chat.bikeDetail!['isOrderSnapshot'] ?? false);

    bool isLocationMessage = RegExp(
      r"(https?:\/\/[^\s]+|maps\.google\.com[^\s]*)",
    ).hasMatch(chat.message);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chat.bikeDetail != null)
          Column(
            children: [
              const Gap(16),
              buildSnippetBike(chat.bikeDetail!),
              if (isOrderSnapshot)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: DottedLine(dashColor: Color(0xffCECED5)),
                ),
            ],
          ),

        if (isLocationMessage)
          _buildLocationBubble(chat.message, false)
        else
          Container(
            margin: const EdgeInsets.only(right: 49, left: 24),
            padding: const EdgeInsets.all(12),
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
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xff070623),
                  ),
                ),
                const Gap(4),
                Text(
                  formatTimestamp(chat.timestamp),
                  style: const TextStyle(
                    fontSize: 10,
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
              height: 32,
              width: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: Image.asset('assets/logo-ngibritin.png'),
            ),
            const Gap(8),
            const Text(
              'CS Ngibrit.in',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xff070623),
              ),
            ),
          ],
        ),
        const Gap(20),
      ],
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

  Widget buildSnippetBike(Map bike) {
    bool isOrderSnapshot = bike['isOrderSnapshot'] ?? false;
    String title = isOrderSnapshot
        ? (bike['bikeName'] ?? 'Motor')
        : (bike['name'] ?? 'Motor');
    String imageUrl = isOrderSnapshot
        ? (bike['bikeImage'] ?? '')
        : (bike['image'] ?? '');
    String status = isOrderSnapshot
        ? (bike['status'] ?? '-')
        : (bike['category'] ?? '-');
    String orderId = isOrderSnapshot
        ? (bike['orderId'] ?? '')
        : (bike['id'] ?? '');
    num totalPrice = isOrderSnapshot ? (bike['totalPrice'] ?? 0) : 0;
    String safeOrderId = (orderId.length >= 5)
        ? orderId.substring(0, 5).toUpperCase()
        : orderId.toUpperCase();
    String dateRange = isOrderSnapshot
        ? '${bike['startDate']} - ${bike['endDate']}'
        : '';

    Color statusColor = const Color(0xff838384);
    Color statusBg = const Color(0xffF3F4F6);
    if (status.toLowerCase().contains('dikirim')) {
      statusColor = const Color(0xffFFBC1C);
      statusBg = const Color(0xffFFF8E1);
    } else if (status.toLowerCase().contains('berlangsung')) {
      statusColor = const Color(0xff4A1DFF);
      statusBg = const Color(0xffEFEEF7);
    } else if (status.toLowerCase().contains('selesai')) {
      statusColor = const Color(0xff1AC75A);
      statusBg = const Color(0xffE8F9EE);
    } else if (status.toLowerCase().contains('darurat')) {
      statusColor = const Color(0xffFF2055);
      statusBg = const Color(0xffFFF1F3);
    }

    return GestureDetector(
      onTap: () {
        if (orderId.isNotEmpty) {
          if (isOrderSnapshot)
            _navigateToDetail(orderId);
          else
            Navigator.pushNamed(context, '/detail', arguments: orderId);
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
                  child: imageUrl.isNotEmpty
                      ? ExtendedImage.network(
                          imageUrl,
                          width: 70,
                          height: 60,
                          fit: BoxFit.contain,
                          cache: true,
                        )
                      : Container(
                          width: 70,
                          height: 60,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
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
                        Text(
                          dateRange,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xff838384),
                          ),
                        ),
                      ] else
                        Text(
                          status,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff838384),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isOrderSnapshot)
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/detail',
                      arguments: orderId,
                    ),
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
                      status,
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

class ChatInputWidget extends StatefulWidget {
  final String uid;
  const ChatInputWidget({super.key, required this.uid});

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final edtInput = TextEditingController();
  bool isTyping = false;

  @override
  void dispose() {
    edtInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              onChanged: (value) {
                if (value.trim().isNotEmpty != isTyping) {
                  setState(() => isTyping = value.trim().isNotEmpty);
                }
              },
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
          if (isTyping)
            IconButton(
              onPressed: () {
                Chat chat = Chat(
                  roomId: widget.uid,
                  message: edtInput.text.trim(),
                  receiverId: 'cs',
                  senderId: widget.uid,
                  bikeDetail: null,
                );
                ChatSource.send(chat, widget.uid);
                edtInput.clear();
                setState(() => isTyping = false);
              },
              icon: Image.asset('assets/ic_send.png', height: 24, width: 24),
            ),
        ],
      ),
    );
  }
}
