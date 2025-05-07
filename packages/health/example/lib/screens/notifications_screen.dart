import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/bottom_nav_bar.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _currentIndex = 3;

  final List<Map<String, String>> notifications = [
    {"message": "Your result is available now.", "time": "2024-03-01 14:30"},
    {"message": "Parent-teacher meeting scheduled for Monday.", "time": "2024-03-01 10:15"},
    {"message": "Your profile information has been updated.", "time": "2024-02-28 18:45"},
    {"message": "New assignment uploaded by your teacher.", "time": "2024-02-27 09:20"},
  ];

  String formatTime(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    return DateFormat('MMM d, h:mm a').format(dateTime);
  }

  void _onNavTap(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });

      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/profile');
          break;
        case 2:
        // Handle modal for prediction options in BottomNavBar
          break;
        case 3:
          break; // Stay on the same screen
        case 4:
          Navigator.pushReplacementNamed(context, '/settings');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
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
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 3,
            child: ListTile(
              leading: Icon(Icons.notifications_active, color: Colors.blue),
              title: Text(
                notifications[index]["message"]!,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                formatTime(notifications[index]["time"]!),
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
