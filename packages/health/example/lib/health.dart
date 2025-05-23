import 'dart:async';
import 'dart:io';
import 'package:health_example/screens/feature_screen/study_timer.dart';
import 'package:health_example/screens/gpa_screen.dart';
import 'package:health_example/screens/home_screen.dart';
import 'package:health_example/screens/stress_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:health_example/util.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:carp_serializable/carp_serializable.dart';

// Global Health instance
final health = Health();

void main() => runApp(HealthApp());

class HealthApp extends StatefulWidget {
  const HealthApp({super.key});

  @override
  HealthAppState createState() => HealthAppState();
}

enum AppState {
  DATA_NOT_FETCHED,
  FETCHING_DATA,
  DATA_READY,
  NO_DATA,
  AUTHORIZED,
  AUTH_NOT_GRANTED,
  DATA_ADDED,
  DATA_DELETED,
  DATA_NOT_ADDED,
  DATA_NOT_DELETED,
  STEPS_READY,
  SLEEP_READY,
  ACTIVITY_READY,
  HEALTH_CONNECT_STATUS,
  PERMISSIONS_REVOKING,
  PERMISSIONS_REVOKED,
  PERMISSIONS_NOT_REVOKED,
}

class HealthAppState extends State<HealthApp> {
  List<HealthDataPoint> _healthDataList = [];
  AppState _state = AppState.DATA_NOT_FETCHED;
  int _nofSteps = 0;
  double _sleepHours = 0.0;
  double _activityMinutes = 0.0;
  List<RecordingMethod> recordingMethodsToFilter = [];

  // Define colors
  final Color primaryColor = const Color(0xFF4285F4);
  final Color secondaryColor = const Color(0xFF34A853);
  final Color accentColor = const Color(0xFFEA4335);
  final Color backgroundColor = const Color(0xFFF8F9FA);

  List<HealthDataType> get types => (Platform.isAndroid)
      ? dataTypesAndroid
      : (Platform.isIOS)
      ? dataTypesIOS
      : [];

  List<HealthDataAccess> get permissions => types
      .map((type) =>
  [
    HealthDataType.WALKING_HEART_RATE,
    HealthDataType.ELECTROCARDIOGRAM,
    HealthDataType.HIGH_HEART_RATE_EVENT,
    HealthDataType.LOW_HEART_RATE_EVENT,
    HealthDataType.IRREGULAR_HEART_RATE_EVENT,
    HealthDataType.EXERCISE_TIME,
  ].contains(type)
      ? HealthDataAccess.READ
      : HealthDataAccess.READ_WRITE)
      .toList();

  @override
  void initState() {
    super.initState();
    _initHealth();
  }



  Future<void> _initHealth() async {
    await health.configure();
    if (Platform.isAndroid) {
      await health.getHealthConnectSdkStatus();
      await _checkHealthConnectInstallation();
    }
    await _requestBasicPermissions();
    await Permission.activityRecognition.request();
    await Permission.location.request();
  }

  Future<void> _checkHealthConnectInstallation() async {
    final status = await health.getHealthConnectSdkStatus();
    if (status != HealthConnectSdkStatus.sdkAvailable) {
      await health.installHealthConnect();
    }
  }

  Future<void> _requestBasicPermissions() async {
    await Permission.activityRecognition.request();
    await Permission.location.request();
  }

  Future<void> installHealthConnect() async => await health.installHealthConnect();

  Future<void> authorize() async {
    bool? hasPermissions = await health.hasPermissions(types, permissions: permissions);
    hasPermissions = false; // Force re-request for testing

    bool authorized = false;
    if (!hasPermissions) {
      try {
        authorized = await health.requestAuthorization(types, permissions: permissions);
        if (Platform.isAndroid) {
          await health.requestHealthDataHistoryAuthorization();
        }
      } catch (error) {
        debugPrint("Exception in authorize: $error");
      }
    }

    setState(() => _state = (authorized) ? AppState.AUTHORIZED : AppState.AUTH_NOT_GRANTED);
  }

  Future<void> getHealthConnectSdkStatus() async {
    assert(Platform.isAndroid, "This is only available on Android");

    final status = await health.getHealthConnectSdkStatus();

    setState(() {
      _contentHealthConnectStatus =
          Text('Health Connect Status: ${status?.name.toUpperCase()}');
      _state = AppState.HEALTH_CONNECT_STATUS;
    });
  }

  void refreshData() async {
    await fetchStepData();
    await fetchSleepData();
    await fetchActivityData();
  }

