import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../health.dart';
import '../services/api_service.dart';
import '../utils/colors1.dart';
import '../utils/data_stress_fetcher.dart';
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

  Future<void> _autoFillData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
              ),
              SizedBox(width: 16),
              Text('Fetching data...', style: TextStyle(color: AppColors.textLight)),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );

      Map<String, dynamic> allData = await StressDataFetcher.fetchAllData();

      setState(() {
        studyController.text = (allData['studyHours'] as double).toStringAsFixed(1);
        sleepController.text = (allData['sleepHours'] as double).toStringAsFixed(1);
        physicalController.text = (allData['activityMinutes'] as double).toStringAsFixed(0);

        if (extracurricularController.text.isEmpty) {
          extracurricularController.text = '1.0';
        }
        if (socialController.text.isEmpty) {
          socialController.text = '2.0';
        }

        if (allData['gpa'] != null) {
          gpaController.text = (allData['gpa'] as double).toStringAsFixed(2);
          _fetchedGpaMessage = allData['gpaMessage'];
        } else {
          _fetchedGpaMessage = allData['gpaMessage'];
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data filled successfully!', style: TextStyle(color: AppColors.textLight)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch data: $e', style: TextStyle(color: AppColors.textLight)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
        labelStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary),
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
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: AppColors.textPrimary),
    );
  }

  Widget buildBarChart(Map<String, double> data) {
    final bars = data.entries.map((entry) => BarChartRodData(
      toY: entry.value,
      color: AppColors.primary,
      width: 20,
      borderRadius: BorderRadius.circular(4),
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        toY: 1.0,
        color: AppColors.divider,
      ),
    )).toList();

    final labels = data.keys.toList();

    return Container(
      height: 250,
      padding: EdgeInsets.symmetric(vertical: 16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${labels[groupIndex]}\n${rod.toY.toStringAsFixed(2)}',
                  TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                );
              },
              tooltipMargin: 8,
              tooltipPadding: EdgeInsets.all(8),
              tooltipRoundedRadius: 8,
              getTooltipColor: (group) => AppColors.primary.withOpacity(0.8),
            ),
          ),
          barGroups: List.generate(bars.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [bars[index]],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
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
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.divider,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Stress Prediction", style: TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.bold,
        )),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textLight),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.0),
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
                    Icon(Icons.health_and_safety,
                        color: AppColors.textLight, size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Stress Level Prediction",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Understand how your habits affect your stress levels",
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

              // Input Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: AppColors.shadow,
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      buildTextField("Study Hours", studyController, Icons.book),
                      SizedBox(height: 16),
                      buildTextField("Extracurricular Hours", extracurricularController, Icons.sports),
                      SizedBox(height: 16),
                      buildTextField("Sleep Hours", sleepController, Icons.nightlight_round),
                      SizedBox(height: 16),
                      buildTextField("Social Hours", socialController, Icons.people),
                      SizedBox(height: 16),
                      buildTextField("Physical Activity Hours", physicalController, Icons.fitness_center),
                      SizedBox(height: 16),
                      buildTextField("GPA", gpaController, Icons.grade),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fillGpaFromFirestore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textLight,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_download, size: 20),
                            SizedBox(width: 8),
                            Text("Fetch GPA from Database"),
                          ],
                        ),
                      ),
                      if (_fetchedGpaMessage != null) ...[
                        SizedBox(height: 12),
                        Text(
                          _fetchedGpaMessage!,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Action Buttons
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  // Predict Button
                  ElevatedButton.icon(
                    onPressed: predictStress,
                    icon: Icon(Icons.analytics, size: 20),
                    label: Text("Predict"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textLight,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),

                  // Auto-Fill Button
                  ElevatedButton.icon(
                    onPressed: _autoFillData,
                    icon: Icon(Icons.auto_fix_high, size: 20),
                    label: Text("Auto-Fill"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.textLight,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),

                  // Clear Button
                  ElevatedButton.icon(
                    onPressed: clearData,
                    icon: Icon(Icons.clear, size: 20),
                    label: Text("Clear"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.divider,
                      foregroundColor: AppColors.textPrimary,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),

                  // Study Timer Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StudyTimerPage()),
                      );
                    },
                    icon: Icon(Icons.timer, size: 20),
                    label: Text("Study Timer"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPurple,
                      foregroundColor: AppColors.textLight,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Results Section
              if (stressResult != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getStressColor(stressResult!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStressColor(stressResult!).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getStressIcon(stressResult!),
                            color: _getStressColor(stressResult!),
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Stress Prediction:",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        stressResult!,
                        style: TextStyle(
                          fontSize: 18,
                          color: _getStressColor(stressResult!),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
              ],

              // Feature Importance Chart
              if (featureImportances != null) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Feature Importance",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "How each factor contributes to your stress level",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 16),
                        buildBarChart(featureImportances!),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStressColor(String stressLevel) {
    if (stressLevel.toLowerCase().contains('low')) {
      return AppColors.success;
    } else if (stressLevel.toLowerCase().contains('medium')) {
      return Colors.orange;
    } else {
      return AppColors.error;
    }
  }

  IconData _getStressIcon(String stressLevel) {
    if (stressLevel.toLowerCase().contains('low')) {
      return Icons.sentiment_very_satisfied;
    } else if (stressLevel.toLowerCase().contains('medium')) {
      return Icons.sentiment_neutral;
    } else {
      return Icons.sentiment_very_dissatisfied;
    }
  }
}