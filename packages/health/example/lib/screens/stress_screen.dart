import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';
import 'feature_screen/study_timer.dart';

class StressScreen extends StatefulWidget {
  final double? averageStudyHours;
  final double sleepHours;
  final double activityMinutes;

  const StressScreen({
    Key? key,
    this.averageStudyHours,
    required this.sleepHours,
    required this.activityMinutes,
  }) : super(key: key);

  @override
  _StressScreenState createState() => _StressScreenState();
}

class _StressScreenState extends State<StressScreen> {
  TextEditingController studyController = TextEditingController();
  TextEditingController extracurricularController = TextEditingController();
  TextEditingController sleepController = TextEditingController();
  TextEditingController socialController = TextEditingController();
  TextEditingController physicalController = TextEditingController();
  TextEditingController gpaController = TextEditingController();

  String? stressResult;
  Map<String, double>? featureImportances;

  @override
  void initState() {
    super.initState();  sleepController.text = widget.sleepHours.toStringAsFixed(1);
    physicalController.text = widget.activityMinutes.toStringAsFixed(0);
    // Set the studyController text if averageStudyHours is provided
    if (widget.averageStudyHours != null) {
      studyController.text = widget.averageStudyHours!.toStringAsFixed(1);
    }
  }

  void predictStress() async {
    try {
      final result = await ApiService.predictStress(
        studyHours: double.parse(studyController.text),
        extracurricularHours: double.parse(extracurricularController.text),
        sleepHours: double.parse(sleepController.text),
        socialHours: double.parse(socialController.text),
        physicalActivityHours: double.parse(physicalController.text),
        gpa: double.parse(gpaController.text),
      );

      setState(() {
        stressResult = result["stress_level"];
        featureImportances = result["feature_importance"];
      });
    } catch (e) {
      setState(() {
        stressResult = "Error: ${e.toString()}";
        featureImportances = null;
      });
    }
  }

  void clearData() {
    studyController.clear();
    extracurricularController.clear();
    sleepController.clear();
    socialController.clear();
    physicalController.clear();
    gpaController.clear();
    setState(() {
      stressResult = null;
      featureImportances = null;
    });
  }

  Widget buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryColor2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget buildBarChart(Map<String, double> data) {
    final bars = data.entries
        .map((entry) => BarChartRodData(
      toY: entry.value,
      color: AppColors.primaryColor2,
      width: 20,
      borderRadius: BorderRadius.circular(4),
    ))
        .toList();

    final labels = data.keys.toList();

    return Container(
      height: 250,
      padding: EdgeInsets.symmetric(vertical: 16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: List.generate(bars.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [bars[index]],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,  // Space for titles
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        labels[idx],  // Fetch corresponding label
                        style: TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return Container(); // Return empty container if out of range
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor2,
      appBar: AppBar(
        title: Text("Stress Prediction"),
        backgroundColor: AppColors.primaryColor2,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor2,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
                ),
                child: Column(
                  children: [
                    Icon(Icons.health_and_safety, color: Colors.white, size: 40),
                    SizedBox(height: 10),
                    Text("Track Your Stress Levels", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Inputs
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      buildTextField("Study Hours", studyController, Icons.book),
                      SizedBox(height: 12),
                      buildTextField("Extracurricular Hours", extracurricularController, Icons.sports),
                      SizedBox(height: 12),
                      buildTextField("Sleep Hours", sleepController, Icons.nightlight_round),
                      SizedBox(height: 12),
                      buildTextField("Social Hours", socialController, Icons.people),
                      SizedBox(height: 12),
                      buildTextField("Physical Activity Hours", physicalController, Icons.fitness_center),
                      SizedBox(height: 12),
                      buildTextField("GPA", gpaController, Icons.grade),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: predictStress,
                    icon: Icon(Icons.analytics),
                    label: Text("Predict"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor2,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudyTimerPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor2,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Check_Study_Hour'),
                  ),
                  OutlinedButton.icon(
                    onPressed: clearData,
                    icon: Icon(Icons.clear),
                    label: Text("Clear"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorColor2,
                      side: BorderSide(color: AppColors.errorColor2),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Result
              if (stressResult != null)
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)],
                  ),
                  child: Column(
                    children: [
                      Text("Predicted Stress Level", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textColor2)),
                      SizedBox(height: 8),
                      Text(stressResult!, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryColor2)),
                      if (featureImportances != null) ...[
                        SizedBox(height: 20),
                        Text("Feature Impact on Stress", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        buildBarChart(featureImportances!),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}