// import 'package:flutter/material.dart';
// import 'package:flutter_health_connect/flutter_health_connect.dart';
// import 'dart:io';
//
// class HealthConnectScreen extends StatefulWidget {
//   const HealthConnectScreen({super.key});
//
//   @override
//   State<HealthConnectScreen> createState() => _HealthConnectScreenState();
// }
//
// class _HealthConnectScreenState extends State<HealthConnectScreen> {
//   List<HealthConnectDataType> types = [
//     HealthConnectDataType.Steps,
//     HealthConnectDataType.HeartRate,
//     HealthConnectDataType.SleepSession,
//     HealthConnectDataType.OxygenSaturation,
//     HealthConnectDataType.RespiratoryRate,
//   ];
//
//   bool readOnly = false;
//   String resultText = '';
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Health Connect'),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           ElevatedButton(
//             onPressed: _checkApiSupported,
//             child: const Text('Is API Supported'),
//           ),
//           ElevatedButton(
//             onPressed: _checkAvailability,
//             child: const Text('Check Installed/Available'),
//           ),
//           ElevatedButton(
//             onPressed: _openHealthConnectSettings,
//             child: const Text('Open Health Connect Settings'),
//           ),
//           ElevatedButton(
//             onPressed: _checkPermissions,
//             child: const Text('Has Permissions'),
//           ),
//           ElevatedButton(
//             onPressed: _requestPermissionsSafely,
//             child: const Text('Request Permissions Safely'),
//           ),
//           ElevatedButton(
//             onPressed: _getStepRecords,
//             child: const Text('Get Step Records'),
//           ),
//           const SizedBox(height: 20),
//           Text(
//             resultText,
//             style: const TextStyle(fontSize: 14),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _updateResultText(String message) {
//     if (!mounted) return;
//     setState(() {
//       resultText = message;
//     });
//     debugPrint(message);
//   }
//
//   Future<void> _checkApiSupported() async {
//     var supported = await HealthConnectFactory.isApiSupported();
//     _updateResultText('isApiSupported: $supported');
//   }
//
//   Future<void> _checkAvailability() async {
//     var supported = await HealthConnectFactory.isApiSupported();
//     if (!supported) {
//       _updateResultText('Health Connect API is not supported on this device.');
//       return;
//     }
//
//     var available = await HealthConnectFactory.isAvailable();
//     _updateResultText('isAvailable: $available');
//
//     if (!available) {
//       _updateResultText('Health Connect likely integrated into Android Settings (Android 14+). Opening settings...');
//       await HealthConnectFactory.openHealthConnectSettings();
//     }
//   }
//
//   Future<void> _openHealthConnectSettings() async {
//     await HealthConnectFactory.openHealthConnectSettings();
//     _updateResultText('Opened Health Connect settings.');
//   }
//
//   Future<void> _checkPermissions() async {
//     var supported = await HealthConnectFactory.isApiSupported();
//     if (!supported) {
//       _updateResultText('Health Connect API is not supported on this device.');
//       return;
//     }
//
//     var result = await HealthConnectFactory.hasPermissions(
//       types,
//       readOnly: readOnly,
//     );
//     _updateResultText('hasPermissions: $result');
//   }
//
//   Future<void> _requestPermissionsSafely() async {
//     var supported = await HealthConnectFactory.isApiSupported();
//     if (!supported) {
//       _updateResultText('Health Connect API is not supported on this device.');
//       return;
//     }
//
//     var available = await HealthConnectFactory.isAvailable();
//     if (!available) {
//       _updateResultText('Health Connect not available — likely built into Android 14 Settings. Opening settings...');
//       await HealthConnectFactory.openHealthConnectSettings();
//       return;
//     }
//
//     var result = await HealthConnectFactory.requestPermissions(
//       types,
//       readOnly: readOnly,
//     );
//     _updateResultText('Permissions granted: $result');
//   }
//
//   Future<void> _getStepRecords() async {
//     var supported = await HealthConnectFactory.isApiSupported();
//     if (!supported) {
//       _updateResultText('Health Connect API is not supported on this device.');
//       return;
//     }
//
//     var available = await HealthConnectFactory.isAvailable();
//     if (!available) {
//       _updateResultText('Health Connect not available — open settings manually.');
//       await HealthConnectFactory.openHealthConnectSettings();
//       return;
//     }
//
//     var hasPermission = await HealthConnectFactory.hasPermissions(
//       types,
//       readOnly: readOnly,
//     );
//
//     if (!hasPermission) {
//       _updateResultText('Permissions not granted — requesting now.');
//       var granted = await HealthConnectFactory.requestPermissions(
//         types,
//         readOnly: readOnly,
//       );
//       if (!granted) {
//         _updateResultText('Permissions denied.');
//         return;
//       }
//     }
//
//     var startTime = DateTime.now().subtract(const Duration(days: 4));
//     var endTime = DateTime.now();
//
//     var results = await HealthConnectFactory.getRecord(
//       type: types.first,
//       startTime: startTime,
//       endTime: endTime,
//     );
//
//     double totalSteps = 0;
//     var stepsRecords = results[HealthConnectDataType.Steps.name];
//
//     if (stepsRecords != null) {
//       for (var record in stepsRecords) {
//         totalSteps += record.count;
//       }
//     }
//
//     _updateResultText(
//       'Steps from ${startTime.toLocal()} to ${endTime.toLocal()}: $totalSteps\n\nFull results:\n$results',
//     );
//   }
// }
