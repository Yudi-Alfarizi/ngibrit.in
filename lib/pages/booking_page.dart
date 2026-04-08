import 'package:d_session/d_session.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/models/bike.dart';
import 'package:ngibrit_in/widgets/button_primary.dart';
import 'package:ngibrit_in/widgets/input.dart';
import 'package:ngibrit_in/widgets/multi_drop_down.dart';

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

  // FocusNode untuk mendeteksi kapan user selesai mengetik
  final FocusNode focusName = FocusNode();
  final FocusNode focusPhone = FocusNode();

  // Logic Pengiriman
  bool isDelivery = true; // Default Diantar
  String? selectedPickupAddress;
  String? selectedReturnAddress;

  // Logic Biaya
  double deliveryDistance = 0.0;
  num deliveryFee = 0;
  final num pricePerKm = 3000; // Rp 3.000 per KM

  String? selectedAgency;
  String? selectedInsurance;
  final List<String> insuranceList = ['Allianz', 'Astra Life', 'Prudential'];

  Account? account;

  @override
  void initState() {
    super.initState();
    _fetchUser();

    // Listener: Jika fokus hilang dan teks kosong, kembalikan ke data akun
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
        // Coba ambil no hp dari akun jika ada
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

  @override
  void dispose() {
    focusName.dispose();
    focusPhone.dispose();
    super.dispose();
  }

  void _fetchUser() async {
    final data = await DSession.getUser();
    if (data != null) {
      setState(() {
        account = Account.fromJson(Map.from(data));
        edtName.text = account?.name ?? '';
        // Auto-fill HP jika ada di model akun
        try {
          // ignore: avoid_dynamic_calls
          final phone = (account as dynamic).phoneNumber;
          if (phone != null) edtPhone.text = phone;
        } catch (_) {}
      });
    }
  }

  Future<void> pickDate(TextEditingController controller) async {
    final pickDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: DateTime.now(),
    );
    if (pickDate == null) return;
    if (!mounted) return;
    controller.text = DateFormat('dd MMM yyyy').format(pickDate);
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
    // Default koordinat jika data motor belum lengkap
    double hubLat = -6.175392;
    double hubLng = 106.827153;

    // Cek jika model Bike sudah punya lat/lng
    try {
      // ignore: avoid_dynamic_calls
      final bikeDynamic = widget.bike as dynamic;
      if (bikeDynamic.hubLat != 0) {
        hubLat = bikeDynamic.hubLat;
        hubLng = bikeDynamic.hubLng;
      }
    } catch (_) {}

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
    }

    try {
      final start = DateFormat('dd MMM yyyy').parse(edtStartDate.text);
      final end = DateFormat('dd MMM yyyy').parse(edtEndDate.text);
      if (end.isBefore(start)) return 'Tanggal akhir tidak valid';
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
            onTap: () {
              final err = validateForm();
              if (err != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(err)));
                return;
              }

              if (account != null && !account!.isVerified) {
                _showKYCAlert();
                return;
              }

              // [LOGIC PENGEMBALIAN]
              // Jika return address kosong, gunakan pickup address
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
                  'return':
                      finalReturnAddress, // Gunakan alamat yang sudah difix
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
        if (deliveryFee > 0)
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
                  // [LOGIC TAMPILAN] Tampilkan Hint Pickup jika Return Kosong
                  child: Text(
                    selectedReturnAddress ??
                        (selectedPickupAddress ?? "Sama dengan lokasi antar"),
                    style: TextStyle(
                      // Warna hitam jika sudah dipilih, abu-abu jika hint (default pickup)
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

  Widget buildLocationPickupSelf() {
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
          const Text(
            "Ngibrit Point (Hub Pusat)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Gap(4),
          const Text(
            "Jl. Jendral Sudirman No. 45, Jakarta Pusat",
            style: TextStyle(color: Color(0xff070623)),
          ),
          const Gap(12),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 16,
                color: Color(0xff1AC75A),
              ),
              const Gap(6),
              const Text(
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
              if (result == true) {
                _fetchUser();
              }
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
        // [NAMA] dengan Icon Edit & FocusNode
        Row(
          children: [
            const Text(
              'Nama Lengkap',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            const Icon(Icons.edit, size: 14, color: Colors.grey),
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
          // Menggunakan TextField standar agar support focusNode dengan benar
          // styling disamakan dengan input.dart
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

        // [NOMOR HP] dengan Icon Edit & FocusNode
        Row(
          children: [
            const Text(
              'Nomor Handphone',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            const Icon(Icons.edit, size: 14, color: Colors.grey),
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

        // [LAYOUT TANGGAL] Diubah menjadi Column agar tidak terpotong
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tanggal Mulai
            const Text(
              'Mulai',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            Input(
              icon: 'assets/ic_calendar.png',
              hint: 'Pilih Tgl',
              editingController: edtStartDate,
              enable: true,
              readOnly: true,
              onTapBox: () => pickDate(edtStartDate),
            ),

            const Gap(12),

            // Tanggal Selesai
            const Text(
              'Selesai',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            Input(
              icon: 'assets/ic_calendar.png',
              hint: 'Pilih Tgl',
              editingController: edtEndDate,
              enable: true,
              readOnly: true,
              onTapBox: () => pickDate(edtEndDate),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.bike.name,
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
        ],
      ),
    );
  }
}
