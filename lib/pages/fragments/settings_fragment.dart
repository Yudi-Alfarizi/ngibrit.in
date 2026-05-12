import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_session/d_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ngibrit_in/common/info.dart';
import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/pages/edit_profile_page.dart';

class SettingsFragment extends StatefulWidget {
  const SettingsFragment({super.key});

  @override
  State<SettingsFragment> createState() => _SettingsFragmentState();
}

class _SettingsFragmentState extends State<SettingsFragment> {
  logout() {
    DSession.removeUser().then((removed) {
      if (!removed) return;
      Navigator.pushReplacementNamed(context, '/signin');
    });
  }

  Map<String, dynamic> getKycUI(String status) {
    switch (status) {
      case 'VERIFIED':
        return {'color': const Color(0xff1AC75A), 'bg': const Color(0xffE8F9EE), 'text': 'Terverifikasi', 'icon': Icons.check_circle};
      case 'PENDING':
        return {'color': const Color(0xffFF9F00), 'bg': const Color(0xffFFF4E5), 'text': 'Dalam Proses', 'icon': Icons.access_time_filled};
      case 'REJECTED':
        return {'color': const Color(0xffFF2055), 'bg': const Color(0xffFFF1F3), 'text': 'Ditolak', 'icon': Icons.cancel};
      default:
        return {'color': const Color(0xff838384), 'bg': const Color(0xffF3F4F6), 'text': 'Belum Verifikasi', 'icon': Icons.info};
    }
  }

  void _handleKycTap(Account account) {
    if (account.kycStatus == 'PENDING') {
      Info.success("Dokumen Anda sedang ditinjau. Mohon tunggu.");
    } else if (account.kycStatus == 'VERIFIED') {
      Info.success("Akun Anda sudah terverifikasi!");
    } else {
      Navigator.pushNamed(context, '/upload-kyc');
    }
  }

