import 'package:d_session/d_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:ngibrit_in/models/bike.dart';
import 'package:ngibrit_in/pages/booking_page.dart';
import 'package:ngibrit_in/pages/chatting_page.dart';
import 'package:ngibrit_in/pages/checkout_page.dart';
import 'package:ngibrit_in/pages/detail_page.dart';
import 'package:ngibrit_in/pages/discover_page.dart';
import 'package:ngibrit_in/pages/pin_page.dart';
import 'package:ngibrit_in/pages/signin_page.dart';
import 'package:ngibrit_in/pages/signup_page.dart';
import 'package:ngibrit_in/pages/splash_screen.dart';
import 'package:ngibrit_in/pages/success_booking_page.dart';
import 'package:ngibrit_in/pages/upload_kyc_page.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:ngibrit_in/pages/map_picker_page.dart';
import 'package:ngibrit_in/pages/notification_page.dart';
import 'package:ngibrit_in/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // [PERBAIKAN CRITICAL P0]: Menghapus 'await' agar startup tidak tertahan oleh inisialisasi plugin
  NotificationService.init().catchError((_) {});

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xffEFEFF0),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: FutureBuilder(
        future: DSession.getUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data == null) return const SplashScreen();
          return const DiscoverPage();
        },
      ),
      routes: {
        '/discover': (context) => const DiscoverPage(),
        '/signup': (context) => const SignupPage(),
        '/signin': (context) => const SigninPage(),
        '/notifications': (context) => const NotificationPage(),
        '/detail': (context) {
          String bikeId = ModalRoute.of(context)!.settings.arguments as String;
          return DetailPage(bikeId: bikeId);
        },
        '/booking': (context) {
          Bike bike = ModalRoute.of(context)!.settings.arguments as Bike;
          return BookingPage(bike: bike);
        },
        '/checkout': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return CheckoutPage(
            bike: args['bike'],
            startDate: args['startDate'],
            endDate: args['endDate'],
            deliveryFee: args['deliveryFee'] ?? 0,
            isDelivery: args['isDelivery'] ?? false,
          );
        },
        '/pin': (context) => const PINPage(),
        '/success-booking': (context) {
          Bike bike = ModalRoute.of(context)!.settings.arguments as Bike;
          return SuccessBookingPage(bike: bike);
        },
        '/chatting': (context) {
          Map data = ModalRoute.of(context)!.settings.arguments as Map;
          return ChattingPage(uid: data['uid'], userName: data['userName']);
        },
        '/upload-kyc': (context) => const UploadKycPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/map-picker') {
          final LatLng? initialPos = (settings.arguments is LatLng)
              ? settings.arguments as LatLng
              : null;
          return MaterialPageRoute(
            builder: (ctx) => MapPickerPage(initialPosition: initialPos),
          );
        }
        return null;
      },
    );
  }
}
