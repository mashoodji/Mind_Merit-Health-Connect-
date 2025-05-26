// Create this file at: lib/utils/data_fetcher.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GPADataFetcher {
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

  // Method to fetch health data (you would implement this based on your health data storage)
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

  // Method to fetch all data at once
  static Future<Map<String, double>> fetchAllData() async {
    final studyHours = await getStudyHours();
    final healthData = await getHealthData();

    return {
      'studyHours': studyHours,
      'sleepHours': healthData['sleepHours'] ?? 0.0,
      'activityMinutes': healthData['activityMinutes'] ?? 0.0,
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