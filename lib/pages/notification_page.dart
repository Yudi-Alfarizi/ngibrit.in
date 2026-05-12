import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_session/d_session.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:ngibrit_in/models/notification_model.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String? uid;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final session = await DSession.getUser();
    if (session != null && mounted) {
      setState(() {
        uid = session['uid'];
      });
    }
  }

  Future<void> _markAsRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('Notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEFEFF0),
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff070623),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff070623)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              // [PERBAIKAN] Menghapus orderBy agar terhindar dari Error Firebase Composite Index
              stream: FirebaseFirestore.instance
                  .collection('Notifications')
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Menangani error jika terjadi masalah koneksi
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Terjadi kesalahan: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // [PERBAIKAN] Mengurutkan data secara lokal (Dart) terbaru di atas
                var notifications = snapshot.data!.docs.toList();
                notifications.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final tA = dataA['createdAt'] as Timestamp?;
                  final tB = dataB['createdAt'] as Timestamp?;
                  if (tA == null || tB == null) return 0;
                  return tB.compareTo(tA); // Descending (Terbaru di atas)
                });

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) => const Gap(16),
                  itemBuilder: (context, index) {
                    final data =
                        notifications[index].data() as Map<String, dynamic>;
                    final notif = NotificationModel.fromJson(
                      data,
                      notifications[index].id,
                    );

                    return _buildNotifCard(notif);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/ic_notification.png',
            width: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const Gap(16),
          const Text(
            "Belum ada notifikasi",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(NotificationModel notif) {
    IconData icon;
    Color iconColor;

    switch (notif.type) {
      case 'booking':
        icon = Icons.check_circle;
        iconColor = const Color(0xff1AC75A);
        break;
      case 'message':
        icon = Icons.message;
        iconColor = const Color(0xff4A1DFF);
        break;
      case 'reminder':
        icon = Icons.alarm;
        iconColor = const Color(0xffFF9F00);
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    String timeFormatted = DateFormat(
      'dd MMM yyyy, HH:mm',
    ).format(notif.createdAt.toDate());

    return GestureDetector(
      onTap: () {
        if (!notif.isRead) _markAsRead(notif.id);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : const Color(0xffF3E8FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead
                ? Colors.transparent
                : const Color(0xff4A1DFF).withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: notif.isRead
                          ? const Color(0xff070623)
                          : const Color(0xff4A1DFF),
                    ),
                  ),
                  const Gap(4),
                  Text(
                    notif.body,
                    style: const TextStyle(
                      color: Color(0xff838384),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    timeFormatted,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
            if (!notif.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xffFF2055),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
