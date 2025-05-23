import 'package:flutter/material.dart';
import 'package:health_example/screens/home_screen.dart';
import 'package:health_example/screens/stress_screen.dart';

import '../screens/gpa_screen.dart';

class DrawerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.person, size: 50, color: Colors.white),
                SizedBox(height: 10),
                Text("Student Name", style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text("Home"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.health_and_safety, color: Colors.white),
            title: Text("Stress Prediction", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StressScreen(
                    averageStudyHours: null,
                    sleepHours: 0,
                    activityMinutes: 0,
                    socialHours: 0,  // Add default value
                  ),
                ),
              );
            },
          ),


          ListTile(
            leading: Icon(Icons.school, color: Colors.white),
            title: Text("GPA Prediction", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GPAScreen(
                    averageStudyHours: null,
                    sleepHours: 0, // Default value
                    activityMinutes: 0, // Default value
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text("Logout"),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
