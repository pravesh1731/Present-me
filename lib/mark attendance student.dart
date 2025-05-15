import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:present_me_flutter/mark%20attendnace%20student%20list.dart';
import 'package:present_me_flutter/mark%20smart%20attendance%20student.dart';

class mark_Attendance_Student extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mark Attendance',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff0BCCEB), Color(0xff0A80F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            // 🟦 Track Attendance Card
            buildAttendanceCard(
              context: context,
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 500),
                    pageBuilder: (_, __, ___) => track_Student_Attendance_List(),
                    transitionsBuilder: (_, animation, __, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOutBack;
                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);
                      return SlideTransition(position: offsetAnimation, child: child);
                    },
                  ),
                );
              },
              imagePath: "assets/image/track.jpg",
              title: 'Track Attendance',
              subtitle: 'Monitor your attendance',
              screenWidth: screenWidth,
            ),

            // 🟦 Smart Attendance Card
            buildAttendanceCard(
              context: context,
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 500),
                    pageBuilder: (_, __, ___) => mark_Smart_Attendance(),
                    transitionsBuilder: (_, animation, __, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOutBack;
                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);
                      return SlideTransition(position: offsetAnimation, child: child);
                    },
                  ),
                );
              },
              imagePath: "assets/image/smart-contracts.jpg",
              title: 'Smart Attendance',
              subtitle: 'Use Smart detection to mark attendance',
              screenWidth: screenWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAttendanceCard({
    required BuildContext context,
    required VoidCallback onTap,
    required String imagePath,
    required String title,
    required String subtitle,
    required double screenWidth,
  }) {
    final cardWidth = screenWidth * 0.9;
    final imageWidth = screenWidth * 0.25;
    final imageHeight = screenWidth * 0.3;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            SizedBox(
              width: imageWidth,
              height: imageHeight,
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
