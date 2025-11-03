import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:present_me_flutter/track%20attendace%20student%20detais.dart';

class track_Student_Attendance_List extends StatelessWidget {
  final currentUser = FirebaseAuth.instance.currentUser;

  Stream<List<Map<String, String>>> _getJoinedClassesStream() {
    return FirebaseFirestore.instance.collection('classes').snapshots().map((snapshot) {
      final userUid = currentUser?.uid;
      if (userUid == null) return [];

      final List<Map<String, String>> userClasses = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final students = List<String>.from(data['students'] ?? []);
        if (students.contains(userUid)) {
          final title = data['name'] ?? 'Untitled Class';
          final code = doc.id;
          userClasses.add({'name': title, 'code': code});
        }
      }

      return userClasses;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Classes', style: TextStyle(fontSize: 22, color: Colors.white)),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<Map<String, String>>>(
          stream: _getJoinedClassesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final classes = snapshot.data ?? [];

            if (classes.isEmpty) {
              return Center(child: Text("You haven't joined any classes yet."));
            }

            return ListView.builder(
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final classItem = classes[index];
                return InkWell(
                  onTap: () {
                    // Pass class name and class code to the next screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrackStudentAttendanceDetails(
                          className: classItem['name']!,
                          classCode: classItem['code']!,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classItem['name']!,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Class Code : ${classItem['code']}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        Icon(Icons.arrow_forward, color: Colors.blue, size: 28),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
