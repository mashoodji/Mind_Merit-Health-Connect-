import 'package:flutter/material.dart';

class MedalsScreen extends StatelessWidget {
  const MedalsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medals"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Medals Are Awards",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Medals are awards for particularly good study days. In Athenify, there are three medals: Gold, Silver, and Bronze. By default, you receive medals for the following study times:",
            ),
            const SizedBox(height: 16),
            _medalRow("Gold Medal", "More than 5 hours (300 minutes)", "assets/images/medals/gold.jpeg"),
            const SizedBox(height: 12),
            _medalRow("Silver Medal", "More than 4 hours (240 minutes)", "assets/images/medals/silver.jpeg"),
            const SizedBox(height: 12),
            _medalRow("Bronze Medal", "More than 3 hours (180 minutes)", "assets/images/medals/bronze.jpeg"),
            const SizedBox(height: 24),

            const Divider(),

            const Text(
              "Custom Medals",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "In Athenify, you can freely decide the amount of study time required to earn medals. In the settings, you can change the values for all three medals at any time.",
            ),
            const SizedBox(height: 16),
            const Text(
              "• Don't set goals too low. Medals should only be earned when you can truly be satisfied with the study time.",
            ),
            const SizedBox(height: 8),
            const Text(
              "• Don't set goals too high. Otherwise, medals might become demotivating.",
            ),
            const SizedBox(height: 24),

            const Divider(),

            const Text(
              "The Art of Medals",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "The art lies in setting the values of the medals to a Goldilocks level. You'll need to experiment a bit, and that's completely fine! Eventually, you’ll find the right medal values for you.",
            ),
            const SizedBox(height: 12),
            const Text(
              "Once set, the medals will unleash their full power. Like an Olympian, you’ll collect medals. Everywhere in Athenify, you’ll see on which days you earned medals.",
            ),
            const SizedBox(height: 24),

            Center(
              child: Image.asset(
                "assets/medal_summary.png", // Placeholder image for art concept
                height: 180,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _medalRow(String title, String description, String assetPath) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          assetPath,
          width: 60,
          height: 60,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(description),
            ],
          ),
        ),
      ],
    );
  }
}