  void _showChangePasswordDialog() {
    final edtOldPassword = TextEditingController();
    final edtNewPassword = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text("Ubah Kata Sandi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: edtOldPassword, obscureText: true,
                  decoration: const InputDecoration(hintText: "Kata Sandi Lama", border: OutlineInputBorder()),
                ),
                const Gap(16),
                TextField(
                  controller: edtNewPassword, obscureText: true,
                  decoration: const InputDecoration(hintText: "Kata Sandi Baru (Min. 6 Karakter)", border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: isLoading ? null : () => Navigator.pop(dialogContext), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff4A1DFF)),
                onPressed: isLoading ? null : () async {
                  if (edtOldPassword.text.isEmpty || edtNewPassword.text.length < 6) {
                    Info.error("Sandi lama wajib diisi & sandi baru minimal 6 karakter."); return;
                  }
                  setStateDialog(() => isLoading = true);
                  try {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user == null || user.email == null) {
                      setStateDialog(() => isLoading = false); Info.error("Sesi tidak valid."); return;
                    }
                    AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: edtOldPassword.text);
                    await user.reauthenticateWithCredential(credential);
                    await user.updatePassword(edtNewPassword.text);
                    if (mounted) { Navigator.pop(dialogContext); Info.success("Kata sandi berhasil diubah!"); }
                  } on FirebaseAuthException catch (e) {
                    setStateDialog(() => isLoading = false);
                    if (e.code == 'wrong-password' || e.code == 'invalid-credential') Info.error("Kata sandi lama Anda salah.");
                    else if (e.code == 'requires-recent-login') Info.error("Sesi telah kedaluwarsa. Silakan Logout dan Login kembali.");
                    else Info.error("Gagal: ${e.message}");
                  } catch (e) {
                    setStateDialog(() => isLoading = false); Info.error("Terjadi kesalahan sistem.");
                  }
                },
                child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Simpan", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: DSession.getUser(),
      builder: (context, sessionSnapshot) {
        // Hanya memuat sekilas dari memori lokal (sangat cepat)
        if (sessionSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!sessionSnapshot.hasData || sessionSnapshot.data == null) {
          return const Center(child: Text("Sesi tidak ditemukan, silakan login ulang."));
        }

        // Ambil data lokal sebagai FALLBACK AWAL
        Map<String, dynamic> localData = Map<String, dynamic>.from(sessionSnapshot.data!);
        String? uid = localData['uid'];

        if (uid == null) {
          return const Center(child: Text("Data pengguna rusak, silakan login ulang."));
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('User').doc(uid).snapshots(),
          builder: (context, firestoreSnapshot) {
            
            // [PERBAIKAN UTAMA: OFFLINE-FIRST]
            // Kita SELALU menampilkan UI menggunakan data lokal terlebih dahulu.
            // Jika Firestore berhasil mengirim data baru secara real-time, kita timpa data lokal tersebut.
            // Ini mencegah layar STUCK/BLANK saat jaringan buruk atau emulator error.
            Map<String, dynamic> activeData = localData;

            if (firestoreSnapshot.hasData && firestoreSnapshot.data!.exists) {
              activeData = Map<String, dynamic>.from(firestoreSnapshot.data!.data() as Map);
              activeData['uid'] = uid; // Pastikan uid tidak hilang
            }

            Account account;
            try {
              account = Account.fromJson(activeData);
            } catch (e) {
              return Center(child: Text("Gagal memuat profil: $e"));
            }

            return ListView(
              padding: const EdgeInsets.all(0),
              children: [
                Gap(30 + MediaQuery.of(context).padding.top),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text('Opsi Pengaturan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xff070623))),
                ),
                const Gap(20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      buildProfile(account),
                      const Gap(30),
                      
                      buildItemSetting(
                        'assets/ic_insurance.png', 'Verifikasi Identitas (KYC)', () => _handleKycTap(account), trailing: _buildSmallBadge(account.kycStatus),
                      ),
                      const Gap(20),

                      buildItemSetting('assets/ic_profile.png', 'Edit Profile', () {
                        Navigator.push(context, MaterialPageRoute(builder: (c) => const EditProfilePage())).then((_) => setState((){}));
                      }),
                      const Gap(20),
                      
                      buildItemSetting('assets/wallet.png', 'Dompet Digital Saya', null),
                      const Gap(20),
                      buildItemSetting('assets/ic_rate.png', 'Nilai Aplikasi Ini', null),
                      const Gap(20),
                      
                      buildItemSetting('assets/ic_key.png', 'Ubah Kata Sandi', _showChangePasswordDialog),
                      const Gap(20),
                      
                      buildItemSetting('assets/ic_key.png', 'Ubah Pin', null),
                      const Gap(20),
                      buildItemSetting('assets/ic_logout.png', 'Keluar', logout),
                    ],
                  ),
                ),
                const Gap(120), 
              ],
            );
          }
        );
      }
    );
  }

  Widget buildItemSetting(String icon, String name, VoidCallback? onTap, {Widget? trailing}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.transparent, borderRadius: BorderRadius.circular(50),
          border: Border.all(color: const Color(0xffEFEEF7), width: 1),
        ),
        child: Row(
          children: [
            Image.asset(icon, height: 24, width: 24), const Gap(14),
            Expanded(child: Text(name, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: onTap == null ? Colors.grey : const Color(0xff070623)))),
            if (trailing != null) trailing,
            if (trailing == null) Image.asset('assets/ic_arrow_next.png', height: 20, width: 20, color: onTap == null ? Colors.grey : null),
          ],
        ),
      ),
    );
  }

  Widget buildProfile(Account account) {
    final kycUI = getKycUI(account.kycStatus);
    return Row(
      children: [
        ClipOval(
          child: Container(
            width: 50, height: 50, color: Colors.grey[200],
            child: account.profileUrl != null ? Image.network(account.profileUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Image.asset('assets/profile.png', fit: BoxFit.cover)) : Image.asset('assets/profile.png', fit: BoxFit.cover),
          ),
        ),
        const Gap(20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(account.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xff070623))),
              const Gap(4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: kycUI['bg'], borderRadius: BorderRadius.circular(12), border: Border.all(color: kycUI['color'], width: 0.5)),
                    child: Row(
                      children: [
                        Icon(kycUI['icon'], size: 12, color: kycUI['color']), const Gap(4),
                        Text(kycUI['text'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kycUI['color'])),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildSmallBadge(String status) {
    final kycUI = getKycUI(status);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: kycUI['bg'], shape: BoxShape.circle),
      child: Icon(kycUI['icon'], size: 14, color: kycUI['color']),
    );
  }
}