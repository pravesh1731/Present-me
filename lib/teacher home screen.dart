import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'button.dart';
import 'create class.dart';
import 'download.dart';
import 'records.dart';
import 'take attendance.dart';
import 'teacher profile.dart';

class teacherHome extends StatelessWidget {
  final String formattedDate = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

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
                    pageBuilder: (_, __, ___) => teacher_Profile(),
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
            .collection('teachers')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final teacherData = snapshot.data!.data() as Map<String, dynamic>;
          final teacherName = teacherData['name'] ?? 'Teacher';

          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: teacherData['photoUrl'] != null && teacherData['photoUrl'].toString().isNotEmpty
                        ? NetworkImage(teacherData['photoUrl'])
                        : AssetImage("assets/image/teacher.png") as ImageProvider,
                  ),
                ),

                Container(
                  margin: const EdgeInsets.only(top: 32, left: 32, right: 32, bottom: 16),
                  padding: EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text("Welcome $teacherName", style: TextStyle(fontSize: 18, color: Colors.lightBlue)),
                      Text(formattedDate, style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),

                // === Your Buttons UI ===
                Container(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          buildTile(
                            icon: Icons.check_circle_outline,
                            label: 'Take Attendance',
                            onTap: () => navigate(context, takeAttendnace()),
                          ),
                          buildTile(
                            icon: FontAwesomeIcons.book,
                            label: 'Records',
                            onTap: () => navigate(context, record()),
                            isFontAwesome: true,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          buildTile(
                            icon: FontAwesomeIcons.noteSticky,
                            label: 'Notes',
                            onTap: () {},
                            isFontAwesome: true,
                          ),
                          buildTile(
                            icon: Icons.add_circle_outline,
                            label: 'Create Class',
                            onTap: () => navigate(context, CreateClass()),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          buildTile(
                            icon: FontAwesomeIcons.download,
                            label: 'Download',
                            onTap: () => navigate(context, DownloadAttendancePage()),
                            isFontAwesome: true,
                          ),
                          buildTile(
                            icon: FontAwesomeIcons.bookOpen,
                            label: 'Notice',
                            onTap: () {},
                            isFontAwesome: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildTile({required IconData icon, required String label, required VoidCallback onTap, bool isFontAwesome = false}) {
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
              icon: isFontAwesome
                  ? FaIcon(icon, color: Colors.blue, size: 40)
                  : Icon(icon, color: Colors.blue, size: 45),
            ),
            Text(label, style: TextStyle(fontSize: 16)),
          ],
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
