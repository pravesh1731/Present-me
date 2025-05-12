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
              const PopupMenuItem<String>(
                value: 'profile',
                child: Text('Profile'),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem<String>(
                value: 'help',
                child: Text('Help'),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: Text('About Us'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
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


            // 🔁 Real-time student name and date container
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
                  margin: const EdgeInsets.only(top: 32, left: 32, right: 32, bottom: 16),
                  padding: EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text("Welcome $name",
                          style: TextStyle(fontSize: 18, color: Colors.lightBlue)),
                      Text(formattedDate, style: TextStyle(fontSize: 18)),
                    ],
                  ),
                );
              },
            ),

            // 🔳 Options Grid
            Container(
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      buildOptionCard(
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
                                return SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                      ),
                      buildOptionCard(
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
                                return SlideTransition(
                                  position: offsetAnimation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      buildOptionCard(
                        icon: FontAwesomeIcons.noteSticky,
                        label: 'Notes',
                        onTap: () {},
                      ),
                      buildOptionCard(
                        icon: FontAwesomeIcons.bookOpen,
                        label: 'Notice',
                        onTap: () {},
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      buildOptionCard(
                        icon: Icons.score,
                        label: 'Score',
                        onTap: () {},
                      ),
                      buildOptionCard(
                        icon: Icons.quiz,
                        label: 'Doubts',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildOptionCard({required IconData icon, required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 180,
      width: 190,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.only(top: 24, bottom: 24, left: 8, right: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            IconButton(
              onPressed: onTap,
              icon: Icon(icon, color: Colors.blue, size: 40),
            ),
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
