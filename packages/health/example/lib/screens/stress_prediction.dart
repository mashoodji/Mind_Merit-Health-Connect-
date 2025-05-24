import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';
import 'feature_screen/study_timer.dart';

class StressPrediction extends StatefulWidget {
  final double? averageStudyHours;
  final double sleepHours;
  final double activityMinutes;

  const StressPrediction({
    super.key,
    this.averageStudyHours,
    required this.sleepHours,
    required this.activityMinutes,
  });

  @override
  State<StressPrediction> createState() => _StressPredictionState();
}

class _StressPredictionState extends State<StressPrediction> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController studyController = TextEditingController();
  TextEditingController extracurricularController = TextEditingController();
  TextEditingController sleepController = TextEditingController();
  TextEditingController socialController = TextEditingController();
  TextEditingController physicalController = TextEditingController();
  TextEditingController gpaController = TextEditingController();

  String? stressResult;
  Map<String, double>? featureImportances;
  String? _fetchedGpaMessage;
  bool showResult = false;

  @override
  void initState() {
    super.initState();
    sleepController.text = widget.sleepHours.toStringAsFixed(1);
    physicalController.text = widget.activityMinutes.toStringAsFixed(0);
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
    if (_formKey.currentState!.validate()) {
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
          showResult = true;
        });
      } catch (e) {
        setState(() {
          stressResult = "Error predicting: ${e.toString()}";
          featureImportances = null;
          showResult = true;
        });
      }
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
      showResult = false;
    });
  }

  Widget buildTextField(
      String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryColor2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Image Container with Back Button
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.mainColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      image: DecorationImage(
                        image: AssetImage('assets/images/1.png'),
                        alignment: Alignment.bottomCenter,
                        fit: BoxFit.none,
                        scale: 5.5,
                      ),
                    ),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Padding(
                      padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: Colors.white, size: 30),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 70,
                    child: Text(
                      'Stress Prediction',
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),

              SizedBox(height: 20),

              // Input Form
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      buildTextField(
                          "Study Hours", studyController, Icons.book),
                      SizedBox(height: 12),
                      buildTextField("Extracurricular Hours",
                          extracurricularController, Icons.sports_soccer),
                      SizedBox(height: 12),
                      buildTextField("Sleep Hours", sleepController,
                          Icons.nightlight_round),
                      SizedBox(height: 12),
                      buildTextField(
                          "Social Hours", socialController, Icons.people),
                      SizedBox(height: 12),
                      buildTextField("Physical Activity (minutes)",
                          physicalController, Icons.fitness_center),
                      SizedBox(height: 12),
                      buildTextField("GPA", gpaController, Icons.grade),
                      SizedBox(height: 10),
                      // Fill GPA Button
                      ElevatedButton.icon(
                        onPressed: _fillGpaFromFirestore,
                        icon: Icon(Icons.download_done),
                        label: Text("Fill GPA from University"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      if (_fetchedGpaMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _fetchedGpaMessage!,
                            style: TextStyle(
                              fontSize: 14,
                              color: _fetchedGpaMessage!.startsWith("Error") ||
                                      _fetchedGpaMessage!
                                          .startsWith("No CGPA") ||
                                      _fetchedGpaMessage!
                                          .startsWith("Not a university") ||
                                      _fetchedGpaMessage!
                                          .startsWith("User not logged in")
                                  ? AppColors.errorColor2
                                  : AppColors.primaryColor2,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: predictStress,
                      icon: Icon(Icons.analytics),
                      label: Text("Predict"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor2,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Study Timer'),
                    ),
                    OutlinedButton.icon(
                      onPressed: clearData,
                      icon: Icon(Icons.clear),
                      label: Text("Clear"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorColor2,
                        side: BorderSide(color: AppColors.errorColor2),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Animated Result Section
              AnimatedOpacity(
                opacity: showResult ? 1.0 : 0.0,
                duration: Duration(milliseconds: 500),
                child: showResult
                    ? Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Predicted Stress Level",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textColor2,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              stressResult ?? '',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: stressResult!.startsWith("Error")
                                    ? AppColors.errorColor2
                                    : AppColors.primaryColor2,
                              ),
                            ),
                            if (featureImportances != null) ...[
                              SizedBox(height: 20),
                              Text(
                                "Feature Impact on Stress",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textColor2),
                              ),
                              buildBarChart(featureImportances!),
                            ],
                          ],
                        ),
                      )
                    : SizedBox(),
              ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
