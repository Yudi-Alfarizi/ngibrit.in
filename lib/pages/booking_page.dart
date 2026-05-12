import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_session/d_session.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:ngibrit_in/common/info.dart';
import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/models/bike.dart';
import 'package:ngibrit_in/widgets/button_primary.dart';
import 'package:ngibrit_in/widgets/input.dart';
import 'package:ngibrit_in/widgets/multi_drop_down.dart';

// [IMPORT BARU] Untuk sistem Hub dinamis
import 'package:ngibrit_in/models/hub.dart';
import 'package:ngibrit_in/source/hub_source.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key, required this.bike});
  final Bike bike;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final edtName = TextEditingController();
  final edtPhone = TextEditingController();
  final edtStartDate = TextEditingController();
  final edtEndDate = TextEditingController();

  final FocusNode focusName = FocusNode();
  final FocusNode focusPhone = FocusNode();

  bool isDelivery = true;
  String? selectedPickupAddress;
  String? selectedReturnAddress;

  double deliveryDistance = 0.0;
  num deliveryFee = 0;
  final num pricePerKm = 2000;

  String? selectedInsurance;
  final List<String> insuranceList = ['Allianz', 'Astra Life', 'Prudential'];

  Account? account;

  // [VARIABLE BARU] Untuk menampung data garasi (Hub) dari Firebase
  Hub? selectedHub;

  @override
  void initState() {
    super.initState();
    _fetchUser();

    // [FUNGSI BARU] Mengambil data cabang (Hub) secara dinamis
    _fetchHubData();

    focusName.addListener(() {
      if (!focusName.hasFocus &&
          edtName.text.trim().isEmpty &&
          account != null) {
        setState(() => edtName.text = account!.name);
      }
    });

    focusPhone.addListener(() {
      if (!focusPhone.hasFocus &&
          edtPhone.text.trim().isEmpty &&
          account != null) {
        try {
          // ignore: avoid_dynamic_calls
          final phone = (account as dynamic).phoneNumber;
          if (phone != null && phone.toString().isNotEmpty) {
            setState(() => edtPhone.text = phone);
          }
        } catch (_) {}
      }
    });
  }

  // [FUNGSI BARU] Mengambil detail Alamat & Koordinat Hub dari Firestore
  void _fetchHubData() async {
    if (widget.bike.hubId.isNotEmpty) {
      final hub = await HubSource.getHub(widget.bike.hubId);
      if (mounted) {
        setState(() {
          selectedHub = hub;
        });
      }
    }
  }

  @override
  void dispose() {
    focusName.dispose();
    focusPhone.dispose();
    super.dispose();
  }

  void _fetchUser() async {
    final data = await DSession.getUser();
    if (data != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('User')
            .doc(data['uid'])
            .get();
        if (doc.exists) {
          final freshData = doc.data()!;
          await DSession.setUser(freshData);
          if (mounted) {
            setState(() {
              account = Account.fromJson(freshData);
              edtName.text = account?.name ?? '';
              try {
                // ignore: avoid_dynamic_calls
                final phone = (account as dynamic).phoneNumber;
                if (phone != null) edtPhone.text = phone;
              } catch (_) {}
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            account = Account.fromJson(Map.from(data));
            edtName.text = account?.name ?? '';
            try {
              // ignore: avoid_dynamic_calls
              final phone = (account as dynamic).phoneNumber;
              if (phone != null) edtPhone.text = phone;
            } catch (_) {}
          });
        }
      }
    }
  }

  // [PERBAIKAN LOGIKA] Fungsi pickDate dengan parameter isEndDate untuk validasi interaktif
  Future<void> pickDate(
    TextEditingController controller,
    bool isEndDate,
  ) async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: DateTime.now(),
    );

    if (pickedDate == null || !mounted) return;

    DateTime newDate = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
    );
    DateTime? startDate;
    DateTime? endDate;

    try {
      if (edtStartDate.text.isNotEmpty) {
        startDate = DateFormat('dd MMM yyyy').parse(edtStartDate.text);
      }
      if (edtEndDate.text.isNotEmpty) {
        endDate = DateFormat('dd MMM yyyy').parse(edtEndDate.text);
      }
    } catch (_) {}

    // Pengecekan Tanggal Akhir
    if (isEndDate) {
      if (startDate != null) {
        if (newDate.isAtSameMomentAs(startDate)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tanggal akhir harus lebih dari tanggal mulai (Minimal Sewa 1 Hari).',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        if (newDate.isBefore(startDate)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tanggal tidak valid. Tanggal akhir tidak boleh sebelum tanggal mulai.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    } else {
      // Pengecekan Tanggal Mulai (Auto-Reset End Date jika terlewati)
      if (endDate != null) {
        if (newDate.isAtSameMomentAs(endDate) || newDate.isAfter(endDate)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tanggal mulai melewati tanggal akhir. Silakan pilih ulang tanggal akhir Anda.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          edtEndDate.clear();
        }
      }
    }

    controller.text = DateFormat('dd MMM yyyy').format(newDate);
    setState(() {});
  }

  Future<void> openMapPicker(String type) async {
    final result = await Navigator.pushNamed(context, '/map-picker');

    if (result != null && result is Map) {
      final addr = result['address'] as String?;
      final lat = (result['lat'] ?? 0).toDouble();
      final lng = (result['lng'] ?? 0).toDouble();

      setState(() {
        if (type == 'pickup') {
          selectedPickupAddress = addr;
          if (isDelivery) {
            _calculateDeliveryFee(lat, lng);
          }
        } else {
          selectedReturnAddress = addr;
        }
      });
    }
  }

  void _calculateDeliveryFee(double userLat, double userLng) {
    // Default Koordinat jika kosong
    double hubLat = -6.175392;
    double hubLng = 106.827153;

    // [PERBAIKAN] Menggunakan koordinat dari koleksi Hubs secara dinamis
    if (selectedHub != null &&
        selectedHub!.latitude != 0.0 &&
        selectedHub!.longitude != 0.0) {
      hubLat = selectedHub!.latitude;
      hubLng = selectedHub!.longitude;
    } else if (widget.bike.hubLat != 0.0 && widget.bike.hubLng != 0.0) {
      hubLat = widget.bike.hubLat;
      hubLng = widget.bike.hubLng;
    }

    final Distance distance = const Distance();
    final double km = distance.as(
      LengthUnit.Kilometer,
      LatLng(hubLat, hubLng),
      LatLng(userLat, userLng),
    );

    setState(() {
      deliveryDistance = km;
      deliveryFee = (km * pricePerKm).round();
    });
  }

  String? validateForm() {
    if (edtName.text.isEmpty) return 'Nama lengkap harus diisi';

    String phoneInput = edtPhone.text.trim();
    if (phoneInput.isEmpty) return 'Nomor telephone harus diisi';
    if (!RegExp(r'^[0-9]+$').hasMatch(phoneInput)) return 'Hanya boleh angka';
    if (!phoneInput.startsWith('628')) return 'Wajib diawali 628';
    if (phoneInput.length < 10 || phoneInput.length > 14)
      return 'Nomor tidak valid (10-14 digit)';

    if (edtStartDate.text.isEmpty) return 'Tanggal mulai harus dipilih';
    if (edtEndDate.text.isEmpty) return 'Tanggal akhir harus dipilih';
    if (selectedInsurance == null) return 'Asuransi harus dipilih';

    if (isDelivery) {
      if (selectedPickupAddress == null)
        return 'Lokasi pengantaran wajib dipilih';
      if (deliveryDistance > 30)
        return 'Lokasi terlalu jauh (Maks 30 KM dari Garasi Cabang). Silakan ubah titik atau pilih Ambil Sendiri.';
    }

    // Safety net ganda (Fallback validation)
    try {
      final start = DateFormat('dd MMM yyyy').parse(edtStartDate.text);
      final end = DateFormat('dd MMM yyyy').parse(edtEndDate.text);
      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        return 'Durasi sewa minimal 1 hari (Tanggal akhir tidak valid)';
      }
    } catch (_) {}

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Booking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff070623),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff070623)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const Gap(10),
          buildSnippetBike(),
          const Gap(24),
          buildDeliveryToggle(),
          const Gap(24),
          buildInput(),
          const Gap(24),
          isDelivery
              ? buildLocationPickerDelivery()
              : buildLocationPickupSelf(),
          const Gap(24),
          buildInsurance(),
          const Gap(30),
          ButtonPrimary(
            text: 'Lanjut Checkout',
            onTap: () async {
              final err = validateForm();
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err), backgroundColor: Colors.red),
                );
                return;
              }

              if (account != null) {
                Info.showLoading(
                  context,
                  message: 'Memeriksa status verifikasi...',
                );
                try {
                  final doc = await FirebaseFirestore.instance
                      .collection('User')
                      .doc(account!.uid)
                      .get();
                  if (doc.exists) {
                    final freshData = doc.data()!;
                    account = Account.fromJson(freshData);
                    await DSession.setUser(freshData);
                  }
                } catch (e) {
                  debugPrint("Gagal sinkron KYC: $e");
                }
                Info.hideLoading();

                if (!account!.isVerified) {
                  _showKYCAlert();
                  return;
                }
              } else {
                _showKYCAlert();
                return;
              }

              final finalReturnAddress = isDelivery
                  ? (selectedReturnAddress ?? selectedPickupAddress)
                  : 'Kembali ke Garasi';

              Navigator.pushNamed(
                context,
                '/checkout',
                arguments: {
                  'bike': widget.bike,
                  'name': edtName.text.trim(),
                  'phone': edtPhone.text.trim(),
                  'startDate': edtStartDate.text.trim(),
                  'endDate': edtEndDate.text.trim(),
                  'pickup': isDelivery
                      ? selectedPickupAddress
                      : 'Ambil di Garasi (Self Pickup)',
                  'return': finalReturnAddress,
                  'insurance': selectedInsurance,
                  'isDelivery': isDelivery,
                  'deliveryFee': isDelivery ? deliveryFee : 0,
                  'deliveryDistance': deliveryDistance,
                },
              );
            },
          ),
          const Gap(30),
        ],
      ),
    );
  }

  Widget buildDeliveryToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xffF3F4F6),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Expanded(child: _toggleItem("Diantar", true)),
          Expanded(child: _toggleItem("Ambil Sendiri", false)),
        ],
      ),
    );
  }

  Widget _toggleItem(String title, bool val) {
    final active = isDelivery == val;
    return GestureDetector(
      onTap: () => setState(() {
        isDelivery = val;
        if (!isDelivery) {
          deliveryFee = 0;
          deliveryDistance = 0;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xff4A1DFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xff838384),
          ),
        ),
      ),
    );
  }

  Widget buildLocationPickerDelivery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Lokasi Pengantaran (Titik Jemput)",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const Gap(8),
        GestureDetector(
          onTap: () => openMapPicker('pickup'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xffFF2055)),
                const Gap(12),
                Expanded(
                  child: Text(
                    selectedPickupAddress ?? "Pilih lokasi di peta",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (deliveryDistance > 0 && deliveryDistance <= 30)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              "Jarak: ${deliveryDistance.toStringAsFixed(1)} km • Ongkir: Rp ${NumberFormat('#,###').format(deliveryFee)}",
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff4A1DFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else if (deliveryDistance > 30)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              "Jarak: ${deliveryDistance.toStringAsFixed(1)} km (Terlalu Jauh! Maks 30 km)",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        const Gap(16),
        const Text(
          "Lokasi Pengembalian (Opsional)",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const Gap(8),
        GestureDetector(
          onTap: () => openMapPicker('return'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag, color: Colors.grey),
                const Gap(12),
                Expanded(
                  child: Text(
                    selectedReturnAddress ??
                        (selectedPickupAddress ?? "Sama dengan lokasi antar"),
                    style: TextStyle(
                      color: selectedReturnAddress != null
                          ? Colors.black
                          : Colors.grey[600],
                      fontStyle: selectedReturnAddress == null
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // [PERBAIKAN] Menampilkan data Alamat HUB Dinamis dari Firebase
  Widget buildLocationPickupSelf() {
    String hubName = "Mencari Garasi...";
    String hubAddress = "Memuat alamat...";

    if (selectedHub != null) {
      hubName = "Ngibrit Point (${selectedHub!.name})";
      hubAddress = selectedHub!.address; // Ditarik langsung dari Firestore!
    } else if (widget.bike.hubId.isEmpty) {
      hubName = "Ngibrit Point (Pusat)";
      hubAddress = "Silakan hubungi CS untuk alamat detail.";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Silakan ambil unit di:",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Gap(4),
          Text(
            hubName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Gap(4),
          Text(hubAddress, style: const TextStyle(color: Color(0xff070623))),
          const Gap(12),
          Row(
            children: const [
              Icon(Icons.check_circle, size: 16, color: Color(0xff1AC75A)),
              Gap(6),
              Text(
                "Bebas Biaya Pengantaran",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xff1AC75A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showKYCAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Verifikasi KTP Diperlukan"),
        content: const Text(
          "Demi keamanan, Anda wajib mengunggah foto KTP dan Selfie sebelum menyewa kendaraan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Nanti Saja"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Navigator.pushNamed(context, '/upload-kyc');
              if (result == true) _fetchUser();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff4A1DFF),
            ),
            child: const Text(
              "Verifikasi Sekarang",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text(
              'Nama Lengkap',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Gap(8),
            Icon(Icons.edit, size: 14, color: Colors.grey),
          ],
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: TextField(
            controller: edtName,
            focusNode: focusName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff070623),
            ),
            decoration: InputDecoration(
              hintText: 'Nama Lengkap',
              hintStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xff838384),
              ),
              border: InputBorder.none,
              prefixIcon: UnconstrainedBox(
                alignment: const Alignment(0.5, 0),
                child: Image.asset(
                  'assets/ic_profile.png',
                  width: 24,
                  height: 24,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const Gap(16),
        Row(
          children: const [
            Text(
              'Nomor Handphone',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Gap(8),
            Icon(Icons.edit, size: 14, color: Colors.grey),
          ],
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: TextField(
            controller: edtPhone,
            focusNode: focusPhone,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff070623),
            ),
            decoration: InputDecoration(
              hintText: 'Cth: 628...',
              hintStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xff838384),
              ),
              border: InputBorder.none,
              prefixIcon: UnconstrainedBox(
                alignment: const Alignment(0.5, 0),
                child: Image.asset(
                  'assets/ic_telephone.png',
                  width: 24,
                  height: 24,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const Gap(16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mulai',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            GestureDetector(
              // Panggil pickDate dengan indikator isEndDate = false
              onTap: () => pickDate(edtStartDate, false),
              child: AbsorbPointer(
                child: Input(
                  icon: 'assets/ic_calendar.png',
                  hint: 'Pilih Tgl',
                  editingController: edtStartDate,
                  enable: true,
                  readOnly: true,
                ),
              ),
            ),
            const Gap(12),
            const Text(
              'Selesai',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            GestureDetector(
              // Panggil pickDate dengan indikator isEndDate = true
              onTap: () => pickDate(edtEndDate, true),
              child: AbsorbPointer(
                child: Input(
                  icon: 'assets/ic_calendar.png',
                  hint: 'Pilih Tgl',
                  editingController: edtEndDate,
                  enable: true,
                  readOnly: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildInsurance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Asuransi Perjalanan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const Gap(8),
        MultiLineDropdown(
          value: selectedInsurance,
          items: insuranceList,
          hint: "Pilih proteksi",
          icon: Image.asset("assets/ic_insurance.png", width: 28, height: 28),
          onSelected: (val) => setState(() => selectedInsurance = val),
        ),
      ],
    );
  }

  Widget buildSnippetBike() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          ExtendedImage.network(
            widget.bike.image,
            width: 80,
            height: 60,
            fit: BoxFit.contain,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.bike.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.bike.category,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
