import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';

class GPAScreen extends StatefulWidget {
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

  Widget buildInputField(String label, IconData icon, TextEditingController controller) {
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
        title: Text("GPA Prediction"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildInputField("Study Hours", FontAwesomeIcons.book, studyController),
            buildInputField("Extracurricular Hours", FontAwesomeIcons.basketballBall, extracurricularController),
            buildInputField("Sleep Hours", FontAwesomeIcons.bed, sleepController),
            buildInputField("Social Hours", FontAwesomeIcons.users, socialController),
            buildInputField("Physical Activity Hours", FontAwesomeIcons.running, physicalController),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: predictGPA,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 30),
              ),
              child: Text("Predict GPA", style: TextStyle(fontSize: 18)),
            ),
            SizedBox(height: 20),
            gpaResult == null
                ? Text("Enter values to predict GPA", style: TextStyle(fontSize: 16, color: Colors.grey))
                : Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.lightBlueAccent,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Predicted GPA: $gpaResult",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
