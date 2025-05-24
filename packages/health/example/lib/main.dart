import 'package:flutter/material.dart';
import 'package:health_example/screens/feature_screen/study_timer.dart';
import 'package:health_example/services/shared_data.dart';
import 'package:provider/provider.dart';
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

import 'health.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize SharedPreferences and SharedData
  final prefs = await SharedPreferences.getInstance();
  final sharedData = SharedData();
  await sharedData.loadData(); // Load persisted data

  final bool hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
  User? user = FirebaseAuth.instance.currentUser;

  runApp(
    ChangeNotifierProvider(
      create: (context) => sharedData,
      child: StudentPredictionApp(
        hasCompletedOnboarding: hasCompletedOnboarding,
        isUserLoggedIn: user != null,
      ),
    ),
  );
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
      initialRoute: '/splash', // Start with splash screen
      routes: {
        '/splash': (context) => SplashScreen(hasCompletedOnboarding: hasCompletedOnboarding),
        '/onboarding': (context) => OnboardingScreen(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/notifications': (context) => NotificationsScreen(),
        '/settings': (context) => SettingsScreen(),
        '/health': (context) => HealthApp(),
        '/study': (context) => StudyTimerPage(),
        // '/stress': (context) => StressPrediction(),
      },
    );
  }
}