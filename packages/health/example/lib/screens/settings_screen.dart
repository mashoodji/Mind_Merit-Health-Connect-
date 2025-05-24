import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/notifications_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  final int _selectedIndex = 3;

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      Widget nextScreen;
      switch (index) {
        case 0:
          nextScreen = HomeScreen();
          break;
        case 1:
          nextScreen = ProfileScreen();
          break;
        case 2:
          nextScreen = NotificationsScreen();
          break;
        default:
          return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Text("Preferences",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor)),
          Divider(),
          SwitchListTile(
            title: Text("Enable Notifications",
                style: TextStyle(color: AppColors.textColor)),
            value: _notifications,
            onChanged: (value) {
              setState(() {
                _notifications = value;
              });
            },
          ),
          ListTile(
            leading: Icon(Icons.color_lens, color: AppColors.primaryColor),
            title:
                Text("App Theme", style: TextStyle(color: AppColors.textColor)),
            subtitle: Text("Light / Dark / System",
                style: TextStyle(color: AppColors.accentColor)),
            onTap: () {
              // Implement theme selection
            },
          ),
          SizedBox(height: 20),
          Text("Security",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor)),
          Divider(),
          ListTile(
            leading: Icon(Icons.lock, color: AppColors.primaryColor),
            title: Text("Change Password",
                style: TextStyle(color: AppColors.textColor)),
            onTap: () {
              // Implement Change Password functionality
            },
          ),
          ListTile(
            leading: Icon(Icons.security, color: AppColors.primaryColor),
            title: Text("Privacy & Security",
                style: TextStyle(color: AppColors.textColor)),
            onTap: () {
              // Implement Privacy settings
            },
          ),
          SizedBox(height: 20),
          Text("App Info",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor)),
          Divider(),
          ListTile(
            leading: Icon(Icons.description, color: AppColors.primaryColor),
            title: Text("Terms & Conditions",
                style: TextStyle(color: AppColors.textColor)),
            onTap: () {
              // Implement Terms & Conditions
            },
          ),
          ListTile(
            leading: Icon(Icons.policy, color: AppColors.primaryColor),
            title: Text("Privacy Policy",
                style: TextStyle(color: AppColors.textColor)),
            onTap: () {
              // Implement Privacy Policy
            },
          ),
          ListTile(
            leading: Icon(Icons.help, color: AppColors.primaryColor),
            title: Text("Help & Support",
                style: TextStyle(color: AppColors.textColor)),
            onTap: () {
              // Implement Help & Support
            },
          ),
          ListTile(
            leading: Icon(Icons.info, color: AppColors.primaryColor),
            title:
                Text("About App", style: TextStyle(color: AppColors.textColor)),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "Student Prediction App",
                applicationVersion: "1.0.0",
                applicationIcon:
                    Icon(Icons.school, color: AppColors.primaryColor),
                children: [
                  Text("This app helps students track their academic progress.",
                      style: TextStyle(color: AppColors.textColor))
                ],
              );
            },
          ),
          SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorColor,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              icon: Icon(Icons.logout, color: Colors.white),
              label: Text("Logout", style: TextStyle(color: Colors.white)),
              onPressed: () {
                // Implement logout functionality
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
