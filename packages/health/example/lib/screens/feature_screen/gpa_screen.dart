import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/api_service.dart';
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

  // Method to fetch study hours from SharedPreferences (Study Timer data)
  Future<double> _getStudyHoursFromTimer() async {
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
      debugPrint('Error fetching study data: $e');
    }
    return 0;
  }

  // Method to fetch health data from HealthDataProvider
  Map<String, double>? _getHealthData() {
    try {
      // Import the health screen file and access the global health data
      // Since we can't directly import, we'll use a different approach
      return null; // We'll handle this differently
    } catch (e) {
      debugPrint('Error fetching health data: $e');
      return null;
    }
  }

  // Updated auto-fill method that fetches from actual sources
  Future<void> _autoFillData() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(width: 16),
              Text('Fetching data...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Fetch study hours from Study Timer
      double studyHours = await _getStudyHoursFromTimer();

      // Fetch health data from DataFetcher
      Map<String, double> healthData = await GPADataFetcher.getHealthData();
      double sleepHours = healthData['sleepHours'] ?? 0.0;
      double activityMinutes = healthData['activityMinutes'] ?? 0.0;

      setState(() {
        studyController.text = studyHours.toStringAsFixed(1);
        sleepController.text = sleepHours.toStringAsFixed(1);
        physicalController.text = activityMinutes.toStringAsFixed(0);
        // Keep existing social hours or set default
        if (socialController.text.isEmpty) {
          socialController.text = '2.0'; // Default social hours
        }
        // Keep existing extracurricular or set default
        if (extracurricularController.text.isEmpty) {
          extracurricularController.text = '1.0'; // Default extracurricular hours
        }
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data filled successfully!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch data: $e'),
          backgroundColor: Colors.red,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            icon: Icon(icon, color: Colors.blueAccent),
            labelText: label,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GPA Prediction"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              buildInputField(
                  "Study Hours", FontAwesomeIcons.book, studyController),
              const SizedBox(height: 10),
              buildInputField("Extracurricular Hours",
                  FontAwesomeIcons.basketballBall, extracurricularController),
              const SizedBox(height: 10),
              buildInputField(
                  "Sleep Hours", FontAwesomeIcons.bed, sleepController),
              const SizedBox(height: 10),
              buildInputField(
                  "Social Hours", FontAwesomeIcons.users, socialController),
              const SizedBox(height: 10),
              buildInputField("Physical Activity Hours", FontAwesomeIcons.running,
                  physicalController),
              const SizedBox(height: 20),

              // Auto-Fill Button (prominent placement)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton.icon(
                  onPressed: _autoFillData,
                  icon: const Icon(Icons.auto_fix_high, color: Colors.white),
                  label: const Text(
                    'Auto-Fill Data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Other action buttons
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: predictGPA,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
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
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                    ),
                    child: const Text('Study Timer', style: TextStyle(fontSize: 16)),
                  ),

                  OutlinedButton(
                    onPressed: clearData,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                    ),
                    child: const Text("Clear", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Result display
              gpaResult == null
                  ? const Text("Enter values to predict GPA",
                  style: TextStyle(fontSize: 16, color: Colors.grey))
                  : Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.lightBlueAccent,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Predicted GPA: $gpaResult",
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}