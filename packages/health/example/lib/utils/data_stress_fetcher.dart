// lib/utils/stress_data_fetcher.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StressDataFetcher {
  static Future<double> getStudyHours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('study_data');
      if (data != null) {
        Map<String, int> dailyMinutes = Map<String, int>.from(jsonDecode(data));
        final sortedKeys = dailyMinutes.keys.toList()..sort((a, b) => b.compareTo(a));
        final recentKeys = sortedKeys.take(7).toList();
        if (recentKeys.isEmpty) return 0;
        int totalMinutes = recentKeys.fold(0, (sum, key) => sum + (dailyMinutes[key] ?? 0));
        return totalMinutes / 60 / recentKeys.length;
      }
    } catch (e) {
      print('Error fetching study data: $e');
    }
    return 0;
  }

  static Future<Map<String, double>> getHealthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sleep = prefs.getDouble('cached_sleep_hours') ?? 0.0;
      final activity = prefs.getDouble('cached_activity_minutes') ?? 0.0;
      return {
        'sleepHours': sleep,
        'activityMinutes': activity,
      };
    } catch (e) {
      print('Error fetching health data: $e');
      return {
        'sleepHours': 0.0,
        'activityMinutes': 0.0,
      };
    }
  }

  static Future<double?> getUserGPA() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.email != null) {
        String email = currentUser.email!;
        if (!email.endsWith(".edu.pk")) return null;

        final snapshot = await FirebaseFirestore.instance
            .collection('student_cgpa')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          if (data.containsKey('cgpa')) {
            return (data['cgpa'] as num).toDouble();
          }
        }
      }
    } catch (e) {
      print('Error fetching GPA: $e');
    }
    return null;
  }

  static Future<Map<String, double>> fetchAllStressInputs() async {
    final study = await getStudyHours();
    final health = await getHealthData();
    final gpa = await getUserGPA();

    return {
      'studyHours': study,
      'sleepHours': health['sleepHours'] ?? 0.0,
      'activityMinutes': health['activityMinutes'] ?? 0.0,
      'gpa': gpa ?? 0.0,
    };
  }
}
