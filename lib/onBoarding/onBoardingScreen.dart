import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:present_me_flutter/introScreen.dart';
import 'package:present_me_flutter/onBoarding/widget/widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dots_indicator/dots_indicator.dart';

import '../Provider/onBoarding_Notifier.dart';

class onBoardingScreen extends ConsumerStatefulWidget {
  const onBoardingScreen({super.key});

  @override
  ConsumerState<onBoardingScreen> createState() => _onBoardingScreenState();
}

class _onBoardingScreenState extends ConsumerState<onBoardingScreen> {
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _pages = const [
    {
      'icon': Icons.check_circle_outline,
      'title': 'Welcome to Present-Me',
      'description': 'Your smart attendance companion for seamless classroom management',
      'gradientColors': [Color(0xFF06B6D4), Color(0xFF2563EB)],
    },
    {
      'icon': Icons.check_circle_outline,
      'title': 'Smart Attendance',
      'description': 'Mark attendance with manual, smart, and video recognition methods',
      'gradientColors': [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    },
    {
      'icon': Icons.analytics_outlined,
      'title': 'Track Progress',
      'description': 'Monitor your academic journey with detailed insights and analytics',
      'gradientColors': [Color(0xFF10B981), Color(0xFF3B82F6)],
    },
    {
      'icon': Icons.analytics_outlined,
      'title': 'Build for everyone',
      'description': 'Perfect for both teachers and students with dedicated features',
      'gradientColors': [Color(0xFF10B981), Color(0xFF3B82F6)],
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => introscreen()),
    );
  }

  void _onNext() {
    final currentPage = ref.read(currentPageProvider);

    if (currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(currentPageProvider);
    final currentGradient = _pages[currentPage]['gradientColors'] as List<Color>;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: currentGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Padding(
                padding: const EdgeInsets.only(right: 20, top: 10),
                child: Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) =>
                      ref.read(currentPageProvider.notifier).setPage(page),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    final gradient = page['gradientColors'] as List<Color>;
                    return buildPage(
                      icon: page['icon'],
                      title: page['title'],
                      description: page['description'],
                      iconBg: gradient.first,
                    );
                  },
                ),
              ),

              // Dots Indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: DotsIndicator(
                  dotsCount: _pages.length,
                  position: currentPage,
                  decorator: DotsDecorator(
                    color: Colors.white.withOpacity(0.5),
                    activeColor: Colors.white,
                    size: const Size.square(8),
                    activeSize: const Size(24, 8),
                    activeShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              // Next button
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 30),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xff0A80F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // Present-Me branding
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Present-Me',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
  