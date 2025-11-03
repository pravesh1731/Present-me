import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:present_me_flutter/student%20attendance%20Details.dart';

class TrackStudentListClasses extends StatelessWidget {
  final String classCode;

  TrackStudentListClasses({required this.classCode});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchStudentsInClass() async {
    final classDoc = await _firestore.collection('classes').doc(classCode).get();

    if (!classDoc.exists || classDoc['students'] == null) return [];

    List<dynamic> studentUIDs = classDoc['students'];

    if (studentUIDs.isEmpty) return [];

    // Batch get student documents
    final List<Map<String, dynamic>> studentData = [];

    for (String uid in studentUIDs) {
      final studentDoc = await _firestore.collection('students').doc(uid).get();
      if (studentDoc.exists) {
        final data = studentDoc.data()!;
        studentData.add({
          'uid': uid,
          'name': data['name'] ?? 'No Name',
          'roll': data['roll'] ?? 'Unknown',
          'profile': data['photoUrl'] ?? null,
        });
      }
    }

    return studentData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('Class Students', style: TextStyle(fontSize: 22, color: Colors.white)),
            Text('Code: $classCode', style: TextStyle(fontSize: 16, color: Colors.white)),
          ],
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchStudentsInClass(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return Center(child: Text('Error fetching students'));

            final students = snapshot.data ?? [];

            if (students.isEmpty) {
              return Center(child: Text('No students found in this class'));
            }

            return ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: Duration(milliseconds: 500),
                        pageBuilder: (_, __, ___) => StudentAttendanceDetails(
                          studentUID: student['uid'],
                          classCode: classCode,
                          studentName: student['name'],
                          rollNo: student['roll'],
                          profileImage: student['profile'] ?? '',
                        ),
                        transitionsBuilder: (_, animation, __, child) {
                          final tween = Tween(begin: Offset(1.0, 0.0), end: Offset.zero)
                              .chain(CurveTween(curve: Curves.easeInOutBack));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: student['profile'] != null
                              ? NetworkImage(student['profile'])
                              : null,
                          backgroundColor: Colors.blue.shade100,
                          child: student['profile'] == null
                              ? Icon(Icons.person, color: Colors.blue)
                              : null,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(student['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Roll No: ${student['roll']}'),
                            ],
                          ),
                        ),
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
