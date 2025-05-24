import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import '../gpa_screen.dart';
import '../stress_screen.dart';

class StudyTimerPage extends StatefulWidget {
  const StudyTimerPage({super.key});

  @override
  _StudyTimerPageState createState() => _StudyTimerPageState();
}

class _StudyTimerPageState extends State<StudyTimerPage> {
  DateTime? _studyStart;
  Map<String, int> _dailyMinutes = {};
  bool _isStudying = false;
  bool _showSummary = false;
  final TextEditingController _hourController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStudyData();
  }

  void _loadStudyData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('study_data');
    if (data != null) {
      setState(() {
        _dailyMinutes = Map<String, int>.from(jsonDecode(data));
      });
    }
  }

  void _saveStudyData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('study_data', jsonEncode(_dailyMinutes));
  }

  void _startStudy() {
    setState(() {
      _studyStart = DateTime.now();
      _isStudying = true;
    });
  }

  void _stopStudy() {
    if (_studyStart != null) {
      final now = DateTime.now();
      final minutes = now.difference(_studyStart!).inMinutes;
      final key = _formatDate(now);

      _dailyMinutes.update(key, (value) => value + minutes,
          ifAbsent: () => minutes);
      _saveStudyData();

      setState(() {
        _studyStart = null;
        _isStudying = false;
      });
    }
  }

  void _manualAddStudy() {
    final manualHours = int.tryParse(_hourController.text);
    if (manualHours != null && manualHours > 0) {
      final minutes = manualHours * 60;
      final key = _formatDate(_selectedDate);

      _dailyMinutes.update(key, (value) => value + minutes,
          ifAbsent: () => minutes);
      _saveStudyData();

      setState(() {
        _hourController.clear();
      });
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  List<Widget> _buildStudySummary() {
    final sortedKeys = _dailyMinutes.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return sortedKeys.take(7).map((date) {
      final hrs = (_dailyMinutes[date]! / 60).toStringAsFixed(1);
      return ListTile(
        title: Text(date, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing:
            Text('$hrs hrs', style: TextStyle(fontWeight: FontWeight.w600)),
      );
    }).toList();
  }

  double _calculateAverageStudyHours() {
    final sortedKeys = _dailyMinutes.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final recentKeys = sortedKeys.take(7).toList();

    if (recentKeys.isEmpty) return 0;

    int totalMinutes = 0;
    for (var key in recentKeys) {
      totalMinutes += _dailyMinutes[key]!;
    }

    return totalMinutes / 60 / recentKeys.length;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final averageStudyHours = _calculateAverageStudyHours();

    return Scaffold(
      backgroundColor: Color(0xFFEEF2F7),
      appBar: AppBar(
        title: Text('📘 Study Tracker'),
        centerTitle: true,
        backgroundColor: Color(0xFF0D47A1),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(
              title: 'Manual Entry',
              icon: Icons.edit_calendar_rounded,
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: Icon(Icons.calendar_today),
                    label: Text('Select Date'),
                    style: _buttonStyle(),
                  ),
                  SizedBox(height: 8),
                  Text('Selected: $formattedDate'),
                  SizedBox(height: 10),
                  TextField(
                    controller: _hourController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enter study hours',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.access_time),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _manualAddStudy,
                    icon: Icon(Icons.add),
                    label: Text('Add Manual Hours'),
                    style: _buttonStyle(primary: Color(0xFF00BFA5)),
                  ),
                ],
              ),
            ),
            _buildCard(
              title: 'Study Session',
              icon: Icons.timer_outlined,
              child: Column(
                children: [
                  Text(
                    _isStudying
                        ? '🟢 Session is Active'
                        : '🔴 Session not started.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isStudying ? _stopStudy : _startStudy,
                    icon: Icon(_isStudying
                        ? Icons.stop_circle
                        : Icons.play_circle_fill),
                    label: Text(_isStudying ? 'Stop Session' : 'Start Session'),
                    style: _buttonStyle(
                      primary: _isStudying ? Colors.redAccent : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            _buildCard(
              title: 'Study Summary',
              icon: Icons.bar_chart_rounded,
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showSummary = !_showSummary;
                      });
                    },
                    icon: Icon(
                        _showSummary ? Icons.visibility_off : Icons.visibility),
                    label: Text(_showSummary ? 'Hide Summary' : 'Show Summary'),
                    style: _buttonStyle(primary: Color(0xFF1976D2)),
                  ),
                  if (_showSummary) ...[
                    SizedBox(height: 15),
                    Text(
                      'Last 7 Days',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Divider(),
                    SizedBox(
                      height: 200,
                      child: ListView(children: _buildStudySummary()),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '📊 Average: ${averageStudyHours.toStringAsFixed(1)} hrs/day',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StressScreen(
                      averageStudyHours: averageStudyHours,
                      sleepHours: 0,
                      activityMinutes: 0,
                      socialHours: 0,
                    ),
                  ),
                );
              },
              child: Text('Stress Prediction'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GPAScreen(
                      averageStudyHours: averageStudyHours,
                      sleepHours: 0,
                      activityMinutes: 0,
                    ),
                  ),
                );
              },
              child: Text('GPA Prediction'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
      {required String title, required Widget child, required IconData icon}) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      color: Colors.white,
      shadowColor: Colors.blueGrey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 28),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent),
              ),
            ],
          ),
          Divider(thickness: 1.2),
          child,
        ]),
      ),
    );
  }

  ButtonStyle _buttonStyle({Color? primary}) {
    return ElevatedButton.styleFrom(
      backgroundColor: primary ?? Color(0xFF42A5F5),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}
