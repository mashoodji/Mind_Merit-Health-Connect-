import 'package:flutter/material.dart';
import 'package:health_example/screens/feature_screen/study_timer.dart';

import '../home_screen.dart';
import 'medals_screen.dart';

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // App Bar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          ),
        ),
        title: const Text(
          'Study Tools',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      // Body
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6E48AA), Color(0xFF9D50BB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'SMART TOOLS TO MAKE STUDYING EASIER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 0),
                    Text(
                      'Stay on track and reach your goals',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Features Grid
              Padding(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.76,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const StudyTimerPage()),
                            );
                          },
                          child: _buildFeatureCard(
                            icon: Icons.timer_outlined,
                            imagePath: 'assets/images/timer.png',
                            title: 'Smart Timer',
                            description: 'Track study sessions quickly and easily with our intuitive timer.',
                            iconColor: Colors.blue.shade700,
                            cardColor: Colors.blue.shade50,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MedalsScreen()),
                            );
                          },
                          child: _buildFeatureCard(
                            icon: Icons.emoji_events_outlined,
                            imagePath: 'assets/images/medal.png',
                            title: 'Motivating Medals',
                            description: 'Celebrate learning successes with gold, silver and bronze medals.',
                            iconColor: Colors.amber.shade700,
                            cardColor: Colors.amber.shade50,
                          ),
                        ),
                        _buildFeatureCard(
                          icon: Icons.local_fire_department,
                          imagePath: 'assets/images/streak.png',
                          title: 'Streaks',
                          description: 'Maintain your learning streak by practicing every day.',
                          iconColor: Colors.red.shade400,
                          cardColor: Colors.red.shade50,
                        ),
                        _buildFeatureCard(
                          icon: Icons.bar_chart_rounded,
                          imagePath: 'assets/images/stats.png',
                          title: 'Satisfying Statistics',
                          description: 'Visualize progress with beautiful charts and graphs.',
                          iconColor: Colors.purple.shade700,
                          cardColor: Colors.purple.shade50,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String imagePath,
    required String title,
    required String description,
    required Color iconColor,
    required Color cardColor,
  }) {
    return HoverCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon/Image Container
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Image.asset(
                  imagePath,
                  width: 32,
                  height: 32,
                  color: iconColor,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    icon,
                    size: 32,
                    color: iconColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// HoverCard Widget to handle scaling on hover (for web/desktop)
class HoverCard extends StatefulWidget {
  final Widget child;

  const HoverCard({Key? key, required this.child}) : super(key: key);

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
