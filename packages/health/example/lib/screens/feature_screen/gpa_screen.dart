import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
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
  Map<String, double>? featureImportances;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
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
          totalMinutes += dailyMinutes[key] ?? 0;
        }

        return totalMinutes / 60 / recentKeys.length;
      }
    } catch (e) {
      debugPrint('Error fetching study data: $e');
    }
    return 0;
  }

  Future<void> _autoFillData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight)),
              SizedBox(width: 16),
              Text('Fetching data...', style: TextStyle(color: AppColors.textLight)),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );

      double studyHours = await _getStudyHoursFromTimer();
      Map<String, double> healthData = await GPADataFetcher.getHealthData();

      setState(() {
        studyController.text = studyHours.toStringAsFixed(1);
        sleepController.text = (healthData['sleepHours'] ?? 0.0).toStringAsFixed(1);
        physicalController.text = (healthData['activityMinutes'] ?? 0.0).toStringAsFixed(0);

        if (socialController.text.isEmpty) socialController.text = '2.0';
        if (extracurricularController.text.isEmpty) extracurricularController.text = '1.0';
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
      setState(() => _errorMessage = 'Failed to fetch data: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!, style: TextStyle(color: AppColors.textLight)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> predictGPA() async {
    // Validate inputs
    if (studyController.text.isEmpty ||
        extracurricularController.text.isEmpty ||
        sleepController.text.isEmpty ||
        socialController.text.isEmpty ||
        physicalController.text.isEmpty) {
      setState(() {
        gpaResult = null;
        featureImportances = null;
        _errorMessage = "All fields must be filled";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.predictGPA(
        studyHours: double.tryParse(studyController.text) ?? 0,
        extracurricularHours: double.tryParse(extracurricularController.text) ?? 0,
        sleepHours: double.tryParse(sleepController.text) ?? 0,
        socialHours: double.tryParse(socialController.text) ?? 0,
        physicalActivityHours: double.tryParse(physicalController.text) ?? 0,
      );

      if (response == null || response["predicted_cgpa"] == null) {
        throw Exception("Invalid response from server");
      }

      setState(() {
        gpaResult = response["predicted_cgpa"].toStringAsFixed(2);
        featureImportances = response["feature_importance"] is Map
            ? Map<String, double>.from(response["feature_importance"])
            : null;
      });
    } catch (e) {
      setState(() {
        gpaResult = null;
        featureImportances = null;
        _errorMessage = "Error predicting GPA: ${e.toString().replaceAll('Bad state: No element', 'No data available')}";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void clearData() {
    studyController.clear();
    extracurricularController.clear();
    sleepController.text = widget.sleepHours.toStringAsFixed(1);
    physicalController.text = widget.activityMinutes.toStringAsFixed(0);
    if (widget.averageStudyHours != null) {
      studyController.text = widget.averageStudyHours!.toStringAsFixed(1);
    }
    socialController.clear();
    setState(() {
      gpaResult = null;
      featureImportances = null;
      _errorMessage = null;
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
    if (data.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: Text(
          "No feature importance data available",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    try {
      final sortedEntries = data.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (sortedEntries.isEmpty) {
        return Container(
          height: 150,
          alignment: Alignment.center,
          child: Text(
            "No data to display",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        );
      }

      final maxValue = sortedEntries.first.value.toDouble();
      final normalizedData = Map.fromEntries(
          sortedEntries.map((e) => MapEntry(e.key, maxValue > 0 ? e.value.toDouble() / maxValue : 0.0))
      );

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
                    '${sortedEntries[groupIndex].key}\n${sortedEntries[groupIndex].value.toStringAsFixed(2)}',
                    TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
                tooltipMargin: 8,
                tooltipPadding: EdgeInsets.all(8),
                tooltipRoundedRadius: 8,
                getTooltipColor: (group) => AppColors.primary.withOpacity(0.9),
              ),
            ),
            barGroups: List.generate(normalizedData.length, (index) {
              final value = normalizedData.values.elementAt(index).toDouble();
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: value,
                    color: _getGradientColor(value),
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 1.0,
                      color: AppColors.divider,
                    ),
                  ),
                ],
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
                    if (idx >= 0 && idx < sortedEntries.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          sortedEntries[idx].key.replaceAll('_', '\n'),
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
    } catch (e) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: Text(
          "Error displaying chart",
          style: TextStyle(color: AppColors.error),
        ),
      );
    }
  }

  Color _getGradientColor(double value) {
    try {
      final double normalizedValue = value.toDouble();
      if (normalizedValue < 0.3) {
        return Color.lerp(AppColors.success, Colors.orange, normalizedValue / 0.3)!;
      } else {
        return Color.lerp(Colors.orange, AppColors.error, (normalizedValue - 0.3) / 0.7)!;
      }
    } catch (e) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("GPA Prediction", style: TextStyle(
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
                    Icon(Icons.school, color: AppColors.textLight, size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "GPA Prediction",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Understand how your habits affect your academic performance",
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
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: AppColors.error),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Action Buttons
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  // Predict Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : predictGPA,
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
                    onPressed: _isLoading ? null : _autoFillData,
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
                    onPressed: _isLoading ? null : clearData,
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
                    onPressed: _isLoading ? null : () {
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

              // Loading Indicator
              if (_isLoading) ...[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],

              // Results Section
              if (gpaResult != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Predicted GPA:",
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
                        gpaResult!,
                        style: TextStyle(
                          fontSize: 24,
                          color: AppColors.primary,
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
                          "How each factor contributes to your GPA",
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
}