import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.100.54:5000";

  static Future<Map<String, dynamic>> predictStress({
    required double studyHours,
    required double sleepHours,
    required double extracurricularHours,
    required double socialHours,
    required double physicalActivityHours,
    required double gpa,
  }) async {
    try {
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
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "stress_level": data["stress_level"]?.toString() ?? "Unknown",
          "feature_importance": _convertFeatureImportance(data["feature_importance"]),
        };
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to predict stress: ${e.toString()}");
    }
  }

  static Future<Map<String, dynamic>> predictGPA({
    required double studyHours,
    required double sleepHours,
    required double extracurricularHours,
    required double socialHours,
    required double physicalActivityHours,
  }) async {
    try {
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
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "predicted_cgpa": _parseDouble(data["predicted_cgpa"]),
          "feature_importance": _convertFeatureImportance(data["feature_importance"]),
        };
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to predict GPA: ${e.toString()}");
    }
  }

  static Map<String, double> _convertFeatureImportance(dynamic importanceData) {
    try {
      if (importanceData == null) return {};
      if (importanceData is Map) {
        return Map<String, double>.from(importanceData.map((k, v) =>
            MapEntry(k.toString(), _parseDouble(v))));
            }
            return {};
        } catch (e) {
          return {};
        }
      }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}