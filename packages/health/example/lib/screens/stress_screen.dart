import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../health.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';
import 'feature_screen/study_timer.dart';

class StressScreen extends StatefulWidget {
  final double? averageStudyHours;
  final double sleepHours;
  final double activityMinutes;
  final double socialHours;

  const StressScreen({
    Key? key,
    this.averageStudyHours,
    required this.sleepHours,
    required this.activityMinutes,
    required this.socialHours,
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
  String? _fetchedGpaMessage;

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

  Future<double?> _fetchUserCGPAFromFirestore() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && currentUser.email != null) {
      String userEmail = currentUser.email!;
      if (userEmail.endsWith(".edu.pk")) {
        try {
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection('student_cgpa')
              .where('email', isEqualTo: userEmail)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            var data = querySnapshot.docs.first.data() as Map<String, dynamic>?;
            if (data != null && data.containsKey('cgpa')) {
              return (data['cgpa'] as num).toDouble();
            } else {
              setState(() {
                _fetchedGpaMessage = 'CGPA field not found in database.';
              });
              return null;
            }
          } else {
            setState(() {
              _fetchedGpaMessage = 'No CGPA record found for your email.';
            });
            return null;
          }
        } catch (e) {
          setState(() {
            _fetchedGpaMessage = 'Error fetching CGPA: ${e.toString()}';
          });
          print('Error fetching CGPA: $e');
          return null;
        }
      } else {
        setState(() {
          _fetchedGpaMessage = 'Not a university email. Cannot fetch GPA.';
        });
        return null;
      }
    } else {
      setState(() {
        _fetchedGpaMessage = 'User not logged in. Cannot fetch GPA.';
      });
      return null;
    }
  }

  void _fillGpaFromFirestore() async {
    double? cgpa = await _fetchUserCGPAFromFirestore();
    if (cgpa != null) {
      setState(() {
        gpaController.text = cgpa.toStringAsFixed(2);
        _fetchedGpaMessage = "Fetched GPA: ${cgpa.toStringAsFixed(2)}";
      });
    }
  }

  void predictStress() async {
    if (gpaController.text.isEmpty) {
      setState(() {
        stressResult = "Error: GPA field cannot be empty.";
        featureImportances = null;
      });
      return;
    }
    if (studyController.text.isEmpty ||
        extracurricularController.text.isEmpty ||
        sleepController.text.isEmpty ||
        socialController.text.isEmpty ||
        physicalController.text.isEmpty) {
      setState(() {
        stressResult = "Error: All fields must be filled.";
        featureImportances = null;
      });
      return;
    }

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
        stressResult = "Error predicting: ${e.toString()}";
        featureImportances = null;
      });
    }
  }

  void clearData() {
    studyController.clear();
    extracurricularController.clear();
    sleepController.text = widget.sleepHours.toStringAsFixed(1);
    physicalController.text = widget.activityMinutes.toStringAsFixed(0);
    if (widget.averageStudyHours != null) {
      studyController.text = widget.averageStudyHours!.toStringAsFixed(1);
    } else {
      studyController.clear();
    }
    socialController.clear();
    gpaController.clear();
    setState(() {
      stressResult = null;
      featureImportances = null;
      _fetchedGpaMessage = null;
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
      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        labels[idx],
                        style: TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                  return Container();
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
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fillGpaFromFirestore,
                        child: Text("Fetch GPA from Database"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor2,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 10,
                runSpacing: 10,
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
                    child: Text('Study Timer'),
                  ),

                  // Replace the Get Health Data button with this:
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        // Fetch data directly without opening Health Screen
                        final healthData = HealthDataProvider.getHealthData();

                        if (healthData != null) {
                          setState(() {
                            sleepController.text = healthData['sleepHours']?.toStringAsFixed(1) ?? sleepController.text;
                            physicalController.text = healthData['activityMinutes']?.toStringAsFixed(0) ?? physicalController.text;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Health data loaded successfully!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Health data not available. Please check health tracking.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error fetching health data: ${e.toString()}'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.download_for_offline),
                    label: Text("Get Health Data"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor2,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
              if (_fetchedGpaMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Text(
                    _fetchedGpaMessage!,
                    style: TextStyle(
                      fontSize: 15,
                      color: _fetchedGpaMessage!.startsWith("Error") ||
                          _fetchedGpaMessage!.startsWith("No CGPA") ||
                          _fetchedGpaMessage!.startsWith("Not a university") ||
                          _fetchedGpaMessage!.startsWith("User not logged in")
                          ? AppColors.errorColor2
                          : AppColors.primaryColor2,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                      Text(
                        stressResult!,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: stressResult!.startsWith("Error") ? AppColors.errorColor2 : AppColors.primaryColor2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (featureImportances != null) ...[
                        SizedBox(height: 20),
                        Text("Feature Impact on Stress", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textColor2)),
                        buildBarChart(featureImportances!),
                      ],
                    ],
                  ),
                ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}