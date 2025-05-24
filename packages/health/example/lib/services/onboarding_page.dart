import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnboardingPage extends StatelessWidget {
  final String animationUrl;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.animationUrl,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16.0), // Add horizontal padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Use a SizedBox with a fixed height for the animation
          SizedBox(
            height: MediaQuery.of(context).size.height *
                0.4, // Adjust the height as needed (e.g., 40% of screen height)
            child: Lottie.network(
              animationUrl,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(
              height: 16), // Reduced spacing between animation and title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Text(
              title,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(
              height: 8), // Reduced spacing between title and description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 23),
            child: Text(
              description,
              textAlign: TextAlign.start,
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String animationUrl;
  final String title;
  final String description;

  OnboardingData({
    required this.animationUrl,
    required this.title,
    required this.description,
  });
}
