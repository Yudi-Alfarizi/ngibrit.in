import 'package:d_session/d_session.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/models/bike.dart';
import 'package:ngibrit_in/widgets/button_primary.dart';

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
  // num balance = 0;
  double grandTotal = 9300000;

  FToast fToast = FToast();
  
  checkoutNow() {
    if (balance < grandTotal) {
      Widget notifUI = Transform.translate(
        offset: const Offset(0, -50),
        child: Container(
          height: 96,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          decoration: BoxDecoration(
            color: const Color(0xffFF2055),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                offset: const Offset(0, 16),
                color: const Color(0xffFF2055).withValues(alpha: 0.25),
              ),
            ],
          ),
          child: const Text(
            'Gagal melakukan pembayaran. Dompet anda tidak memiliki saldo yang cukup saat ini.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: Color(0xffFFFFFF),
            ),
          ),
        ),
      );
      fToast.showToast(
        child: notifUI,
        gravity: ToastGravity.TOP,
        toastDuration: const Duration(milliseconds: 2500),
      );
      return;
    }

    Navigator.pushNamed(context, '/pin', arguments: widget.bike);
  }

  @override
  void initState() {
    fToast.init(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          Gap(20 + MediaQuery.of(context).padding.top),
          buildHeader(context),
          const Gap(24),
          buildSnippetBike(),
          const Gap(24),
          buildDetails(),
          const Gap(24),
          buildPaymentMethod(),
          const Gap(24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ButtonPrimary(
              text: 'Pesan Sekarang',
              onTap: () => checkoutNow(),
            ),
          ),
          const Gap(30),
        ],
      ),
    );
  }

  Widget buildPaymentMethod() {
    final payments = [
      ['My Wallet', 'assets/wallet.png'],
      ['Credit Card', 'assets/cards.png'],
      ['Cash', 'assets/cash.png'],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Text(
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
              return Container(
                width: 130,
                margin: EdgeInsets.only(
                  left: index == 0 ? 24 : 8,
                  right: index == payments.length - 1 ? 24 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: index == 0
                      ? Border.all(color: const Color(0xff4A1DFF), width: 3)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(payments[index][1]),
                    Gap(10),
                    Text(
                      payments[index][0],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff070623),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const Gap(24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FutureBuilder(
            future: DSession.getUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              Account account = Account.fromJson(Map.from(snapshot.data!));
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
                      // TODO : sesuaikan data dgn seccsion
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          account.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          '08/25',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
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
                      // TODO : sesuaikan data dgn seccsion
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Balance',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                        const Gap(6),
                        Text(
                          NumberFormat.currency(
                            decimalDigits: 0,
                            locale: 'id_ID',
                            symbol: 'Rp ',
                          ).format(balance),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          ),
        ),
      ],
    );
  }

  // TODO: Tambahkan Data untuk Detail Order
  Widget buildDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Column(
        children: [
          buildItemDetails1('Harga', 'Rp 300,000', '/Hari'),
          const Gap(14),
          buildItemDetails2('Tanggal Mulai', widget.startDate),
          const Gap(14),
          buildItemDetails2('Tanggal Akhir', widget.endDate),
          const Gap(14),
          buildItemDetails1('Durasi', '15', ' Hari'),
          const Gap(14),
          buildItemDetails2('Sub Total Harga', 'Rp 2,000,000'),
          const Gap(14),
          buildItemDetails2('Asuransi 20%', 'Rp 20,000'),
          const Gap(14),
          buildItemDetails2('Tax 11%', 'Rp 231,000'),
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

  Widget buildItemDetails1(String title, String data, String unit) {
    return Row(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xff838384),
          ),
        ),
        const Spacer(),
        Text(
          data,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xff070623),
          ),
        ),
        Text(
          unit,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xff070623),
          ),
        ),
      ],
    );
  }

  Widget buildItemDetails2(String title, String data) {
    return Row(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xff838384),
          ),
        ),
        const Spacer(),
        Text(
          data,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xff070623),
          ),
        ),
      ],
    );
  }

  Widget buildItemDetails3(String title, String data) {
    return Row(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xff838384),
          ),
        ),
        const Spacer(),
        Text(
          data,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xff4A1DFF),
          ),
        ),
      ],
    );
  }

  Widget buildSnippetBike() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
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
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff070623),
                  ),
                ),
                Text(
                  widget.bike.category,
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff070623),
                ),
              ),
              Gap(4),
              Icon(Icons.star, size: 20, color: Color(0xffFFBC1C)),
            ],
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
              'Checkout',
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
}
