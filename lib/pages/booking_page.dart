import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
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

  String? selectedPickup;
  String? selectedReturn;
  String? selectedAgency;
  String? selectedInsurance;

  final List<String> locationList = [
    'Jakarta Utara - Waduk Pluit',
    'Jakarta Barat - Stasiun Kota Jakarta',
    'Jakarta Timur - Condet',
    'Jakarta Selatan - Blok M',
    'Jakarta Pusat - Stasiun Gambir',
  ];

  final List<String> agencyList = ['Revolte', 'KBP City', 'Sumedap'];
  final List<String> insuranceList = ['Allianz', 'Astra Life', 'Prudential'];

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

  String? validateForm() {
    final name = edtName.text.trim();
    final phone = edtPhone.text.trim();
    final startDateText = edtStartDate.text.trim();
    final endDateText = edtEndDate.text.trim();

    if (name.isEmpty) {
      return 'Nama lengkap harus diisi';
    }

    if (phone.isEmpty) {
      return 'Nomor telephone harus diisi';
    }

    if (startDateText.isEmpty) {
      return 'Tanggal mulai sewa harus dipilih';
    }

    if (endDateText.isEmpty) {
      return 'Tanggal akhir sewa harus dipilih';
    }

    if (selectedPickup == null) {
      return 'Lokasi pengambilan harus dipilih';
    }

    if (selectedReturn == null) {
      return 'Lokasi pengembalian harus dipilih';
    }

    if (selectedAgency == null) {
      return 'Agency harus dipilih';
    }

    if (selectedInsurance == null) {
      return 'Asuransi harus dipilih';
    }

    try {
      final start = DateFormat('dd MMM yyyy').parseStrict(startDateText);
      final end = DateFormat('dd MMM yyyy').parseStrict(endDateText);
      if (end.isBefore(start)) {
        return 'Tanggal akhir harus setelah atau sama dengan tanggal mulai';
      }
    } catch (e) {
      return 'Format tanggal tidak valid';
    }

    return null;
  }

  bool _isSubmitting = false;

  @override
  void dispose() {
    edtName.dispose();
    edtPhone.dispose();
    edtStartDate.dispose();
    edtEndDate.dispose();
    super.dispose();
  }

  // Open the map picker and set the appropriate field based on returned 'type'
  Future<void> openMapPicker(BuildContext context, String type) async {
    final result = await Navigator.pushNamed(
      context,
      '/map-picker',
      arguments: type,
    );

    if (result != null && result is Map) {
      final addr = result['address'] as String?;
      final retType = result['type'] as String? ?? type;
      if (retType == 'pickup') {
        setState(() => selectedPickup = addr);
      } else if (retType == 'return') {
        setState(() => selectedReturn = addr);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight =
        kToolbarHeight + MediaQuery.of(context).padding.top + 32;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(height: headerHeight),
                const Gap(24),
                buildSnippetBike(),
                const Gap(24),
                buildInput(),
                const Gap(24),
                buildLocationPicker(),
                const Gap(24),
                buildAgency(),
                const Gap(24),
                buildInsurance(),
                const Gap(24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AbsorbPointer(
                    absorbing: _isSubmitting,
                    child: ButtonPrimary(
                      text: _isSubmitting ? 'Memproses...' : 'Buat Pesanan',
                      onTap: () async {
                        final err = validateForm();
                        if (err != null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(err)));
                          return;
                        }
                        setState(() => _isSubmitting = true);

                        try {
                          await Navigator.pushNamed(
                            context,
                            '/checkout',
                            arguments: {
                              'bike': widget.bike,
                              'name': edtName.text.trim(),
                              'phone': edtPhone.text.trim(),
                              'startDate': edtStartDate.text.trim(),
                              'endDate': edtEndDate.text.trim(),
                              'pickup': selectedPickup,
                              'return': selectedReturn,
                              'agency': selectedAgency,
                              'insurance': selectedInsurance,
                            },
                          );
                        } finally {
                          if (mounted) setState(() => _isSubmitting = false);
                        }
                      },
                    ),
                  ),
                ),
                const Gap(30),
              ],
            ),
          ),

          // HEADER FIXED
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: buildHeader(context, headerHeight),
          ),
        ],
      ),
    );
  }

  Widget buildInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nama Lengkap',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff070623),
            ),
          ),
          const Gap(12),
          Input(
            icon: 'assets/ic_profile.png',
            hint: 'Masukkan nama lengkap',
            editingController: edtName,
          ),
          const Gap(16),
          const Text(
            'Nomor Handphone',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff070623),
            ),
          ),
          const Gap(12),
          Input(
            icon: 'assets/ic_telephone.png',
            hint: 'Masukkan nomor HP',
            editingController: edtPhone,
            keyboardType: TextInputType.phone,
          ),
          const Gap(16),
          const Text(
            'Tanggal Mulai Sewa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff070623),
            ),
          ),
          const Gap(12),
          Input(
            icon: 'assets/ic_calendar.png',
            hint: 'Pilih tanggal',
            editingController: edtStartDate,
            enable: false,
            readOnly: true,
            onTapBox: () => pickDate(edtStartDate),
          ),
          const Gap(16),
          const Text(
            'Tanggal Akhir Sewa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff070623),
            ),
          ),
          const Gap(12),
          Input(
            icon: 'assets/ic_calendar.png',
            hint: 'Pilih tanggal',
            editingController: edtEndDate,
            enable: false,
            readOnly: true,
            onTapBox: () => pickDate(edtEndDate),
          ),
        ],
      ),
    );
  }

  Widget buildLocationPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================================
          // 🔵 LOKASI PENGAMBILAN (GOJEK STYLE)
          // =====================================================
          const Text(
            "Lokasi Pengambilan",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff1E1E1E),
            ),
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () => openMapPicker(context, 'pickup'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xffEFF7EE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.green,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedPickup ?? "Pilih lokasi di peta",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: selectedPickup == null
                            ? Colors.grey
                            : const Color(0xff1E1E1E),
                      ),
                    ),
                  ),
                  const Icon(Icons.map_outlined, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // =====================================================
          // 🟣 LOKASI PENGEMBALIAN (GOJEK STYLE)
          // =====================================================
          const Text(
            "Lokasi Pengembalian",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff1E1E1E),
            ),
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () => openMapPicker(context, 'return'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xffF3ECFA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.flag_circle_rounded,
                      color: Colors.deepPurple,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedReturn ?? "Pilih lokasi di peta",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: selectedReturn == null
                            ? Colors.grey
                            : const Color(0xff1E1E1E),
                      ),
                    ),
                  ),
                  const Icon(Icons.map_outlined, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAgency() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Agency',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff070623),
            ),
          ),
        ),
        const Gap(12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: agencyList.length,
            itemBuilder: (context, index) {
              final agency = agencyList[index];
              final isSelected = selectedAgency == agency;
              return GestureDetector(
                onTap: () => setState(() => selectedAgency = agency),
                child: Container(
                  width: 120,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 24 : 8,
                    right: index == agencyList.length - 1 ? 24 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(color: const Color(0xff4A1DFF), width: 3)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/agency.png', width: 38, height: 38),
                      const Gap(10),
                      Text(
                        agency,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff070623),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildInsurance() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Asuransi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff070623),
            ),
          ),
          const Gap(12),

          MultiLineDropdown(
            value: selectedInsurance,
            items: insuranceList,
            hint: "Pilih asuransi",
            icon: Image.asset("assets/ic_insurance.png", width: 28, height: 28),
            onSelected: (value) {
              setState(() => selectedInsurance = value);
            },
          ),
        ],
      ),
    );
  }

  Widget buildHeader(BuildContext context, double headerHeight) {
    return Container(
      height: headerHeight,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 24,
        right: 24,
        bottom: 10,
      ),
      color: Theme.of(context).scaffoldBackgroundColor,
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
              'Booking',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
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

  Widget buildSnippetBike() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      height: 98,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Row(
        children: [
          ExtendedImage.network(
            widget.bike.image,
            width: 90,
            height: 70,
            fit: BoxFit.contain,
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.bike.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff070623),
                  ),
                ),
                Text(
                  widget.bike.category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff838384),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                '${widget.bike.rating}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff070623),
                ),
              ),
              const Gap(4),
              const Icon(Icons.star, size: 20, color: Color(0xffFFBC1C)),
            ],
          ),
        ],
      ),
    );
  }
}
