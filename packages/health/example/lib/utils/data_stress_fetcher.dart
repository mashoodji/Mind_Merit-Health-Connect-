// Create this file at: lib/utils/data_stress_fetcher.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class StressDataFetcher {
  // Method to fetch study hours from Study Timer data
  static Future<double> getStudyHours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('study_data');
      if (data != null) {
        Map<String, int> dailyMinutes = Map<String, int>.from(jsonDecode(data));

        // Get last 7 days average
        final sortedKeys = dailyMinutes.keys.toList()..sort((a, b) => b.compareTo(a));
        final recentKeys = sortedKeys.take(7).toList();

        if (recentKeys.isEmpty) return 0;

        int totalMinutes = 0;
        for (var key in recentKeys) {
          totalMinutes += dailyMinutes[key]!;
        }

        return totalMinutes / 60 / recentKeys.length; // Convert to hours per day
      }
    } catch (e) {
      print('Error fetching study data: $e');
    }
    return 0;
  }

  // Method to fetch health data
  static Future<Map<String, double>> getHealthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to get cached health data
      final sleepData = prefs.getDouble('cached_sleep_hours') ?? 0.0;
      final activityData = prefs.getDouble('cached_activity_minutes') ?? 0.0;

      return {
        'sleepHours': sleepData,
        'activityMinutes': activityData,
      };
    } catch (e) {
      print('Error fetching health data: $e');
      return {
        'sleepHours': 0.0,
        'activityMinutes': 0.0,
      };
    }
  }

  // Method to fetch GPA from Firestore
  static Future<Map<String, dynamic>> getGpaData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && currentUser.email != null) {
        String userEmail = currentUser.email!;
        if (userEmail.endsWith(".edu.pk")) {
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection('student_cgpa')
              .where('email', isEqualTo: userEmail)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            var data = querySnapshot.docs.first.data() as Map<String, dynamic>?;
            if (data != null && data.containsKey('cgpa')) {
              return {
                'gpa': (data['cgpa'] as num).toDouble(),
                'message': 'Fetched GPA successfully'
              };
            } else {
              return {
                'gpa': null,
                'message': 'CGPA field not found in database'
              };
            }
          } else {
            return {
              'gpa': null,
              'message': 'No CGPA record found for your email'
            };
          }
        } else {
          return {
            'gpa': null,
            'message': 'Not a university email. Cannot fetch GPA.'
          };
        }
      } else {
        return {
          'gpa': null,
          'message': 'User not logged in. Cannot fetch GPA.'
        };
      }
    } catch (e) {
      print('Error fetching GPA: $e');
      return {
        'gpa': null,
        'message': 'Error fetching GPA: ${e.toString()}'
      };
    }
  }

  // Method to cache health data (call this from your health screen)
  static Future<void> cacheHealthData(double sleepHours, double activityMinutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('cached_sleep_hours', sleepHours);
      await prefs.setDouble('cached_activity_minutes', activityMinutes);
      await prefs.setInt('health_data_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching health data: $e');
    }
  }

  // Method to fetch all data at once for stress prediction
  static Future<Map<String, dynamic>> fetchAllData() async {
    final studyHours = await getStudyHours();
    final healthData = await getHealthData();
    final gpaData = await getGpaData();

    return {
      'studyHours': studyHours,
      'sleepHours': healthData['sleepHours'] ?? 0.0,
      'activityMinutes': healthData['activityMinutes'] ?? 0.0,
      'gpa': gpaData['gpa'],
      'gpaMessage': gpaData['message'],
    };
  }

  // Method to check if health data is fresh (less than 24 hours old)
  static Future<bool> isHealthDataFresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('health_data_timestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const oneDay = 24 * 60 * 60 * 1000; // 24 hours in milliseconds

      return (now - timestamp) < oneDay;
    } catch (e) {
      return false;
    }
  }
}