import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../services/onboarding_page.dart';

final List<OnboardingData> onboardingPages = [
  OnboardingData(
    animationUrl: AppConstants.onboardingAnimationUrl1,
    title: 'Let\'s get started',
    description:
        'Take control of your academic journey and well-being! EduCare helps you predict stress levels and academic performance, providing personalized tips to succeed in both studies and life. ',
  ),
  OnboardingData(
    animationUrl: AppConstants.onboardingAnimationUrl2,
    title: 'Predict Stress & GPA',
    description:
        'Input your daily habits like study hours, sleep, and activity levels. Our smart algorithms will predict your stress levels and GPA, helping you stay on track.',
  ),
  OnboardingData(
    animationUrl: AppConstants.onboardingAnimationUrl3,
    title: 'Get Personalized Insights',
    description:
        'Receive actionable recommendations to manage stress, improve academic performance, and maintain a healthy lifestyle. Start your journey to a balanced and successful student life today!',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool isLastPage = false;

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'hasCompletedOnboarding', true); // Set onboarding as completed
    Navigator.pushReplacementNamed(context, '/login'); // Navigate to login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  isLastPage = index == onboardingPages.length - 1;
                });
              },
              itemCount: onboardingPages.length,
              itemBuilder: (context, index) {
                final pageData = onboardingPages[index];
                return OnboardingPage(
                  animationUrl: pageData.animationUrl,
                  title: pageData.title,
                  description: pageData.description,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 35.0),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: onboardingPages.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: Colors.black,
                      dotColor: Colors.grey,
                      dotHeight: 10,
                      dotWidth: 15,
                      spacing: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20.0, bottom: 10),
                child: TextButton(
                  onPressed: _completeOnboarding, // Skip to login
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0, right: 25),
                child: isLastPage
                    ? ElevatedButton(
                        onPressed: _completeOnboarding, // Complete onboarding
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Next',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.arrow_forward,
                                color: Colors.white, size: 20),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
