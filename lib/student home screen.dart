import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:present_me_flutter/joined%20class.dart';
import 'package:present_me_flutter/mark%20attendance%20student.dart';
import 'package:present_me_flutter/student%20profile.dart';

class studentHome extends StatelessWidget {
  final String formattedDate = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Present-Me', style: TextStyle(fontSize: 24, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff0BCCEB), Color(0xff0A80F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_outlined, color: Colors.white),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 500),
                    pageBuilder: (_, __, ___) => student_Profile(),
                    transitionsBuilder: (_, animation, __, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.linearToEaseOut;
                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);
                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(value: 'profile', child: Text('Profile')),
              const PopupMenuItem<String>(value: 'settings', child: Text('Settings')),
              const PopupMenuItem<String>(value: 'help', child: Text('Help')),
              const PopupMenuItem<String>(value: 'about', child: Text('About Us')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const CircularProgressIndicator();
                }

                final studentData = snapshot.data!.data() as Map<String, dynamic>;
                final photoUrl = studentData['photoUrl'] ?? null;

                return Align(
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.blueAccent,
                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : const AssetImage("assets/image/teacher.png") as ImageProvider,
                  ),
                );
              },
            ),

            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const CircularProgressIndicator();
                }

                final studentData = snapshot.data!.data() as Map<String, dynamic>;
                final name = studentData['name'] ?? 'Student';

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text("Welcome $name", style: const TextStyle(fontSize: 18, color: Colors.lightBlue)),
                      Text(formattedDate, style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  buildOptionCard(
                    context: context,
                    icon: Icons.check_circle_outline,
                    label: 'Mark Attendance',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: Duration(milliseconds: 500),
                          pageBuilder: (_, __, ___) => mark_Attendance_Student(),
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
                  ),
                  buildOptionCard(
                    context: context,
                    icon: FontAwesomeIcons.plusCircle,
                    label: 'Classes',
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: Duration(milliseconds: 500),
                          pageBuilder: (_, __, ___) => joined_Class(),
                          transitionsBuilder: (_, animation, __, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.linearToEaseOut;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);
                            return SlideTransition(position: offsetAnimation, child: child);
                          },
                        ),
                      );
                    },
                  ),
                  buildOptionCard(
                    context: context,
                    icon: FontAwesomeIcons.noteSticky,
                    label: 'Notes',
                    onTap: () {},
                  ),
                  buildOptionCard(
                    context: context,
                    icon: FontAwesomeIcons.bookOpen,
                    label: 'Notice',
                    onTap: () {},
                  ),
                  buildOptionCard(
                    context: context,
                    icon: Icons.score,
                    label: 'Score',
                    onTap: () {},
                  ),
                  buildOptionCard(
                    context: context,
                    icon: Icons.quiz,
                    label: 'Doubts',
                    onTap: () {},
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth / 2) - 24;

    return SizedBox(
      width: cardWidth,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onTap,
              icon: Icon(icon, color: Colors.blue, size: 40),
            ),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
