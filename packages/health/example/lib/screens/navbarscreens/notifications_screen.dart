import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/colors1.dart';
import '../../widgets/bottom_nav_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 3;

  late AnimationController _controller;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  List<Map<String, String>> allNotifications = [
    {
      "message": "Your recent stress levels have spiked. Try a breathing exercise.",
      "time": "2024-06-11 09:20",
      "category": "Stress"
    },
    {
      "message": "Low GPA detected in recent exams. Review key topics.",
      "time": "2024-06-10 14:10",
      "category": "GPA"
    },
    {
      "message": "Your stress level has normalized. Great job staying balanced!",
      "time": "2024-06-09 18:45",
      "category": "Info"
    },
    {
      "message": "You missed yesterday’s journal entry. Consistency helps predictions.",
      "time": "2024-06-08 08:30",
      "category": "GPA"
    },
  ];

  List<Map<String, String>> filteredNotifications = [];

  String formatTime(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp);
    return DateFormat('MMM d, h:mm a').format(dateTime);
  }

  Color getCategoryColor(String category) {
    switch (category) {
      case "Stress":
        return AppColors.accentRed;
      case "GPA":
        return AppColors.accentBlue;
      default:
        return AppColors.accentGreen;
    }
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case "Stress":
        return Icons.self_improvement;
      case "GPA":
        return Icons.school;
      default:
        return Icons.info_outline;
    }
  }

  @override
  void initState() {
    super.initState();

    // Filter out only Stress and GPA notifications
    filteredNotifications = allNotifications
        .where((n) => n["category"] == "Stress" || n["category"] == "GPA")
        .toList();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
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
        case 4:
          Navigator.pushReplacementNamed(context, '/settings');
          break;
      }
    }
  }

  void _showDetailsDialog(Map<String, String> notification) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Notification Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification["message"] ?? ""),
            const SizedBox(height: 10),
            Text(
              "Time: ${formatTime(notification["time"] ?? "")}",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            Text(
              "Category: ${notification["category"]}",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
      body: (_fadeAnimation != null && _slideAnimation != null)
          ? FadeTransition(
        opacity: _fadeAnimation!,
        child: SlideTransition(
          position: _slideAnimation!,
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredNotifications.length,
            itemBuilder: (context, index) {
              final notification = filteredNotifications[index];
              final message = notification["message"] ?? "";
              final time = notification["time"] ?? "";
              final category = notification["category"] ?? "Info";

              return Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  final removedItem = notification;
                  setState(() {
                    filteredNotifications.removeAt(index);
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Notification dismissed"),
                      action: SnackBarAction(
                        label: "UNDO",
                        onPressed: () {
                          setState(() {
                            filteredNotifications.insert(index, removedItem);
                          });
                        },
                      ),
                    ),
                  );
                },
                child: InkWell(
                  onTap: () => _showDetailsDialog(notification),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Material(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      elevation: 4,
                      shadowColor: AppColors.shadow,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: getCategoryColor(category),
                                  radius: 20,
                                  child: Icon(
                                    getCategoryIcon(category),
                                    color: AppColors.textLight,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    message,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: AppColors.iconSecondary),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatTime(time),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: getCategoryColor(category).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: getCategoryColor(category),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      )
          : const Center(child: CircularProgressIndicator()),
      // bottomNavigationBar: BottomNavBar(
      //   currentIndex: _currentIndex,
      //   onTap: _onNavTap,
      // ),
    );
  }
}
