import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:present_me_flutter/IntroScreen/introScreen.dart';
import 'package:present_me_flutter/onBoarding/onBoardingScreen.dart';
import 'package:present_me_flutter/Student%20Screens/student%20home%20screen.dart';
import 'package:present_me_flutter/Teacher%20Screens/teacher%20home%20screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class splashScreen extends StatefulWidget{
  @override
  State<splashScreen> createState() => _splashScreenState();
}

class _splashScreenState extends State<splashScreen> {
  @override

  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Check if user has seen onboarding
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    
    // Check if user is logged in with Firebase Auth
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is logged in, check their role
      final role = await _getUserRole(user.uid);

      if (role == 'teacher') {
        // Navigate to teacher home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => teacherHome()),
        );
      } else if (role == 'student') {
        // Navigate to student home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => studentHome()),
        );
      } else {
        // Role not found, sign out and show login
        await FirebaseAuth.instance.signOut();
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
    } else {
      // User is not logged in - show onboarding or intro based on preference
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

  Future<String?> _getUserRole(String uid) async {
    // Check in 'teachers' collection
    final teacherDoc = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(uid)
        .get();
    if (teacherDoc.exists) return 'teacher';

    // Check in 'students' collection
    final studentDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .get();
    if (studentDoc.exists) return 'student';

    return null; // not found in either
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [
                Color(0xff0BCCEB), Color(0xff0A80F5)],
            begin: FractionalOffset(1.0, 0.0),
            end: FractionalOffset(0.0, 1.0)
          )
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
                          child: Image.asset("assets/image/logo.png")),
                      SizedBox(
                        width: 230,
                          child: Text("Present-Me", style: TextStyle(
                              fontSize: 36 ,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                          )),
                      SizedBox(height: 10,),
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ],

                  ),
            ),
          ),
            Positioned(
              bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Text('Developed by Loading...' ,
                    style: TextStyle(color: Colors.white),),
                ))
      ],
        )
      )
    );


  }
}