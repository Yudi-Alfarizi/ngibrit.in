import 'package:d_session/d_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'firebase_options.dart';
import 'package:flutter/material.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((value) {
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
          if(snapshot.connectionState==ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if(snapshot.data==null) return const SplashScreen();
          return DiscoverPage();
        },
      ),
      routes: {
        '/discover': (context) => const DiscoverPage(), 
        '/signup': (context) => const SignupPage(),
        '/signin': (context) => const SigninPage(),
        '/detail': (context){
          String bikeId = ModalRoute.of(context)!.settings.arguments as String;
          return DetailPage(bikeId: bikeId);
        },
        '/booking': (context) {
          Bike bike = ModalRoute.of(context)!.settings.arguments as Bike;
          return BookingPage(bike: bike);
        },
        '/checkout': (context) {
          Map data = ModalRoute.of(context)!.settings.arguments as Map;
          Bike bike = data['bike'];
          String startDate = data['startDate'];
          String endDate =  data['endDate'];
          return CheckoutPage(
            bike: bike,
            startDate: startDate,
            endDate: endDate);
        },
        '/pin': (context) {
          Bike bike = ModalRoute.of(context)!.settings.arguments as Bike;
          return PINPage(bike: bike);
        },
        '/success-booking': (context) {
          Bike bike = ModalRoute.of(context)!.settings.arguments as Bike;
          return SuccessBookingPage(bike: bike);
        },
        '/chatting': (context) {
          Map data = ModalRoute.of(context)!.settings.arguments as Map;
          String uid = data['uid'];
          String userName= data['userName'];
          return ChattingPage(uid: uid, userName: userName);
        },
      },
    );
  }
}
