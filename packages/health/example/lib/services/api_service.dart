import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.84.76.86:5000";

  // Modified method to return both stress level and feature importance
  static Future<Map<String, dynamic>> predictStress({
    required double studyHours,
    required double sleepHours,
    required double extracurricularHours,
    required double socialHours,
    required double physicalActivityHours,
    required double gpa,
  }) async {
    final url = Uri.parse('$baseUrl/predict-stress');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "Study_Hours_Per_Day": studyHours,
        "Sleep_Hours_Per_Day": sleepHours,
        "Extracurricular_Hours_Per_Day": extracurricularHours,
        "Social_Hours_Per_Day": socialHours,
        "Physical_Activity_Hours_Per_Day": physicalActivityHours,
        "GPA": gpa,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        "stress_level": data["stress_level"] ?? "Unknown",
        "feature_importance": Map<String, double>.from(data["feature_importance"] ?? {}),
      };
    } else {
      throw Exception("Failed to predict stress. Try again.");
    }
  }

  static Future<double> predictGPA({
    required double studyHours,
    required double sleepHours,
    required double extracurricularHours,
    required double socialHours,
    required double physicalActivityHours,
  }) async {
    final url = Uri.parse('$baseUrl/predict-cgpa');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "Study_Hours_Per_Day": studyHours,
        "Sleep_Hours_Per_Day": sleepHours,
        "Extracurricular_Hours_Per_Day": extracurricularHours,
        "Social_Hours_Per_Day": socialHours,
        "Physical_Activity_Hours_Per_Day": physicalActivityHours,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return double.parse(data["predicted_cgpa"].toString());
    } else {
      throw Exception("Failed to predict GPA. Try again.");
    }
  }
}
