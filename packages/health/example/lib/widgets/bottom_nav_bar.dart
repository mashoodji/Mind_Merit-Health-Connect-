import 'package:flutter/material.dart';
import 'package:health_example/screens/feature_screen/features_page.dart';
import '../screens/feature_screen/stress_screen.dart';
import '../screens/feature_screen/gpa_screen.dart';
import '../screens/home_screen.dart';
import '../screens/navbarscreens/profile_screen.dart';
import '../screens/navbarscreens/notifications_screen.dart';
import '../screens/navbarscreens/settings_screen.dart';
import '../screens/feature_screen/features_page.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar(
      {super.key, required this.currentIndex, required this.onTap});



  void _navigateToScreen(BuildContext context, int index) {
    Widget screen;
    switch (index) {
      case 0:
        screen = HomeScreen();
        break;
      case 1:
        screen = ProfileScreen(
          username: 'Guest User',
          email: 'guest@example.com',
          photoUrl: 'assets/images/profile.png',
        );
        break;
      case 2:
        screen = FeaturesPage();
        break; // Exit function since we don't navigate immediately
      case 3:
        screen = NotificationsScreen();
        break;
      case 4:
        screen = SettingsScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      onTap: (index) => _navigateToScreen(context, index),
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profile",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: "Tools",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: "Alerts",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: "Settings",
        ),
      ],
    );
  }
}
