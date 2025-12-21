import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:present_me_flutter/IntroScreen/introScreen.dart';
import 'package:present_me_flutter/onBoarding/onBoardingScreen.dart';
import 'package:present_me_flutter/Student Screens/student home screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class splashScreen extends StatefulWidget {
  @override
  State<splashScreen> createState() => _splashScreenState();
}

class _splashScreenState extends State<splashScreen> {
  final box = GetStorage(); // ⭐ GetStorage instance

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

    // 2) Check if we have a saved token (from login)
    final String? token = box.read<String>('token');

    if (token != null) {
      // ⭐ User is considered logged-in → go directly to studentHome
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => studentHome()),
      );
    } else {
      // No saved login → show onboarding or intro based on preference
      if (!hasSeenOnboarding) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const onBoardingScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => introscreen()),
        );
      }
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
