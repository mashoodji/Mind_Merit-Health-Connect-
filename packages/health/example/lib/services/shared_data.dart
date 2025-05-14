import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedData extends ChangeNotifier {
  double _sleepHours = 0;
  double _activityMinutes = 0;
  double _studyHours = 0;

  double get sleepHours => _sleepHours;
  double get activityMinutes => _activityMinutes;
  double get studyHours => _studyHours;

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _sleepHours = prefs.getDouble('sleepHours') ?? 0;
    _activityMinutes = prefs.getDouble('activityMinutes') ?? 0;
    _studyHours = prefs.getDouble('studyHours') ?? 0;
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sleepHours', _sleepHours);
    await prefs.setDouble('activityMinutes', _activityMinutes);
    await prefs.setDouble('studyHours', _studyHours);
  }

  void updateSleep(double value) {
    _sleepHours = value;
    _saveData();
    notifyListeners();
  }

  void updateActivity(double value) {
    _activityMinutes = value;
    _saveData();
    notifyListeners();
  }

  void updateStudy(double value) {
    _studyHours = value;
    _saveData();
    notifyListeners();
  }
}