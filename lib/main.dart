import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import './screens/dashboard_screen.dart';
import './screens/get_student_details.dart';
import './screens/login_screen.dart';
import './screens/qr_code_screen.dart';
import './screens/qr_generator_screen.dart';
import './screens/splash_screen.dart';
import './screens/verify_email_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ],
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance',
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: const Color.fromRGBO(14, 51, 194, 1.0),
          onPrimary: Colors.white,
          secondary: const Color.fromRGBO(255, 105, 0, 1),
          onSecondary: Colors.white,
          error: Colors.red.shade800,
          onError: Colors.white,
          background: Colors.white,
          onBackground: Color(0xff5D3fD3),
          surface: Color(0xff5D3fD3),
          onSurface: Colors.black,
        ),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          } else if (snapshot.hasData) {
            return const VerifyEmailScreen();
          }
          return const LoginScreen();
        },
      ),
      routes: {
        QRGeneratorScreen.routeName: (context) => const QRGeneratorScreen(),
        DashBoardScreen.routeName: (context) => const DashBoardScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        QRCodeScreen.routeName: (context) => const QRCodeScreen(),
        GetStudentDetails.routeName: (context) => const GetStudentDetails(),
      },
    );
  }
}
