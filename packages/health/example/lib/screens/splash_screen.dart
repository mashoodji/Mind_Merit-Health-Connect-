import 'dart:async';
import 'package:flutter/material.dart';
// import 'example/lib/screens/onboarding_screen.dart';
// import 'package:stress_detection/screens/auth/login_screen.dart';
// import 'login_screen.dart';






class SplashScreen extends StatefulWidget {
  final bool hasCompletedOnboarding;

  const SplashScreen({super.key, required this.hasCompletedOnboarding});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (!widget.hasCompletedOnboarding) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "Student Prediction App",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}