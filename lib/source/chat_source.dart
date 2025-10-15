import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ngibrit_in/models/chat.dart';

class ChatSource {
  static Future<void> openChatRoom(String uid, String userName) async {
    final doc = await FirebaseFirestore.instance
        .collection('CS')
        .doc(uid)
        .get();

    if (doc.exists) {
      await FirebaseFirestore.instance.collection('CS').doc(uid).update({
        'newFromCS': false,
      });
      return;
    }

    // fisrt time chat room
    await FirebaseFirestore.instance.collection('CS').doc(uid).set({
      'roomId': uid,
      'name': userName,
      'lastMessage': 'Welcome to Ngibrit.in',
      'newFromUser': false,
      'newFromCS': true,
    });
    await FirebaseFirestore.instance
        .collection('CS')
        .doc(uid)
        .collection('chats')
        .add({
          'roomId': uid,
          'message': 'Welcome to Ngibrit.in',
          'receiverId': uid,
          'senderId': 'cs',
          'bikeDetail': null,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  static Future<void> send(Chat chat, String uid) async {
    await FirebaseFirestore.instance.collection('CS').doc(uid).update({
      'lastMessage': chat.message,
      'newFromUser': true,
      'newFromCS': false,
    });
    await FirebaseFirestore.instance
        .collection('CS')
        .doc(uid)
        .collection('caht')
        .add({
          'roomId': chat.roomId,
          'message': chat.message,
          'receiverId': chat.receiverId,
          'senderId': chat.senderId,
          'bikeDetail': chat.bikeDetail,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }
}
