import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../utils/colors1.dart';
import '../../utils/data_gpa_fetcher.dart';
import 'study_timer.dart';

class GPAScreen extends StatefulWidget {
  final double sleepHours;
  final double activityMinutes;
  final double socialHours;
  final double? averageStudyHours;

  const GPAScreen({
    super.key,
    required this.averageStudyHours,
    required this.sleepHours,
    required this.activityMinutes,
    required this.socialHours,
  });

  @override
  _GPAScreenState createState() => _GPAScreenState();
}

class _GPAScreenState extends State<GPAScreen> {
  TextEditingController studyController = TextEditingController();
  TextEditingController extracurricularController = TextEditingController();
  TextEditingController sleepController = TextEditingController();
  TextEditingController socialController = TextEditingController();
  TextEditingController physicalController = TextEditingController();

  String? gpaResult;

  @override
  void initState() {
    super.initState();
    sleepController.text = widget.sleepHours.toStringAsFixed(1);
    physicalController.text = widget.activityMinutes.toStringAsFixed(0);
    socialController.text = widget.socialHours.toStringAsFixed(1);

    if (widget.averageStudyHours != null) {
      studyController.text = widget.averageStudyHours!.toStringAsFixed(1);
    }
  }

  Future<double> _getStudyHoursFromTimer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('study_data');
      if (data != null) {
        Map<String, int> dailyMinutes = Map<String, int>.from(jsonDecode(data));

        final sortedKeys = dailyMinutes.keys.toList()
          ..sort((a, b) => b.compareTo(a));
        final recentKeys = sortedKeys.take(7).toList();

        if (recentKeys.isEmpty) return 0;

        int totalMinutes = 0;
        for (var key in recentKeys) {
          totalMinutes += dailyMinutes[key]!;
        }

        return totalMinutes / 60 / recentKeys.length;
      }
    } catch (e) {
      debugPrint('Error fetching study data: $e');
    }
    return 0;
  }

  Future<void> _autoFillData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
              ),
              SizedBox(width: 16),
              Text('Fetching data...'),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );

      double studyHours = await _getStudyHoursFromTimer();
      Map<String, double> healthData = await GPADataFetcher.getHealthData();

      double sleepHours = healthData['sleepHours'] ?? 0.0;
      double activityMinutes = healthData['activityMinutes'] ?? 0.0;

      setState(() {
        studyController.text = studyHours.toStringAsFixed(1);
        sleepController.text = sleepHours.toStringAsFixed(1);
        physicalController.text = activityMinutes.toStringAsFixed(0);

        if (socialController.text.isEmpty) {
          socialController.text = '2.0';
        }
        if (extracurricularController.text.isEmpty) {
          extracurricularController.text = '1.0';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data filled successfully!'),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'OK',
            textColor: AppColors.textLight,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch data: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void predictGPA() async {
    try {
      final result = await ApiService.predictGPA(
        studyHours: double.parse(studyController.text),
        extracurricularHours: double.parse(extracurricularController.text),
        sleepHours: double.parse(sleepController.text),
        socialHours: double.parse(socialController.text),
        physicalActivityHours: double.parse(physicalController.text),
      );

      setState(() {
        gpaResult = result.toString();
      });
    } catch (e) {
      setState(() {
        gpaResult = "Error: ${e.toString()}";
      });
    }
  }

  void clearData() {
    studyController.clear();
    extracurricularController.clear();
    sleepController.clear();
    socialController.clear();
    physicalController.clear();
    setState(() {
      gpaResult = null;
    });
  }

  Widget buildInputField(
      String label, IconData icon, TextEditingController controller) {
    return Card(
      elevation: 3,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            icon: Icon(icon, color: AppColors.iconPrimary),
            labelText: label,
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("GPA Prediction"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildInputField("Study Hours", FontAwesomeIcons.book, studyController),
              const SizedBox(height: 10),
              buildInputField("Extracurricular Hours", FontAwesomeIcons.basketballBall,
                  extracurricularController),
              const SizedBox(height: 10),
              buildInputField("Sleep Hours", FontAwesomeIcons.bed, sleepController),
              const SizedBox(height: 10),
              buildInputField("Social Hours", FontAwesomeIcons.users, socialController),
              const SizedBox(height: 10),
              buildInputField("Physical Activity Hours", FontAwesomeIcons.running,
                  physicalController),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton.icon(
                  onPressed: _autoFillData,
                  icon: const Icon(Icons.auto_fix_high, color: AppColors.textLight),
                  label: const Text(
                    'Auto-Fill Data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: AppColors.textLight,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: predictGPA,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: AppColors.textLight,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 30),
                    ),
                    child: const Text("Predict GPA", style: TextStyle(fontSize: 16)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudyTimerPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: AppColors.textLight,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 30),
                    ),
                    child: const Text("Study Timer", style: TextStyle(fontSize: 16)),
                  ),
                  ElevatedButton(
                    onPressed: clearData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.textLight,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 30),
                    ),
                    child: const Text("Clear Data", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              if (gpaResult != null)
                Text(
                  "Predicted GPA: $gpaResult",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentPurple,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
