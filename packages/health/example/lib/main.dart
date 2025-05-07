import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:health_example/screens/auth/sign_up.dart';
import 'package:health_example/screens/onboarding_screen.dart';
import 'package:health_example/screens/splash_screen.dart';
import 'package:health_example/screens/home_screen.dart';
import 'package:health_example/screens/profile_screen.dart';
import 'package:health_example/screens/notifications_screen.dart';
import 'package:health_example/screens/settings_screen.dart';
import 'package:health_example/screens/auth/login_screen.dart';
import 'package:health_example/screens/stress_prediction.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final bool hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;

  User? user = FirebaseAuth.instance.currentUser;

  runApp(StudentPredictionApp(
    hasCompletedOnboarding: hasCompletedOnboarding,
    isUserLoggedIn: user != null,
  ));
}

class StudentPredictionApp extends StatelessWidget {
  final bool hasCompletedOnboarding;
  final bool isUserLoggedIn;

  const StudentPredictionApp({
    super.key,
    required this.hasCompletedOnboarding,
    required this.isUserLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Prediction App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(hasCompletedOnboarding: hasCompletedOnboarding),
        '/onboarding': (context) => OnboardingScreen(),
        '/login': (context) => LoginPage(),
        '/signup': (context)=> SignUpPage(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/settings': (context) => SettingsScreen(),
        // '/StressPrediction': (context) => StressPrediction(),
      },
    );
  }
}



