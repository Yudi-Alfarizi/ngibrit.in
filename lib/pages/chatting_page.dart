import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:ngibrit_in/models/chat.dart';
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

  @override
  void initState() {
    streamChats = FirebaseFirestore.instance
        .collection('CS')
        .doc(widget.uid)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots();
    super.initState();
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
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No Chats'));
        }
        final list = snapshot.data!.docs;
        return ListView.builder(
          reverse: true,
          itemCount: list.length,
          padding: const EdgeInsets.only(top: 20),
          itemBuilder: (context, index) {
            Chat chat = Chat.fromJson(list[index].data());
            if (chat.senderId == 'cs') {
              return chatCS(chat);
            }
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
              const Gap(16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: DottedLine(
                  dashColor: Color(0xffCECED5),
                  lineThickness: 1,
                  dashLength: 6,
                  dashGapLength: 6,
                ),
              ),
              const Gap(16),
            ],
          ),
        Container(
          margin: const EdgeInsets.only(left: 49, right: 24),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
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
            Image.asset('assets/chat_profile.png', height: 40, width: 40),
            const Gap(24),
          ],
        ),
        const Gap(20),
      ],
    );
  }

  Widget chatCS(Chat chat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 49, left: 24),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xff070623),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: Color(
                      0xffBDBDBD,
                    ),
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
              decoration: const BoxDecoration(
                color: Colors.white, // warna lingkaran
                shape: BoxShape.circle, // bentuk lingkaran
              ),
              child: Image.asset(
                'assets/logo-ngibritin.png',
                height: 40,
                width: 40,
                fit: BoxFit.contain,
              ),
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
                  color: Color(0xff070623),
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
                  setState(
                    () {},
                  );
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
                width: 24,
                height: 24,
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
            child: Image.asset('assets/ic_more.png', width: 24, height: 24),
          ),
        ],
      ),
    );
  }

  Widget buildSnippetBike(Map bike) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      height: 98,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Row(
        children: [
          ExtendedImage.network(
            bike['image'],
            width: 90,
            height: 70,
            fit: BoxFit.contain,
          ),
          const Gap(10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bike['name'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff070623),
                  ),
                ),
                Text(
                  bike['category'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff838384),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/detail', arguments: bike['id']);
            },
            child: const Text(
              'Detail',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 5,
                decorationThickness: 1,
                decoration: TextDecoration.underline,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xff4A1DFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
