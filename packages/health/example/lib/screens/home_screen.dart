import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main2.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/drawer_widget.dart';
import 'health_connect.dart';
import 'stress_screen.dart'; // Import the stress screen
import 'gpa_screen.dart'; // Import the GPA screen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      drawer: DrawerWidget(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => HealthApp()),
          );
        },
      ),


      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🎓 Academic Dashboard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.search, color: Colors.black54),
                      SizedBox(width: 15),
                      Icon(Icons.notifications_outlined, color: Colors.black54),
                      SizedBox(width: 15),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.deepPurple,
                        child:
                        Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Greeting
              const Text('Welcome back,',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              const Text(
                'Mashood Farid👋',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'Stay on top of your academic and mental well-being ✨',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),

              const SizedBox(height: 30),

              // Main Card
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF8746E), Color(0xFFFCB69F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Left Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Stress & GPA\nPrediction',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Analyze your wellness and academic scores',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Image.asset('assets/images/3.png', height: 150),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  predictionCard(
                    title: 'Stress\nPrediction',
                    icon: Icons.self_improvement,
                    color: Colors.redAccent,
                    description: 'Monitor your mental health',
                    onTap: () {
                      // Navigate to Stress Screen when tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StressScreen()),
                      );
                    },
                  ),
                  predictionCard(
                    title: 'GPA\nPrediction',
                    icon: Icons.bar_chart,
                    color: Colors.green,
                    description: 'Forecast your performance',
                    onTap: () {
                      // Navigate to GPA Screen when tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GPAScreen()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Quote
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '"Small habits lead to big changes. Keep going!" 💡',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    color: Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                'Recent Predictions 📊',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Stress Chart
              chartCard(
                title: 'Stress Levels',
                data: [3, 4.5, 2.5, 4, 3, 4.2],
                color: Colors.redAccent,
              ),

              const SizedBox(height: 25),

              // GPA Chart
              chartCard(
                title: 'GPA Trends',
                data: [2.8, 3.0, 3.2, 3.5, 3.3, 3.6],
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget predictionCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required VoidCallback onTap, // Add onTap as parameter
  }) {
    return GestureDetector(
      onTap: onTap, // Handle the tap
      child: Container(
        width: (MediaQuery.of(context).size.width - 60) / 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget chartCard({
    required String title,
    required List<double> data,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 0.5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 0.5,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'Week ${value.toInt() + 1}',
                            style: const TextStyle(fontSize: 10),
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
                        color: Colors.grey.withOpacity(0.3), width: 1),
                  ),
                  minX: 0,
                  maxX: data.length.toDouble() - 1,
                  minY: data.reduce((a, b) => a < b ? a : b) - 0.5,
                  maxY: data.reduce((a, b) => a > b ? a : b) + 0.5,
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      spots: List.generate(
                        data.length,
                            (i) => FlSpot(i.toDouble(), data[i]),
                      ),
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.2),
                      ),
                      color: color,
                      barWidth: 3,
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
