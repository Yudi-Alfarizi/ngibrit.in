import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_session/d_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ngibrit_in/models/account.dart';

class AuthSource{
  static Future<String> signUp(
    String name,
    String email,
    String password,)
    async {
      try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          Account account = Account(
          uid: credential.user!.uid,
          name: name,
          email: email);
          await FirebaseFirestore.instance
            .collection('User')
            .doc(account.uid)
            .set(account.toJson());
          return 'success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'Kata sandi yang diberikan terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        return 'Akun untuk email tersebut sudah terdaftar.';
      }
      log(e.toString());
      return "ada masalah";
    } catch (e) {
      log(e.toString());
      return "ada masalah";
    }
  }

  static Future<String> signIn(String email,String password,) async {
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final accountDoc = await FirebaseFirestore.instance
          .collection('User')
          .doc(credential.user!.uid)
          .get();
        await DSession.setUser(Map.from (accountDoc.data()!));
        return "success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Tidak ada pengguna yang ditemukan.';
      } else if (e.code == 'wrong-password') {
        return 'Kata sandi yang diberikan salah.';
      }
      log(e.toString());
      return "ada masalah";
    } catch (e) {
      log(e.toString());
      return "ada masalah";
    }
  }
}