// import 'package:flutter/material.dart';
// import 'package:stress_detection/utils/colors.dart';
// import '../services/api_service.dart';
//
// class StressPrediction extends StatefulWidget {
//   const StressPrediction({super.key});
//
//   @override
//   State<StressPrediction> createState() => _StressPredictionState();
// }
//
// class _StressPredictionState extends State<StressPrediction> {
//   final _formKey = GlobalKey<FormState>();
//
//   TextEditingController studyController = TextEditingController();
//   TextEditingController extracurricularController = TextEditingController();
//   TextEditingController sleepController = TextEditingController();
//   TextEditingController socialController = TextEditingController();
//   TextEditingController physicalController = TextEditingController();
//
//   String? stressResult;
//   bool showResult = false;
//
//   void predictStress() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         final result = await ApiService.predictStress(
//           studyHours: double.parse(studyController.text),
//           extracurricularHours: double.parse(extracurricularController.text),
//           sleepHours: double.parse(sleepController.text),
//           socialHours: double.parse(socialController.text),
//           physicalActivityHours: double.parse(physicalController.text), gpa: null,
//         );
//
//         setState(() {
//           stressResult = result;
//           showResult = true;
//         });
//       } catch (e) {
//         setState(() {
//           stressResult = "Error: ${e.toString()}";
//           showResult = true;
//         });
//       }
//     }
//   }
//
//   void clearData() {
//     studyController.clear();
//     extracurricularController.clear();
//     sleepController.clear();
//     socialController.clear();
//     physicalController.clear();
//     setState(() {
//       stressResult = null;
//       showResult = false;
//     });
//   }
//
//   Widget buildTextField(String label, TextEditingController controller, IconData icon) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: TextInputType.number,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon, color: AppColors.primaryColor2),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         filled: true,
//         fillColor: Colors.white,
//         contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       ),
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return 'Please enter $label';
//         }
//         return null;
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor2,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               // Top Image Container with Back Button
//               Stack(
//                 children: [
//                   Container(
//                     decoration: BoxDecoration(
//                       color: AppColors.mainColor,
//                       borderRadius: BorderRadius.only(
//                         bottomLeft: Radius.circular(30),
//                         bottomRight: Radius.circular(30),
//                       ),
//                       image: DecorationImage(
//                         image: AssetImage('assets/images/1.png'),
//                         alignment: Alignment.bottomCenter,
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                     width: MediaQuery.of(context).size.width,
//                     height: MediaQuery.of(context).size.height * 0.55,
//                     child: Padding(
//                       padding: EdgeInsets.only(top: 20, left: 20, right: 20),
//                       child: Align(
//                         alignment: Alignment.topLeft,
//                         child: IconButton(
//                           icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
//                           onPressed: () {
//                             Navigator.pop(context);
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     bottom: 20,
//                     left: 20,
//                     child: Text(
//                       'Stress Prediction',
//                       style: TextStyle(
//                         fontSize: 30,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//
//               SizedBox(height: 20),
//
//               // Input Form
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 20),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     children: [
//                       buildTextField("Study Hours", studyController, Icons.book),
//                       SizedBox(height: 12),
//                       buildTextField("Extracurricular Hours", extracurricularController, Icons.sports),
//                       SizedBox(height: 12),
//                       buildTextField("Sleep Hours", sleepController, Icons.nightlight_round),
//                       SizedBox(height: 12),
//                       buildTextField("Social Hours", socialController, Icons.people),
//                       SizedBox(height: 12),
//                       buildTextField("Physical Activity Hours", physicalController, Icons.fitness_center),
//                     ],
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: 20),
//
//               // Buttons
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 20),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     ElevatedButton.icon(
//                       onPressed: predictStress,
//                       icon: Icon(Icons.analytics),
//                       label: Text("Predict"),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primaryColor2,
//                         foregroundColor: Colors.white,
//                         padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       ),
//                     ),
//                     OutlinedButton.icon(
//                       onPressed: clearData,
//                       icon: Icon(Icons.clear),
//                       label: Text("Clear"),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: AppColors.errorColor2,
//                         side: BorderSide(color: AppColors.errorColor2),
//                         padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               SizedBox(height: 20),
//
//               // Animated Result Section
//               AnimatedOpacity(
//                 opacity: showResult ? 1.0 : 0.0,
//                 duration: Duration(milliseconds: 500),
//                 child: showResult
//                     ? Container(
//                   margin: EdgeInsets.symmetric(horizontal: 20),
//                   padding: EdgeInsets.all(15),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.2),
//                         blurRadius: 8,
//                         spreadRadius: 1,
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       Text(
//                         "Predicted Stress Level",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: AppColors.textColor2,
//                         ),
//                       ),
//                       SizedBox(height: 8),
//                       Text(
//                         stressResult ?? '',
//                         style: TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                           color: AppColors.primaryColor2,
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//                     : SizedBox(),
//               ),
//
//               SizedBox(height: 30),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