  Future<void> fetchData() async {
    setState(() => _state = AppState.FETCHING_DATA);

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    _healthDataList.clear();

    try {
      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        types: types,
        startTime: yesterday,
        endTime: now,
        recordingMethodsToFilter: recordingMethodsToFilter,
      );

      debugPrint('Total number of data points: ${healthData.length}.');

      healthData.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      _healthDataList.addAll((healthData.length < 100) ? healthData : healthData.sublist(0, 100));
    } catch (error) {
      debugPrint("Exception in getHealthDataFromTypes: $error");
    }

    _healthDataList = health.removeDuplicates(_healthDataList);

    for (var data in _healthDataList) {
      debugPrint(toJsonString(data));
    }

    setState(() {
      _state = _healthDataList.isEmpty ? AppState.NO_DATA : AppState.DATA_READY;
    });
  }

  Future<void> addData() async {
    final now = DateTime.now();
    final earlier = now.subtract(const Duration(minutes: 20));

    bool success = true;

    success &= await health.writeHealthData(
        value: 1.925,
        type: HealthDataType.HEIGHT,
        startTime: earlier,
        endTime: now,
        recordingMethod: RecordingMethod.manual);
    success &= await health.writeHealthData(
        value: 90,
        type: HealthDataType.WEIGHT,
        startTime: now,
        recordingMethod: RecordingMethod.manual);
    success &= await health.writeHealthData(
        value: 90,
        type: HealthDataType.HEART_RATE,
        startTime: earlier,
        endTime: now,
        recordingMethod: RecordingMethod.manual);

    setState(() {
      _state = success ? AppState.DATA_ADDED : AppState.DATA_NOT_ADDED;
    });
  }

  Future<void> deleteData() async {
    final now = DateTime.now();
    final earlier = now.subtract(const Duration(hours: 24));

    bool success = true;
    for (HealthDataType type in types) {
      success &= await health.delete(
        type: type,
        startTime: earlier,
        endTime: now,
      );
    }

    setState(() {
      _state = success ? AppState.DATA_DELETED : AppState.DATA_NOT_DELETED;
    });
  }

  Future<void> fetchStepData() async {
    int? steps;

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    bool stepsPermission = await health.hasPermissions([HealthDataType.STEPS]) ?? false;
    if (!stepsPermission) {
      stepsPermission = await health.requestAuthorization([HealthDataType.STEPS]);
    }

    if (stepsPermission) {
      try {
        steps = await health.getTotalStepsInInterval(midnight, now,
            includeManualEntry:
            !recordingMethodsToFilter.contains(RecordingMethod.manual));
      } catch (error) {
        debugPrint("Exception in getTotalStepsInInterval: $error");
      }

      debugPrint('Total number of steps: $steps');

      setState(() {
        _nofSteps = (steps == null) ? 0 : steps;
        _state = (steps == null) ? AppState.NO_DATA : AppState.STEPS_READY;
      });
    } else {
      debugPrint("Authorization not granted - error in authorization");
      setState(() => _state = AppState.DATA_NOT_FETCHED);
    }
  }

  Future<void> fetchSleepData() async {
    setState(() => _state = AppState.FETCHING_DATA);

    final now = DateTime.now();
    final endTime = DateTime(now.year, now.month, now.day); // Today at midnight
    final startTime = endTime.subtract(Duration(days: 7));

    try {
      List<HealthDataPoint> sleepData = await health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_SESSION],
        startTime: startTime,
        endTime: endTime,
      );

      final dailySleep = <DateTime, double>{};
      final calculationLog = <String>[];
      double totalSleep = 0;
      int daysWithData = 0;
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

      for (var record in sleepData) {
        final duration = record.dateTo.difference(record.dateFrom);
        final double hours = duration.inMinutes / 60.0;

        final recordDate = DateTime(record.dateFrom.year, record.dateFrom.month, record.dateFrom.day);

        if (recordDate.isAfter(startTime.subtract(Duration(seconds: 1))) && recordDate.isBefore(endTime)) {
          dailySleep.update(recordDate, (total) => total + hours, ifAbsent: () => hours);
        }
      }

      for (int i = 0; i < 7; i++) {
        final currentDate = startTime.add(Duration(days: i));
        final dayName = dayNames[currentDate.weekday - 1];
        final dateStr = DateFormat('MMM d').format(currentDate);

        if (dailySleep.containsKey(currentDate)) {
          final hours = dailySleep[currentDate]!;
          totalSleep += hours;
          daysWithData++;
          calculationLog.add('$dayName ($dateStr): ${hours.toStringAsFixed(1)} hrs');
        } else {
          calculationLog.add('$dayName ($dateStr): No data');
        }
      }

      double averageSleep = daysWithData > 0 ? totalSleep / daysWithData : 0;

      debugPrint('=== MATCHED SLEEP DATA ===');
      debugPrint('Date Range: ${DateFormat('MMM d').format(startTime)} to ${DateFormat('MMM d').format(endTime.subtract(Duration(days: 1)))}');
      debugPrint(calculationLog.join('\n'));
      debugPrint('----------------------');
      debugPrint('Total: $totalSleep hours');
      debugPrint('Days with data: $daysWithData');
      debugPrint('Average: ${averageSleep.toStringAsFixed(1)} hrs/day');
      debugPrint('======================');

      setState(() {
        _sleepHours = averageSleep;
        _state = averageSleep > 0 ? AppState.SLEEP_READY : AppState.NO_DATA;
      });

    } catch (error) {
      debugPrint('Error fetching sleep data: $error');
      setState(() => _state = AppState.NO_DATA);
    }
  }


  Future<void> fetchActivityData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    // Use platform-specific activity metrics
    List<HealthDataType> activityTypes = Platform.isAndroid
        ? [HealthDataType.ACTIVE_ENERGY_BURNED]
        : [HealthDataType.EXERCISE_TIME, HealthDataType.ACTIVE_ENERGY_BURNED];

    bool activityPermission = await health.hasPermissions(activityTypes) ?? false;
    if (!activityPermission) {
      activityPermission = await health.requestAuthorization(activityTypes);
    }

    if (activityPermission) {
      try {
        // Get activity data
        List<HealthDataPoint> activityData = await health.getHealthDataFromTypes(
          types: activityTypes,
          startTime: midnight,
          endTime: now,
        );

        // Calculate total activity minutes
        double activityMinutes = 0;
        for (var data in activityData) {
          if (data.type == HealthDataType.EXERCISE_TIME) {
            activityMinutes += data.value is double
                ? data.value as double
                : (data.value as int).toDouble();
          } else if (data.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
            // Convert calories to activity minutes (5 cals ≈ 1 minute)
            activityMinutes += (data.value is double
                ? data.value as double
                : (data.value as int).toDouble()) / 5.0;
          }
        }

        // Fallback: Use steps if no direct activity data
        if (activityMinutes == 0) {
          int? steps = await health.getTotalStepsInInterval(midnight, now);
          if (steps != null && steps > 0) {
            activityMinutes = steps / 100.0; // 100 steps ≈ 1 minute
          }
        }

        setState(() {
          _activityMinutes = activityMinutes;
          _state = activityMinutes > 0 ? AppState.ACTIVITY_READY : AppState.NO_DATA;
        });

      } catch (error) {
        debugPrint("Activity data error: $error");
        setState(() => _state = AppState.NO_DATA);
      }
    } else {
      debugPrint("Activity permissions not granted");
      setState(() => _state = AppState.DATA_NOT_FETCHED);
    }
  }

  Future<void> revokeAccess() async {
    setState(() => _state = AppState.PERMISSIONS_REVOKING);

    bool success = false;
    try {
      await health.revokePermissions();
      success = true;
    } catch (error) {
      debugPrint("Exception in revokeAccess: $error");
    }

    setState(() {
      _state = success
          ? AppState.PERMISSIONS_REVOKED
          : AppState.PERMISSIONS_NOT_REVOKED;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: backgroundColor,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        buttonTheme: ButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Health Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: primaryColor,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildActionButtons(),
                const SizedBox(height: 20),
                _buildHealthMetrics(),
                const SizedBox(height: 20),
                _buildDataSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        if (Platform.isAndroid)
          _buildActionButton(
            "Check Health Connect Status",
            getHealthConnectSdkStatus,
            icon: Icons.health_and_safety,
          ),
        if (Platform.isAndroid &&
            health.healthConnectSdkStatus != HealthConnectSdkStatus.sdkAvailable)
          _buildActionButton(
            "Install Health Connect",
            installHealthConnect,
            icon: Icons.download,
          ),
        if (Platform.isIOS ||
            (Platform.isAndroid &&
                health.healthConnectSdkStatus == HealthConnectSdkStatus.sdkAvailable))
          Column(
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildActionButton(
                    "Authenticate",
                    authorize,
                    icon: Icons.lock_open,
                  ),
                  _buildActionButton(
                    "Fetch All Data",
                    fetchData,
                    icon: Icons.refresh,
                  ),
                  _buildActionButton(
                    "Add Sample Data",
                    addData,
                    icon: Icons.add,
                  ),
                  _buildActionButton(
                    "Delete Data",
                    deleteData,
                    icon: Icons.delete,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildActionButton(
                    "Get Steps",
                    fetchStepData,
                    icon: Icons.directions_walk,
                  ),
                  _buildActionButton(
                    "Get Sleep",
                    fetchSleepData,
                    icon: Icons.bedtime,
                  ),
                  _buildActionButton(
                    "Get Activity",
                    fetchActivityData,
                    icon: Icons.directions_run,
                  ),
                  _buildActionButton(
                    "Revoke Access",
                    revokeAccess,
                    icon: Icons.lock,
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
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),

                      ),

                      ),
                    child: Text('Get_Study'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StressScreen(
                            averageStudyHours: null,
                            sleepHours: _sleepHours,
                            activityMinutes: _activityMinutes,
                          ),
                        ),
                      );
                    },
                    child: Text('Stress Prediction'),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GPAScreen(
                            averageStudyHours: null,
                            sleepHours: _sleepHours,
                            activityMinutes: _activityMinutes,
                          ),
                        ),
                      );
                    },
                    child: Text('GPA Prediction'),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed, {IconData? icon}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 18),
          if (icon != null) const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildHealthMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Today's Health Metrics",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetricCard("Steps", _nofSteps.toString(), Icons.directions_walk),
                _buildMetricCard("Sleep", "${_sleepHours.toStringAsFixed(1)}h", Icons.bedtime),
                _buildMetricCard("Activity", "${_activityMinutes.toStringAsFixed(0)}m", Icons.directions_run),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: primaryColor),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Health Data",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_state == AppState.DATA_READY) _dataFiltration,
            if (_state == AppState.STEPS_READY ||
                _state == AppState.SLEEP_READY ||
                _state == AppState.ACTIVITY_READY) _stepsFiltration,
            const SizedBox(height: 10),
            _content,
          ],
        ),
      ),
    );
  }

  Widget get _dataFiltration => Column(
    children: [
      const Text("Filter Data:"),
      const SizedBox(height: 8),
      Wrap(
        children: [
          for (final method in Platform.isAndroid
              ? [
            RecordingMethod.manual,
            RecordingMethod.automatic,
            RecordingMethod.active,
            RecordingMethod.unknown,
          ]
              : [
            RecordingMethod.automatic,
            RecordingMethod.manual,
          ])
            SizedBox(
              width: 150,
              child: CheckboxListTile(
                title: Text(
                    '${method.name[0].toUpperCase()}${method.name.substring(1)}'),
                value: !recordingMethodsToFilter.contains(method),
                onChanged: (value) {
                  setState(() {
                    if (value!) {
                      recordingMethodsToFilter.remove(method);
                    } else {
                      recordingMethodsToFilter.add(method);
                    }
                    fetchData();
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
        ],
      ),
    ],
  );

  Widget get _stepsFiltration => Column(
    children: [
      const Text("Filter Data:"),
      const SizedBox(height: 8),
      Wrap(
        children: [
          for (final method in [RecordingMethod.manual])
            SizedBox(
              width: 150,
              child: CheckboxListTile(
                title: Text(
                    '${method.name[0].toUpperCase()}${method.name.substring(1)}'),
                value: !recordingMethodsToFilter.contains(method),
                onChanged: (value) {
                  setState(() {
                    if (value!) {
                      recordingMethodsToFilter.remove(method);
                    } else {
                      recordingMethodsToFilter.add(method);
                    }
                    if (_state == AppState.STEPS_READY) {
                      fetchStepData();
                    } else if (_state == AppState.SLEEP_READY) {
                      fetchSleepData();
                    } else if (_state == AppState.ACTIVITY_READY) {
                      fetchActivityData();
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
        ],
      ),
    ],
  );

  Widget get _permissionsRevoking => const Center(
    child: Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Revoking permissions...'),
      ],
    ),
  );

  Widget get _permissionsRevoked => const Center(
    child: Text('Permissions revoked.', style: TextStyle(color: Colors.green)),
  );

  Widget get _permissionsNotRevoked => const Center(
    child: Text('Failed to revoke permissions', style: TextStyle(color: Colors.red)),
  );

  Widget get _contentFetchingData => const Center(
    child: Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Fetching data...'),
      ],
    ),
  );

  Widget get _contentDataReady => SizedBox(
    height: 300,
    child: ListView.builder(
      itemCount: _healthDataList.length,
      itemBuilder: (_, index) {
        if (recordingMethodsToFilter
            .contains(_healthDataList[index].recordingMethod)) {
          return Container();
        }

        HealthDataPoint p = _healthDataList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text("${p.typeString}: ${p.value}"),
            trailing: Text(p.unitString),
            subtitle: Text('${p.dateFrom} - ${p.dateTo}\n${p.recordingMethod}'),
          ),
        );
      },
    ),
  );

  Widget get _contentNoData => const Center(
    child: Text('No data available', style: TextStyle(color: Colors.grey)),
  );

  Widget get _contentNotFetched => const Center(
    child: Column(
      children: [
        Icon(Icons.health_and_safety, size: 48, color: Colors.grey),
        SizedBox(height: 16),
        Text("Welcome to Health Tracker"),
        SizedBox(height: 8),
        Text("Authenticate to access health data"),
      ],
    ),
  );

  Widget get _authorized => const Center(
    child: Column(
      children: [
        Icon(Icons.check_circle, size: 48, color: Colors.green),
        SizedBox(height: 16),
        Text('Authorization granted!'),
      ],
    ),
  );

  Widget get _authorizationNotGranted => const Center(
    child: Column(
      children: [
        Icon(Icons.error, size: 48, color: Colors.red),
        SizedBox(height: 16),
        Text('Authorization not given.'),
        SizedBox(height: 8),
        Text('Please check your permissions.'),
      ],
    ),
  );

  Widget _contentHealthConnectStatus = const Text('No status available');

  Widget get _dataAdded => const Center(
    child: Column(
      children: [
        Icon(Icons.check, size: 48, color: Colors.green),
        SizedBox(height: 16),
        Text('Data added successfully!'),
      ],
    ),
  );

  Widget get _dataDeleted => const Center(
    child: Column(
      children: [
        Icon(Icons.check, size: 48, color: Colors.green),
        SizedBox(height: 16),
        Text('Data deleted successfully!'),
      ],
    ),
  );

  Widget get _stepsFetched => Center(
    child: Column(
      children: [
        const Icon(Icons.directions_walk, size: 48, color: Colors.blue),
        const SizedBox(height: 16),
        Text('Steps today: $_nofSteps',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget get _sleepFetched => Center(
    child: Column(
      children: [
        const Icon(Icons.bedtime, size: 48, color: Colors.purple),
        const SizedBox(height: 16),
        Text('Weekly_Sleep: ${_sleepHours.toStringAsFixed(1)} hours',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget get _activityFetched => Center(
    child: Column(
      children: [
        const Icon(Icons.directions_run, size: 48, color: Colors.green),
        const SizedBox(height: 16),
        Text('Weekly_Activity : ${_activityMinutes.toStringAsFixed(0)} minutes',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget get _dataNotAdded => const Center(
    child: Column(
      children: [
        Icon(Icons.error, size: 48, color: Colors.red),
        SizedBox(height: 16),
        Text('Failed to add data'),
      ],
    ),
  );

  Widget get _dataNotDeleted => const Center(
    child: Column(
      children: [
        Icon(Icons.error, size: 48, color: Colors.red),
        SizedBox(height: 16),
        Text('Failed to delete data'),
      ],
    ),
  );

  Widget get _content => switch (_state) {
    AppState.DATA_READY => _contentDataReady,
    AppState.DATA_NOT_FETCHED => _contentNotFetched,
    AppState.FETCHING_DATA => _contentFetchingData,
    AppState.NO_DATA => _contentNoData,
    AppState.AUTHORIZED => _authorized,
    AppState.AUTH_NOT_GRANTED => _authorizationNotGranted,
    AppState.DATA_ADDED => _dataAdded,
    AppState.DATA_DELETED => _dataDeleted,
    AppState.DATA_NOT_ADDED => _dataNotAdded,
    AppState.DATA_NOT_DELETED => _dataNotDeleted,
    AppState.STEPS_READY => _stepsFetched,
    AppState.SLEEP_READY => _sleepFetched,
    AppState.ACTIVITY_READY => _activityFetched,
    AppState.HEALTH_CONNECT_STATUS => _contentHealthConnectStatus,
    AppState.PERMISSIONS_REVOKING => _permissionsRevoking,
    AppState.PERMISSIONS_REVOKED => _permissionsRevoked,
    AppState.PERMISSIONS_NOT_REVOKED => _permissionsNotRevoked,
  };
}