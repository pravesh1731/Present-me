import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:present_me_flutter/views/IntroScreen/introScreen.dart';
import 'package:present_me_flutter/views/Student%20Screens/student%20home%20screen.dart';
import 'package:present_me_flutter/views/Teacher%20Screens/teacher%20home%20screen.dart';
import 'package:present_me_flutter/views/onBoarding/onBoardingScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class splashScreen extends StatefulWidget {
  @override
  State<splashScreen> createState() => _splashScreenState();
}

class _splashScreenState extends State<splashScreen> {
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    // Small delay for splash animation
    await Future.delayed(const Duration(seconds: 2));

    // 1) Check onboarding status
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    // 2) Check if we have a saved token (from login) and whether it's a teacher or student
    final String? token = box.read<String>('token');
    final dynamic storedTeacher = box.read('teacher');
    final dynamic storedStudent = box.read('student');
    // Preferred stored role (set on login/logout) - should be 'teacher' or 'student'
    final String? storedRole = box.read<String>('role');

    // Safety: ensure widget still in tree before navigating
    if (!mounted) return;

    if (token != null) {
      // If a role was explicitly saved on login, honor it (most reliable)
      if (storedRole != null) {
        if (storedRole == 'teacher') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => teacherHome()));
          return;
        }
        if (storedRole == 'student') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => studentHome()));
          return;
        }
      }

      // Fallback: if role wasn't saved, use available profile objects.
      // Prefer recent explicit student profile over stale teacher profile if both present.
      if (storedStudent != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => studentHome()));
        return;
      }

      if (storedTeacher != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => teacherHome()));
        return;
      }

      // If token exists but no stored profile, try to fall back to intro so user can be re-validated
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => introscreen()),
      );
      return;
    }

    // No saved login → show onboarding or intro based on preference
    if (!hasSeenOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnBoardingScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => introscreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff0BCCEB), Color(0xff0A80F5)],
            begin: FractionalOffset(1.0, 0.0),
            end: FractionalOffset(0.0, 1.0),
          ),
        ),
        height: double.infinity,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned(
              left: 10,
              right: 0,
              top: 0,
              bottom: 90,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 230,
                      height: 230,
                      child: Image.asset("assets/image/logo.png"),
                    ),
                    const SizedBox(
                      width: 230,
                      child: Text(
                        "Present-Me",
                        style: TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Developed by Loading...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
