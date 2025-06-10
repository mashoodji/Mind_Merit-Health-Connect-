import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class StudyTimerPage extends StatefulWidget {
  const StudyTimerPage({super.key});

  @override
  _StudyTimerPageState createState() => _StudyTimerPageState();
}

class _StudyTimerPageState extends State<StudyTimerPage> {
  DateTime? _studyStart;
  Map<String, int> _dailyMinutes = {};
  bool _isStudying = false;
  final TextEditingController _hourController = TextEditingController();
  DateTime _currentMonth = DateTime.now();
  final int _monthlyGoal = 59 * 60; // 59 hours in minutes

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
      final key = _formatDate(DateTime.now());

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

  int _getTodayMinutes() {
    final todayKey = _formatDate(DateTime.now());
    return _dailyMinutes[todayKey] ?? 0;
  }

  int _getWeekMinutes() {
    final now = DateTime.now();
    int total = 0;
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final key = _formatDate(date);
      total += _dailyMinutes[key] ?? 0;
    }
    return total;
  }

  int _getMonthMinutes() {
    final now = DateTime.now();
    int total = 0;
    for (int day = 1; day <= now.day; day++) {
      final date = DateTime(now.year, now.month, day);
      final key = _formatDate(date);
      total += _dailyMinutes[key] ?? 0;
    }
    return total;
  }

  int _getCurrentMonthMinutes() {
    int total = 0;
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final key = _formatDate(date);
      total += _dailyMinutes[key] ?? 0;
    }
    return total;
  }

  int _getCurrentMonthSessions() {
    int count = 0;
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final key = _formatDate(date);
      if (_dailyMinutes.containsKey(key)) count++;
    }
    return count;
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;

    // Find weekday of first day (0=Sunday, 6=Saturday)
    int firstWeekday = firstDay.weekday % 7; // Convert to 0-based

    List<DateTime> days = [];
    // Add empty days for alignment
    for (int i = 0; i < firstWeekday; i++) {
      days.add(DateTime(0));
    }

    // Add actual days of month
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    return days;
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _goToCurrentMonth() {
    setState(() {
      _currentMonth = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayMinutes = _getTodayMinutes();
    final weekMinutes = _getWeekMinutes();
    final monthMinutes = _getMonthMinutes();
    final currentMonthMinutes = _getCurrentMonthMinutes();
    final currentMonthSessions = _getCurrentMonthSessions();
    final progressPercent = (currentMonthMinutes / _monthlyGoal * 100).clamp(0, 100);
    final daysInMonth = _getDaysInMonth();
    final monthName = DateFormat('MMMM yyyy').format(_currentMonth);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Study Tracker'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Calendar Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Calendar Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left),
                          onPressed: _goToPreviousMonth,
                        ),
                        Column(
                          children: [
                            Text(
                              'Calendar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            TextButton(
                              onPressed: _goToCurrentMonth,
                              child: Text(
                                'Go to current month',
                                style: TextStyle(color: Colors.blue.shade800),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right),
                          onPressed: _goToNextMonth,
                        ),
                      ],
                    ),

                    // Month and Stats
                    Text(
                      monthName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Study time',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${(currentMonthMinutes / 60).toStringAsFixed(1)}h',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              'Goal',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${(_monthlyGoal / 60).toStringAsFixed(0)}h',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              'Sessions',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '$currentMonthSessions',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Progress
                    Text(
                      '${progressPercent.toStringAsFixed(0)}% of monthly goal',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progressPercent / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 16),

                    // Weekday headers
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1,
                      ),
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
                        return Center(
                          child: Text(
                            weekdays[index],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),

                    // Calendar days grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1,
                      ),
                      itemCount: daysInMonth.length,
                      itemBuilder: (context, index) {
                        final day = daysInMonth[index];
                        if (day.year == 0) {
                          return Container(); // Empty day for alignment
                        }

                        final key = _formatDate(day);
                        final minutes = _dailyMinutes[key] ?? 0;
                        final hours = (minutes / 60).toStringAsFixed(1);

                        return Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: minutes > 0 ? Colors.blue : Colors.black,
                                ),
                              ),
                              if (minutes > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '$hours h',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Time Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildTimeCard('Today', todayMinutes),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeCard('Week', weekMinutes),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeCard('Month', monthMinutes),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Study Session Controls
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _isStudying ? 'Session Active' : 'Ready to Study',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isStudying ? _stopStudy : _startStudy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isStudying ? Colors.red : Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isStudying ? 'STOP SESSION' : 'START SESSION',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Manual Entry
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Manual Entry',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _hourController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Hours studied',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.timer),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _manualAddStudy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'ADD MANUAL ENTRY',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(String period, int minutes) {
    final hours = (minutes / 60).toStringAsFixed(1);
    final displayText = minutes < 60 ? '${minutes}m' : '${hours}h';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              period,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}