import 'package:d_session/d_session.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:ngibrit_in/models/account.dart';
import 'package:ngibrit_in/models/bike.dart';
import 'package:ngibrit_in/widgets/button_primary.dart';
import 'package:ngibrit_in/controllers/booking_status_controller.dart';
import 'package:ngibrit_in/controllers/order_controller.dart';
import 'package:ngibrit_in/common/info.dart';
import 'package:ngibrit_in/pages/midtrans_webview_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.bike,
    required this.startDate,
    required this.endDate,
    this.deliveryFee = 0,
    this.isDelivery = false,
  });

  final Bike bike;
  final String startDate;
  final String endDate;
  final num deliveryFee;
  final bool isDelivery;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  num balance = 9500000;
  num grandTotal = 0;
  num priceSubTotal = 0;
  num priceInsurance = 0;
  num priceTax = 0;

  final num securityDeposit = 150000;
  int durationDays = 0;

  String? selectedPayment;
  String? selectedBank;
  String? generatedVA;

  final List<String> bankList = ['BCA', 'BRI', 'Mandiri', 'CIMB Niaga'];
  late FToast fToast;

  final OrderController orderController = Get.put(OrderController());
  final BookingStatusController bookingStatusController = Get.put(
    BookingStatusController(),
  );

  // [PERBAIKAN ONGKIR] Variabel yang akan menyimpan data fix dari Routing
  bool _isDelivery = false;
  num _deliveryFee = 0;

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        fToast.init(context);
      } catch (e) {
        print("Error init FToast: $e");
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // [PERBAIKAN ONGKIR] Memaksa membaca args dari route jika constructor bermasalah
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _isDelivery = args['isDelivery'] ?? widget.isDelivery;
      _deliveryFee = args['deliveryFee'] ?? widget.deliveryFee;
    } else {
      _isDelivery = widget.isDelivery;
      _deliveryFee = widget.deliveryFee;
    }
    _calculatePriceDetails();
  }

  void _calculatePriceDetails() {
    try {
      final s = DateFormat('dd MMM yyyy').parseStrict(widget.startDate);
      final e = DateFormat('dd MMM yyyy').parseStrict(widget.endDate);
      final diff = e.difference(s).inDays;
      durationDays = diff >= 1 ? diff : 1;
    } catch (_) {
      durationDays = 1;
    }

    final pricePerDay = widget.bike.price.toDouble();
    priceSubTotal = pricePerDay * durationDays;
    priceInsurance = priceSubTotal * 0.2;
    priceTax = priceSubTotal * 0.2;

    // [PERBAIKAN] Menggunakan _deliveryFee yang sudah divalidasi
    grandTotal =
        priceSubTotal +
        priceInsurance +
        priceTax +
        _deliveryFee +
        securityDeposit;
  }

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

  @override
  Widget build(BuildContext context) {
    final headerHeight =
        kToolbarHeight + MediaQuery.of(context).padding.top + 32;
    final payments = [
      ['My Wallet', 'assets/wallet.png'],
      ['Lainnya', 'assets/cards.png'],
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildActionArea(),
                ),
                const Gap(30),
              ],
            ),
          ),
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
    if (selectedPayment == null) return const SizedBox.shrink();
    final argsFromBooking =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    if (selectedPayment == 'Lainnya') {
      return ButtonPrimary(
        text: 'Bayar Sekarang',
        onTap: () async {
          Info.showLoading(context, message: "Memproses Pembayaran...");
          try {
            final result = await orderController.createOrder(
              bike: widget.bike,
              startDate: widget.startDate,
              endDate: widget.endDate,
              duration: durationDays,
              totalPrice: grandTotal,
              paymentMethod: 'Lainnya',
              userPhone: argsFromBooking['phone'] ?? '-',
              renterName: argsFromBooking['name'] ?? 'Guest',
              pickupLocation: argsFromBooking['pickup'] ?? '-',
              returnLocation: argsFromBooking['return'] ?? '-',
              insuranceName: argsFromBooking['insurance'] ?? '-',
              insurancePrice: priceInsurance,
              tax: priceTax,
              subTotal: priceSubTotal,
              deliveryFee: _deliveryFee,
              securityDeposit: securityDeposit,
              isDelivery: _isDelivery,
            );
            Info.hideLoading();

            if (result['success'] == true) {
              if (result['isMidtrans'] == true) {
                final redirectUrl = result['redirectUrl'];
                final orderId = result['orderId'];
                if (redirectUrl != null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MidtransWebViewPage(url: redirectUrl),
                    ),
                  );
                  Info.showLoading(
                    context,
                    message: "Verifikasi Pembayaran...",
                  );
                  await orderController.updateOrderStatus(orderId, 'Dikirim');
                  Info.hideLoading();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/success-booking',
                    (route) => false,
                    arguments: widget.bike,
                  );
                }
              }
            } else {
              showErrorToast("Gagal: ${result['message']}");
            }
          } catch (e) {
            Info.hideLoading();
            showErrorToast("Terjadi kesalahan: $e");
          }
        },
      );
    }

    if (selectedPayment == 'My Wallet' || selectedPayment == 'Cash') {
      return ButtonPrimary(
        text: 'Pesan Sekarang',
        onTap: () {
          if (selectedPayment == 'My Wallet' && balance < grandTotal) {
            showErrorToast('Gagal melakukan pembayaran. Saldo tidak cukup.');
            return;
          }
          final Map<String, dynamic> fullBookingData = {
            'bike': widget.bike,
            'startDate': widget.startDate,
            'endDate': widget.endDate,
            'duration': durationDays,
            'totalPrice': grandTotal,
            'paymentMethod': selectedPayment,
            'name': argsFromBooking['name'],
            'phone': argsFromBooking['phone'],
            'pickup': argsFromBooking['pickup'],
            'return': argsFromBooking['return'],
            'insurance': argsFromBooking['insurance'],
            'deliveryFee': _deliveryFee,
            'securityDeposit': securityDeposit,
            'isDelivery': _isDelivery,
          };
          Navigator.pushNamed(context, '/pin', arguments: fullBookingData);
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
              final label = payments[index][0],
                  iconPath = payments[index][1],
                  isSelected = label == selectedPayment;
              return GestureDetector(
                onTap: () => setState(() {
                  selectedPayment = label;
                  selectedBank = null;
                  generatedVA = null;
                }),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FutureBuilder(
            future: DSession.getUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              if (!snapshot.hasData) return const SizedBox();
              final account = Account.fromJson(
                Map<String, dynamic>.from(snapshot.data!),
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
      ],
    );
  }

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
          buildItemDetails1('Harga', _fmt(widget.bike.price), '/Hari'),
          const Gap(14),
          buildItemDetails2('Tanggal Mulai', widget.startDate),
          const Gap(14),
          buildItemDetails2('Tanggal Akhir', widget.endDate),
          const Gap(14),
          buildItemDetails1('Durasi', '$durationDays', ' Hari'),
          const Gap(14),
          buildItemDetails2('Sub Total Harga', _fmt(priceSubTotal)),
          const Gap(14),
          buildItemDetails2('Asuransi 2%', _fmt(priceInsurance)),
          const Gap(14),
          buildItemDetails2('Tax 2%', _fmt(priceTax)),

          if (_isDelivery) ...[
            const Gap(14),
            buildItemDetails2('Biaya Antar', _fmt(_deliveryFee)),
          ],

          const Gap(14),
          buildItemDetails2('Deposit Jaminan', _fmt(securityDeposit)),
          const Gap(4),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              "*Deposit akan dikembalikan setelah sewa selesai",
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const Divider(height: 30, thickness: 1),
          buildItemDetails3('Total Pembayaran', _fmt(grandTotal)),
        ],
      ),
    );
  }

  String _fmt(num price) => NumberFormat.currency(
    decimalDigits: 0,
    locale: 'id_ID',
    symbol: 'Rp ',
  ).format(price);

  Widget buildItemDetails1(String title, String data, String unit) => Row(
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
  Widget buildItemDetails2(String title, String data) => Row(
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
  Widget buildItemDetails3(String title, String data) => Row(
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

  Widget buildSnippetBike() => Container(
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                widget.bike.category,
                style: const TextStyle(fontSize: 14, color: Color(0xff838384)),
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

  Widget buildHeader(BuildContext context, double headerHeight) => Container(
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
