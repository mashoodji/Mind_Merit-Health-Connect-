import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../health.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/drawer_widget.dart';
import 'stress_screen.dart';
import 'gpa_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  double _socialHours = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadSocialHours();
  }

  void _loadSocialHours() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _socialHours = prefs.getDouble('social_hours') ?? 0;
    });
  }

  void _saveSocialHours(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('social_hours', value);
    setState(() {
      _socialHours = value;
    });
  }

  void _showSocialHoursDialog() {
    double tempHours = _socialHours;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text('Time spent with friends/family',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${tempHours.toStringAsFixed(1)} hours',
                      style: TextStyle(fontSize: 16)),
                  SizedBox(height: 16),
                  Slider(
                    value: tempHours,
                    min: 0,
                    max: 12,
                    divisions: 24,
                    label: '${tempHours.toStringAsFixed(1)} h',
                    onChanged: (value) {
                      setStateDialog(() {
                        tempHours = value;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    _saveSocialHours(tempHours);
                    Navigator.pop(context);
                  },
                  child: Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F8FA),
      drawer: DrawerWidget(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const HealthApp()),
          );
        },
        child: const Icon(
          Icons.medical_services,
          color: Colors.white,
          size: 28,
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            shadowColor: Colors.black12,
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded,
                  color: Colors.deepPurple, size: 26),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: RichText(
              text: const TextSpan(
                children: [
                  WidgetSpan(
                    child: Icon(Icons.school_rounded,
                        color: Colors.deepPurple, size: 33),
                    alignment: PlaceholderAlignment.middle,
                  ),
                  TextSpan(
                    text: ' Academic Dashboard',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Badge(
                  smallSize: 8,
                  child: const Icon(Icons.notifications_outlined,
                      color: Colors.black54, size: 30),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
            floating: true,
            snap: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildGreetingSection(theme),
                const SizedBox(height: 30),
                _buildMainCard(),
                const SizedBox(height: 30),
                _buildSocialHoursCard(),
                const SizedBox(height: 30),
                _buildPredictionCards(),
                const SizedBox(height: 30),
                _buildMotivationalQuote(),
                const SizedBox(height: 30),
                Text('Recent Predictions 📊',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    )),
                const SizedBox(height: 20),
                _buildChartCard(
                  title: 'Stress Levels',
                  data: [
                    FlSpot(0, 3),
                    FlSpot(1, 4),
                    FlSpot(2, 2),
                    FlSpot(3, 5),
                    FlSpot(4, 3),
                    FlSpot(5, 4),
                    FlSpot(6, 3.5),
                  ],
                  lineColor: Colors.redAccent,
                  maxX: 6,
                  maxY: 6,
                  minY: 0,
                ),
                const SizedBox(height: 20),
                _buildChartCard(
                  title: 'GPA Progress',
                  data: [
                    FlSpot(0, 2.8),
                    FlSpot(1, 3.1),
                    FlSpot(2, 3.3),
                    FlSpot(3, 3.5),
                    FlSpot(4, 3.6),
                    FlSpot(5, 3.7),
                    FlSpot(6, 3.8),
                  ],
                  lineColor: Colors.green,
                  maxX: 6,
                  maxY: 4,
                  minY: 0,
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back,',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey,
            )),
        const SizedBox(height: 4),
        Text('Mashood Farid 👋',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            )),
        const SizedBox(height: 8),
        Text('Stay on top of your academic and mental well-being ✨',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.black54,
            )),
      ],
    );
  }

  Widget _buildMainCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6E48AA), Color(0xFF9D50BB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stress & GPA\nPrediction',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Analyze your wellness and academic scores',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StressScreen(
                          averageStudyHours: null,
                          sleepHours: 0,
                          activityMinutes: 0,
                          socialHours: _socialHours,
                        ),
                      ),
                    );
                  },
                  child: const Text('Get Started',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Image.asset('assets/images/3.png', height: 130),
        ],
      ),
    );
  }

  Widget _buildSocialHoursCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Social Hours',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.deepPurple[800],
                    )),
                Icon(Icons.people_alt, color: Colors.deepPurple[300], size: 24),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _socialHours / 12,
              backgroundColor: Colors.deepPurple[100],
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.deepPurple[400]!),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_socialHours.toStringAsFixed(1)} hours this week',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    )),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: _showSocialHoursDialog,
                  child: const Text('Update',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCards() {
    return Row(
      children: [
        Expanded(
            child: _buildPredictionCard(
          title: 'Stress\nPrediction',
          icon: Icons.self_improvement,
          color: Colors.redAccent,
          description: 'Monitor your mental health',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StressScreen(
                  averageStudyHours: null,
                  sleepHours: 0,
                  activityMinutes: 0,
                  socialHours: _socialHours,
                ),
              ),
            );
          },
        )),
        const SizedBox(width: 16),
        Expanded(
            child: _buildPredictionCard(
          title: 'GPA\nPrediction',
          icon: Icons.bar_chart,
          color: Colors.green,
          description: 'Forecast your performance',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GPAScreen(
                  averageStudyHours: null,
                  sleepHours: 0,
                  activityMinutes: 0,
                ),
              ),
            );
          },
        )),
      ],
    );
  }

  Widget _buildPredictionCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required void Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.arrow_forward_rounded,
                    color: color.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotivationalQuote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            '"Small habits lead to big changes. Keep going!"',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 16,
              color: Colors.deepPurple,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.favorite, color: Colors.red, size: 16),
              SizedBox(width: 4),
              Text('Today\'s Tip',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontSize: 12,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required List<FlSpot> data,
    required Color lineColor,
    required double maxX,
    required double maxY,
    required double minY,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[200],
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey[200],
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          const style = TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          );
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Sun', style: style);
                            case 1:
                              return const Text('Mon', style: style);
                            case 2:
                              return const Text('Tue', style: style);
                            case 3:
                              return const Text('Wed', style: style);
                            case 4:
                              return const Text('Thu', style: style);
                            case 5:
                              return const Text('Fri', style: style);
                            case 6:
                              return const Text('Sat', style: style);
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data,
                      isCurved: true,
                      color: lineColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: lineColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: lineColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
