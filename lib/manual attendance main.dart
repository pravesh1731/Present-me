import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'button.dart';

class ManualAttendanceMain extends StatefulWidget {
  final String className;
  final String classCode;

  ManualAttendanceMain({required this.className, required this.classCode});

  @override
  _ManualAttendanceMainState createState() => _ManualAttendanceMainState();
}

class _ManualAttendanceMainState extends State<ManualAttendanceMain> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool isAttendanceFinalized = false;
  Map<String, String> savedStatuses = {};

  Stream<List<Map<String, dynamic>>> _getClassStudentsStream() {
    return FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classCode)
        .snapshots()
        .asyncMap((snapshot) async {
      if (!snapshot.exists) return [];

      final classData = snapshot.data() ?? {};
      final studentsList = List<String>.from(classData['students'] ?? []);
      if (studentsList.isEmpty) return [];

      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('Attendance')
          .doc(widget.classCode)
          .collection(dateKey())
          .get();

      final savedData = Map.fromEntries(attendanceSnapshot.docs.map(
              (doc) => MapEntry(doc.id, (doc.data()['status'] ?? 'None') as String)));

      savedStatuses = savedData;

      final studentDocs = await FirebaseFirestore.instance
          .collection('students')
          .where('uid', whereIn: studentsList)
          .get();

      final List<Map<String, dynamic>> students = [];
      for (var studentDoc in studentDocs.docs) {
        final studentData = studentDoc.data();
        final uid = studentDoc.id;
        students.add({
          'name': studentData['name'] ?? 'Unknown Name',
          'roll': studentData['roll'] ?? 'Unknown Roll No',
          'uid': uid,
          'status': savedData[uid] ?? 'None',
          'photoUrl': studentData['photoUrl'] ?? '',
        });
      }

      // 🔽 Sort students by roll number ascending
      students.sort((a, b) {
        final rollA = int.tryParse(a['roll'].toString()) ?? 0;
        final rollB = int.tryParse(b['roll'].toString()) ?? 0;
        return rollA.compareTo(rollB);
      });

      return students;
    });
  }


  String dateKey() {
    final dateFormat = DateFormat('yyyyMMdd');
    return dateFormat.format(DateTime.now());
  }

  Future<void> saveAttendance(String studentUid, String status) async {
    final classCodeRef = FirebaseFirestore.instance
        .collection('Attendance')
        .doc(widget.classCode)
        .collection(dateKey())
        .doc(studentUid);

    await classCodeRef.set({'status': status}).then((_) async {
      setState(() {
        savedStatuses[studentUid] = status;
      });

      final dateListRef = FirebaseFirestore.instance
          .collection("Attendance")
          .doc(widget.classCode)
          .collection("DateList")
          .doc("AllDates");

      final dateSnapshot = await dateListRef.get();
      final existingDates = dateSnapshot.data()?['dates'] as List<dynamic>? ?? [];
      if (!existingDates.contains(dateKey())) {
        await dateListRef.set({
          'dates': [...existingDates, dateKey()]
        });
      }
    }).catchError((error) {
      print("Error saving attendance: $error");
    });
  }

  Future<void> finalizeAttendance(List<Map<String, dynamic>> students) async {
    final allMarked = students.every((student) =>
    student['status'] == 'Present' || student['status'] == 'Absent');

    if (!allMarked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mark attendance for all students.')),
      );
      return;
    }

    final classCodeRef = FirebaseFirestore.instance
        .collection('Attendance')
        .doc(widget.classCode)
        .collection(dateKey())
        .doc('finalStatus');

    await classCodeRef.set({'finalized': true}).then((_) {
      setState(() {
        isAttendanceFinalized = true;
      });
    }).catchError((error) {
      print("Error finalizing attendance: $error");
    });
  }

  void showConfirmationDialog(List<Map<String, dynamic>> students) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Finalization'),
          content:
          Text('Are you sure you want to finalize today\'s attendance?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                finalizeAttendance(students);
                Navigator.pop(context);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('Attendance')
        .doc(widget.classCode)
        .collection(dateKey())
        .doc('finalStatus')
        .get()
        .then((doc) {
      if (doc.exists && doc.data()?['finalized'] == true) {
        setState(() {
          isAttendanceFinalized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('Class : ${widget.className}',
                style: TextStyle(fontSize: 22, color: Colors.white)),
            Text('Code : ${widget.classCode}',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ],
        ),
        flexibleSpace: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff0BCCEB), Color(0xff0A80F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getClassStudentsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No students found for this class."));
                  }

                  final students = snapshot.data!;

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      Color containerColor;

                      if (student['status'] == 'Absent') {
                        containerColor = Colors.red.shade100;
                      } else if (student['status'] == 'Present') {
                        containerColor = Colors.green.shade100;
                      } else {
                        containerColor = Colors.white;
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: containerColor,
                          border: Border.all(color: Colors.blue, width: 3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: student['photoUrl'] != ''
                                  ? NetworkImage(student['photoUrl'])
                                  : AssetImage('assets/image/teacher.png') as ImageProvider,
                            ),


                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(student['name']!,
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text('Roll No: ${student['roll']}'),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                ElevatedButton(
                                  onPressed: isAttendanceFinalized
                                      ? null
                                      : () async {
                                    setState(() {
                                      student['status'] = 'Present';
                                    });
                                    await saveAttendance(
                                        student['uid']!, 'Present');
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade400),
                                  child: Text('Present'),
                                ),
                                SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: isAttendanceFinalized
                                      ? null
                                      : () async {
                                    setState(() {
                                      student['status'] = 'Absent';
                                    });
                                    await saveAttendance(
                                        student['uid']!, 'Absent');
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade400),
                                  child: Text('Absent'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 8),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getClassStudentsStream(),
          builder: (context, snapshot) {
            final students = snapshot.data ?? [];
            return Button(
              text: isAttendanceFinalized ? "SUBMITTED" : "FINAL SUBMIT",
              onPressed: isAttendanceFinalized
                  ? null
                  : () => showConfirmationDialog(students),
            );
          },
        ),
      ),
    );
  }
}