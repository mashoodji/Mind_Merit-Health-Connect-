import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../utils/colors1.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Study Tracker', style: TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.bold,
        )),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textLight),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hero Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: AppColors.textLight, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Study Tracker",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Track your study sessions and progress",
                          style: TextStyle(
                            color: AppColors.textLight.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Time Summary Cards
            Row(
              children: [
                Expanded(child: _buildTimeCard("Today", todayMinutes)),
                SizedBox(width: 12),
                Expanded(child: _buildTimeCard("This Week", weekMinutes)),
                SizedBox(width: 12),
                Expanded(child: _buildTimeCard("This Month", monthMinutes)),
              ],
            ),
            SizedBox(height: 24),

            // Calendar Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: AppColors.shadow,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Calendar Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left, color: AppColors.primary),
                          onPressed: _goToPreviousMonth,
                        ),
                        Text(
                          monthName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right, color: AppColors.primary),
                          onPressed: _goToNextMonth,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: _goToCurrentMonth,
                      child: Text(
                        'Current Month',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard("Study Time", "${(currentMonthMinutes / 60).toStringAsFixed(1)}h"),
                        _buildStatCard("Goal", "${(_monthlyGoal / 60).toStringAsFixed(0)}h"),
                        _buildStatCard("Sessions", "$currentMonthSessions"),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Progress
                    LinearProgressIndicator(
                      value: progressPercent / 100,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 8,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${progressPercent.toStringAsFixed(0)}% of monthly goal',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Weekday headers
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1,
                      ),
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                        return Center(
                          child: Text(
                            weekdays[index],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),

                    // Calendar days grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1,
                      ),
                      itemCount: daysInMonth.length,
                      itemBuilder: (context, index) {
                        final day = daysInMonth[index];
                        if (day.year == 0) return Container();

                        final key = _formatDate(day);
                        final minutes = _dailyMinutes[key] ?? 0;
                        final hours = (minutes / 60).toStringAsFixed(1);

                        return Container(
                          margin: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: minutes > 0 ? AppColors.primary.withOpacity(0.1) : null,
                            border: Border.all(color: AppColors.divider),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: minutes > 0 ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              if (minutes > 0) ...[
                                SizedBox(height: 4),
                                Text(
                                  '$hours h',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
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
            SizedBox(height: 24),

            // Study Session Controls
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: AppColors.shadow,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _isStudying ? 'Session Active' : 'Ready to Study',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isStudying ? _stopStudy : _startStudy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isStudying ? AppColors.error : AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isStudying ? 'STOP SESSION' : 'START SESSION',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Manual Entry
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: AppColors.shadow,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Manual Entry',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _hourController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Hours studied',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        prefixIcon: Icon(Icons.timer, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _manualAddStudy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'ADD MANUAL ENTRY',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(String title, int minutes) {
    final hours = (minutes / 60).toStringAsFixed(1);
    final displayText = minutes < 60 ? '${minutes}m' : '${hours}h';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: AppColors.shadow,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              displayText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}