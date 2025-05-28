import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'joined class.dart';
import 'mark attendance student.dart';
import 'student profile.dart';

class studentHome extends StatelessWidget {
  final String formattedDate = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
                      return SlideTransition(position: offsetAnimation, child: child);
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
      body: currentUser == null
          ? Center(child: Text("User not logged in"))
          : StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: CircularProgressIndicator());
          }

          final studentData = snapshot.data!.data() as Map<String, dynamic>;
          final name = studentData['name'] ?? 'Student';
          final photoUrl = studentData['photoUrl'];

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.03),
                  Align(
                    alignment: Alignment.center,
                    child: CircleAvatar(
                      radius: screenWidth * 0.12,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: photoUrl != null && photoUrl.toString().isNotEmpty
                          ? NetworkImage(photoUrl)
                          : AssetImage("assets/image/teacher.png") as ImageProvider,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: screenHeight * 0.01),
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text("Welcome $name",
                            style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                color: Colors.lightBlue)),
                        SizedBox(height: 8),
                        Text(formattedDate,
                            style: TextStyle(fontSize: screenWidth * 0.045)),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  LayoutBuilder(builder: (context, constraints) {
                    return Column(
                      children: [
                        buildResponsiveRow(context, screenWidth, [
                          buildTile(
                            icon: Icons.check_circle_outline,
                            label: 'Mark Attendance',
                            onTap: () => navigate(context, mark_Attendance_Student()),
                          ),
                          buildTile(
                            icon: FontAwesomeIcons.plusCircle,
                            label: 'Classes',
                            onTap: () => navigate(context, joined_Class()),
                            isFontAwesome: true,
                          ),
                        ]),
                        buildResponsiveRow(context, screenWidth, [
                          buildTile(
                            icon: FontAwesomeIcons.noteSticky,
                            label: 'Notes',
                            onTap: () {},
                            isFontAwesome: true,
                          ),
                          buildTile(
                            icon: FontAwesomeIcons.bookOpen,
                            label: 'Notice',
                            onTap: () {},
                            isFontAwesome: true,
                          ),
                        ]),
                        buildResponsiveRow(context, screenWidth, [
                          buildTile(
                            icon: Icons.score,
                            label: 'Score',
                            onTap: () {},
                          ),
                          buildTile(
                            icon: Icons.quiz,
                            label: 'Doubts',
                            onTap: () {},
                          ),
                        ]),
                      ],
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildResponsiveRow(BuildContext context, double screenWidth, List<Widget> tiles) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: tiles.map((tile) {
        return Expanded(child: tile);
      }).toList(),
    );
  }

  Widget buildTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isFontAwesome = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onTap,
                icon: isFontAwesome
                    ? FaIcon(icon, color: Colors.blue, size: 40)
                    : Icon(icon, color: Colors.blue, size: 45),
              ),
              SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  void navigate(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => page,
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
  }
}
