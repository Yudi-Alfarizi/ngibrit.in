import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:ngibrit_in/models/bike.dart';
import 'package:ngibrit_in/widgets/button_primary.dart';
import 'package:ngibrit_in/widgets/input.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key, required this.bike});
  final Bike bike;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final edtName = TextEditingController();
  final edtStartDate = TextEditingController();
  final edtEndDate = TextEditingController();

  pickDate(TextEditingController editingController) {
    showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
      initialDate: DateTime.now(),
    ).then((pickDate) {
      if (pickDate == null) return;
      editingController.text = DateFormat('dd MMM yyy').format(pickDate);
    });
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
          buildInput(),
          const Gap(24),
          buildAgency(),
          const Gap(24),
          buildInsurance(),
          const Gap(24),
          Padding(
            // TODO : Bikin Validasi Buat Pesanan
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ButtonPrimary(text: 'Buat Pesanan', onTap: (){
              Navigator.pushNamed(context, '/checkout', arguments: {
                'bike' : widget.bike,
                'startDate': edtStartDate.text,
                'endDate' : edtEndDate.text
              });
            }),
          ),
          const Gap(30),
        ],
      ),
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
          SizedBox(
            height: 52,
            child: DropdownButtonFormField(
              initialValue: 'Pilih asuransi',
              icon: Image.asset('assets/ic_arrow_down.png',width: 20, height: 20,),
              items:
                  [
                    'Pilih asuransi',
                    'Allianz',
                    'Astra Life',
                    'Prudential',
                  ].map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff070623),
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {},
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                contentPadding: EdgeInsets.only(right: 16),
                prefixIcon: UnconstrainedBox(
                  alignment: Alignment(0.2,0),
                  child: Image.asset(
                    'assets/ic_insurance.png',
                    width: 24,
                    height: 24,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: const BorderSide(
                    color: Color(0xff4A1DFF),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAgency() {
    final listAgency = ['Revolte', 'KBP City', 'Sumedap'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Text(
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
            itemCount: listAgency.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: EdgeInsets.only(
                  left: index == 0 ? 24 : 8,
                  right: index == listAgency.length - 1 ? 24 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: index == 1
                      ? Border.all(color: const Color(0xff4A1DFF), width: 3)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/agency.png', width: 38, height: 38),
                    Gap(10),
                    Text(
                      listAgency[index],
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
      ],
    );
  }

  // FIXME: Ambil Data untuk order dari sini
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
            onTapBox: () => pickDate(edtStartDate),
          ),
          const Gap(16),
          const Text(
            'Tanggal Akhir',
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
            onTapBox: () => pickDate(edtEndDate),
          ),
          const Gap(16),
        ],
      ),
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
              'Booking',
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
