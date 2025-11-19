// checkout_page.dart
import 'dart:math';
import 'package:d_session/d_session.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/models/bike.dart';
import 'package:ngibrit_in/widgets/button_primary.dart';
import 'package:ngibrit_in/controllers/booking_status_controller.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.bike,
    required this.startDate,
    required this.endDate,
  });

  final Bike bike;
  final String startDate;
  final String endDate;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  num balance = 9500000;
  double grandTotal = 0;

  // payment state
  String? selectedPayment; // null = belum pilih
  String? selectedBank;
  String? generatedVA;

  // bank list
  final List<String> bankList = ['BCA', 'BRI', 'Mandiri', 'CIMB Niaga'];

  // toast
  late FToast fToast;

  // booking status controller (GetX)
  final BookingStatusController bookingStatusController =
      Get.find<BookingStatusController>();

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fToast.init(context);
    });
  }

  String generateVANumber16() {
    final rnd = Random();
    final sb = StringBuffer();
    for (int i = 0; i < 16; i++) {
      sb.write(rnd.nextInt(10));
    }
    return sb.toString();
  }

  // ERROR TOAST (merah)
  void showErrorToast(String message) {
    final Widget notifUI = Transform.translate(
      offset: const Offset(0, -50),
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xffFF2055),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              offset: const Offset(0, 16),
              color: const Color(0xffFF2055).withOpacity(0.25),
            ),
          ],
        ),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5,
            color: Color(0xffFFFFFF),
          ),
        ),
      ),
    );

    fToast.removeCustomToast();
    fToast.showToast(
      child: notifUI,
      gravity: ToastGravity.TOP,
      toastDuration: const Duration(milliseconds: 2500),
    );
  }

  // SUCCESS TOAST (hijau + icon)
  void showSuccessToast(String message) {
    final Widget notifUI = Transform.translate(
      offset: const Offset(0, -50),
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xff1AC75A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              offset: const Offset(0, 16),
              color: const Color(0xff1AC75A).withOpacity(0.25),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: Color(0xffFFFFFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    fToast.removeCustomToast();
    fToast.showToast(
      child: notifUI,
      gravity: ToastGravity.TOP,
      toastDuration: const Duration(milliseconds: 2500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight =
        kToolbarHeight + MediaQuery.of(context).padding.top + 32;

    final payments = [
      ['My Wallet', 'assets/wallet.png'],
      ['Transfer', 'assets/cards.png'],
      ['Cash', 'assets/cash.png'],
    ];

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
                buildDetails(),
                const Gap(24),
                _buildPaymentMethod(payments),
                const Gap(24),

                // aksi dinamis per metode
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildActionArea(),
                ),

                const Gap(30),
              ],
            ),
          ),

          // header fixed (konsep seperti booking page)
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

  Widget _buildActionArea() {
    // jika belum memilih metode -> hide semua tombol
    if (selectedPayment == null) return const SizedBox.shrink();

    // TRANSFER -> tampilkan VA & tombol "Saya Sudah Transfer"
    if (selectedPayment == 'Transfer') {
      final va = generatedVA ?? '';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selectedBank == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Pilih bank untuk melihat nomor Virtual Account.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),

          if (selectedBank != null) ...[
            const Text(
              'Virtual Account',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xff070623),
              ),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xff4A1DFF), width: 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      va,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Salin VA',
                    onPressed: () async {
                      if (va.isNotEmpty) {
                        await Clipboard.setData(ClipboardData(text: va));
                        showSuccessToast(
                          'Nomor Virtual Account berhasil disalin.',
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
            ),
            const Gap(12),
            // Tombol "Saya Sudah Transfer"
            ButtonPrimary(
              text: 'Saya Sudah Transfer',
              onTap: () {
                // isi bookingStatusController agar buildBookingStatus dapat menampilkan data
                bookingStatusController.bike = {
                  'id': widget.bike.id,
                  'name': widget.bike.name,
                  'image': widget.bike.image,
                  'category': widget.bike.category,
                };

                // navigasi ke success-booking (membawa bike)
                Navigator.pushNamed(
                  context,
                  '/success-booking',
                  arguments: widget.bike,
                );
              },
            ),
          ],
        ],
      );
    }

    // My Wallet & Cash -> Pesan Sekarang (tombol muncul hanya untuk keduanya)
    if (selectedPayment == 'My Wallet' || selectedPayment == 'Cash') {
      return ButtonPrimary(
        text: 'Pesan Sekarang',
        onTap: () {
          if (selectedPayment == 'My Wallet') {
            if (balance < grandTotal) {
              showErrorToast(
                'Gagal melakukan pembayaran. Dompet anda tidak memiliki saldo yang cukup saat ini.',
              );
              return;
            }
            // My Wallet -> lanjut ke /pin (PIN page akan set bookingStatusController)
            Navigator.pushNamed(context, '/pin', arguments: widget.bike);
            return;
          }

          // Cash: langsung ke PIN (PIN page set bookingStatusController)
          if (selectedPayment == 'Cash') {
            Navigator.pushNamed(context, '/pin', arguments: widget.bike);
            return;
          }
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPaymentMethod(List<List<String>> payments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Metode Pembayaran',
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
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final label = payments[index][0];
              final iconPath = payments[index][1];
              final isSelected = label == selectedPayment;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPayment = label;
                    // reset bank/va when switching away/from transfer
                    if (selectedPayment != 'Transfer') {
                      selectedBank = null;
                      generatedVA = null;
                    } else {
                      selectedBank = null;
                      generatedVA = null;
                    }
                  });
                },
                child: Container(
                  width: 130,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 24 : 8,
                    right: index == payments.length - 1 ? 24 : 8,
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
                      Image.asset(iconPath, width: 36, height: 36),
                      const Gap(10),
                      Text(
                        label,
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
        const Gap(24),

        // Wallet card (tetap tampil)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FutureBuilder(
            future: DSession.getUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const CircularProgressIndicator();
              final Account account = Account.fromJson(
                Map.from(snapshot.data!),
              );
              return Stack(
                children: [
                  Image.asset(
                    'assets/bg_wallet.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Text(
                          '08/25',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Balance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Gap(6),
                        Text(
                          NumberFormat.currency(
                            decimalDigits: 0,
                            locale: 'id_ID',
                            symbol: 'Rp ',
                          ).format(balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Jika Transfer dipilih -> tampilkan dropdown bank + instruksi
        if (selectedPayment == 'Transfer') ...[
          const Gap(16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedBank,
                  hint: const Text('Pilih Bank Transfer'),
                  items: bankList
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedBank = v;
                      generatedVA = generateVANumber16();
                    });
                  },
                ),
              ),
            ),
          ),

          // instruksi transfer (muncul jika bank sudah dipilih)
          if (selectedBank != null) ...[
            const Gap(12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xffF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffD7E1FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instruksi Pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Bank: $selectedBank',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(6),
                    const Text(
                      'Nomor Virtual Account:',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const Gap(6),
                    SelectableText(
                      generatedVA ?? '-',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Gap(10),
                    Text(
                      'Total Pembayaran: ${NumberFormat.currency(locale: "id_ID", symbol: "Rp ", decimalDigits: 0).format(grandTotal)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(8),
                    const Text(
                      'Panduan:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Text('1. Buka aplikasi m-banking Anda.'),
                    const Text('2. Pilih menu Virtual Account.'),
                    const Text('3. Masukkan nomor VA di atas.'),
                    const Text('4. Bayar sesuai total tagihan.'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  // DETAILS & helpers (tidak berubah banyak dari sebelumnya)
  Widget buildDetails() {
    final dur = _calculateDuration(widget.startDate, widget.endDate);
    final pricePerDay = widget.bike.price.toDouble();
    final subTotal = pricePerDay * dur;
    final insurance = subTotal * 0.20;
    final tax = subTotal * 0.11;
    grandTotal = subTotal + insurance + tax;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Column(
        children: [
          buildItemDetails1(
            'Harga',
            NumberFormat.currency(
              decimalDigits: 0,
              locale: 'id_ID',
              symbol: 'Rp ',
            ).format(widget.bike.price),
            '/Hari',
          ),
          const Gap(14),
          buildItemDetails2('Tanggal Mulai', widget.startDate),
          const Gap(14),
          buildItemDetails2('Tanggal Akhir', widget.endDate),
          const Gap(14),
          buildItemDetails1('Durasi', '$dur', ' Hari'),
          const Gap(14),
          buildItemDetails2(
            'Sub Total Harga',
            NumberFormat.currency(
              decimalDigits: 0,
              locale: 'id_ID',
              symbol: 'Rp ',
            ).format(subTotal),
          ),
          const Gap(14),
          buildItemDetails2(
            'Asuransi 20%',
            NumberFormat.currency(
              decimalDigits: 0,
              locale: 'id_ID',
              symbol: 'Rp ',
            ).format(insurance),
          ),
          const Gap(14),
          buildItemDetails2(
            'Tax 11%',
            NumberFormat.currency(
              decimalDigits: 0,
              locale: 'id_ID',
              symbol: 'Rp ',
            ).format(tax),
          ),
          const Gap(14),
          buildItemDetails3(
            'Total Harga',
            NumberFormat.currency(
              decimalDigits: 0,
              locale: 'id_ID',
              symbol: 'Rp ',
            ).format(grandTotal),
          ),
        ],
      ),
    );
  }

  int _calculateDuration(String startText, String endText) {
    try {
      final s = DateFormat('dd MMM yyyy').parseStrict(startText);
      final e = DateFormat('dd MMM yyyy').parseStrict(endText);
      final diff = e.difference(s).inDays;
      return diff >= 1 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  Widget buildItemDetails1(String title, String data, String unit) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Color(0xff838384)),
        ),
        const Spacer(),
        Text(
          data,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        Text(unit, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget buildItemDetails2(String title, String data) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Color(0xff838384)),
        ),
        const Spacer(),
        Text(
          data,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget buildItemDetails3(String title, String data) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Color(0xff838384)),
        ),
        const Spacer(),
        Text(
          data,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xff4A1DFF),
          ),
        ),
      ],
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
                  ),
                ),
                Text(
                  widget.bike.category,
                  style: const TextStyle(
                    fontSize: 14,
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
              'Checkout',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
}
