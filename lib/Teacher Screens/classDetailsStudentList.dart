import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:present_me_flutter/Teacher%20Screens/student%20request%20list.dart';
import 'package:present_me_flutter/Teacher%20Screens/track%20attendance%20of%20specificStudent%20for%20Teacher.dart';

import 'dart:math';
import 'package:shimmer/shimmer.dart';

class classDetailsStudentList extends StatelessWidget {
    Future<double> _fetchAttendancePercentage(String classCode, String studentUID) async {
      final firestore = FirebaseFirestore.instance;
      final datesRef = firestore
          .collection('Attendance')
          .doc(classCode)
          .collection('DateList')
          .doc('AllDates');
      try {
        final snapshot = await datesRef.get();
        final dateList = List<String>.from(snapshot.get('dates') ?? []);
        if (dateList.isEmpty) return 0.0;
        int present = 0;
        for (var dateKey in dateList) {
          final recordSnapshot = await firestore
              .collection('Attendance')
              .doc(classCode)
              .collection(dateKey)
              .doc(studentUID)
              .get();
          String status;
          if (!recordSnapshot.exists) {
            status = "Absent";
          } else {
            status = recordSnapshot.data()?['status']?.toString() ?? "Absent";
          }
          if (status == 'Present') present++;
        }
        return dateList.isNotEmpty ? (present / dateList.length) * 100 : 0.0;
      } catch (e) {
        return 0.0;
      }
    }
  final String classCode;

  classDetailsStudentList({required this.classCode});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> _fetchClassDetails() async {
    final classDoc = await _firestore.collection('classes').doc(classCode).get();
    if (!classDoc.exists) return {};
    final data = classDoc.data()!;
    return {
      'name': data['name'] ?? '',
      'room': data['room'] ?? '',
      'startTime': data['startTime'] ?? '',
      'endTime': data['endTime'] ?? '',
      'days': data['days'] ?? [],
      'students': data['students'] ?? [],
      'attendance': 94, // demo, replace with actual if available
      'classes': 45, // demo, replace with actual if available
    };
  }

  Future<List<Map<String, dynamic>>> _fetchStudents(List<dynamic> studentUIDs) async {
    if (studentUIDs.isEmpty) return [];
    final List<Map<String, dynamic>> studentData = [];
    for (String uid in studentUIDs) {
      final studentDoc = await _firestore.collection('students').doc(uid).get();
      if (studentDoc.exists) {
        final data = studentDoc.data()!;
        studentData.add({
          'uid': uid,
          'name': data['name'] ?? 'No Name',
          'email': data['email'] ?? '',
          'roll': data['roll'] ?? 'Unknown',
          'profile': data['photoUrl'] ?? null,
        });
      }
    }
    return studentData;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0].substring(0, min(2, parts[0].length)).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color _attendanceColor(int percent) {
    if (percent > 90) return Color(0xFF10B981); // green
    if (percent >= 76) return Color(0xFFF97316); // orange
    if (percent >= 66) return Color(0xFFFFD600); // yellow
    return Color(0xFFEF4444); // red
  }

  @override
  Widget build(BuildContext context) {
    // Static header and summary cards
    Widget headerSection({String className = '', String room = ''}) => StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('classes').doc(classCode).snapshots(),
      builder: (context, snapshot) {
        int requestCount = 0;
        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final joinRequests = data['joinRequests'] ?? [];
          requestCount = joinRequests is List ? joinRequests.length : 0;
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 44, bottom: 24, left: 24, right: 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                className.isNotEmpty ? className : 'Class',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                room.isNotEmpty ? 'Room $room' : 'Room --',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentRequestList(classCode: classCode),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '$requestCount',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    Widget summaryCards({int students = 0, int attendance = 94, int classes = 45}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _summaryCard(Icons.people_alt_rounded, students.toString(), 'Students', Colors.blue),
          _summaryCard(Icons.check_circle_rounded, '$attendance%', 'Attendance', Color(0xFF10B981)),
          _summaryCard(Icons.calendar_month_rounded, '$classes', 'Classes', Colors.purple),
        ],
      ),
    );

    Widget shimmerClassInfo() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Class Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 10),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: double.infinity,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );

    Widget shimmerStudentList() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enrolled Students (--)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 10),
          Column(
            children: List.generate(4, (i) => Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchClassDetails(),
        builder: (context, classSnapshot) {
          final loadingClass = classSnapshot.connectionState == ConnectionState.waiting || classSnapshot.data == null;
          final classData = classSnapshot.data ?? {};
          final studentsUIDs = classData['students'] ?? [];
          final className = classData['name'] ?? '';
          final room = classData['room'] ?? '';
          final startTime = classData['startTime'] ?? '';
          final endTime = classData['endTime'] ?? '';
          final days = classData['days'] ?? [];
          final attendance = classData['attendance'] ?? 94;
          final classes = classData['classes'] ?? 45;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headerSection(className: className, room: room),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18),
                        summaryCards(
                          students: loadingClass ? 0 : (studentsUIDs.length),
                          attendance: attendance,
                          classes: classes,
                        ),
                        const SizedBox(height: 18),
                        if (loadingClass)
                          shimmerClassInfo()
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Class Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, color: Color(0xFF06B6D4), size: 22),
                                          const SizedBox(width: 10),
                                          Text('Time', style: TextStyle(fontWeight: FontWeight.w500)),
                                          const Spacer(),
                                          Text('$startTime - $endTime', style: TextStyle(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_rounded, color: Color(0xFF6366F1), size: 22),
                                          const SizedBox(width: 10),
                                          Text('Location', style: TextStyle(fontWeight: FontWeight.w500)),
                                          const Spacer(),
                                          Text('Room $room', style: TextStyle(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, color: Color(0xFFF59E0B), size: 22),
                                          const SizedBox(width: 10),
                                          Text('Schedule', style: TextStyle(fontWeight: FontWeight.w500)),
                                          const Spacer(),
                                          Text(days.join(', '), style: TextStyle(fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 18),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: loadingClass ? null : _fetchStudents(studentsUIDs),
                          builder: (context, studentSnapshot) {
                            final loadingStudents = loadingClass || studentSnapshot.connectionState == ConnectionState.waiting;
                            final students = studentSnapshot.data ?? [];
                            if (loadingStudents) {
                              return shimmerStudentList();
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Enrolled Students (${students.length})',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  ...students.isEmpty
                                      ? [
                                          const SizedBox(height: 10),
                                          const Center(
                                            child: Text(
                                              'No students found in this class',
                                              style: TextStyle(fontSize: 16, color: Colors.black54),
                                            ),
                                          ),
                                        ]
                                      : [
                                          const SizedBox(height: 10),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: students.length,
                                            itemBuilder: (context, index) {
                                              final student = students[index];
                                              return FutureBuilder<double>(
                                                future: _fetchAttendancePercentage(classCode, student['uid']),
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                                    return Container(
                                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(16),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withOpacity(0.04),
                                                            blurRadius: 8,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          student['profile'] != null && student['profile'].toString().isNotEmpty
                                                              ? CircleAvatar(
                                                                  radius: 22,
                                                                  backgroundImage: NetworkImage(student['profile']),
                                                                )
                                                              : CircleAvatar(
                                                                  radius: 22,
                                                                  backgroundColor: Color(0xFF6366F1),
                                                                  child: Text(
                                                                    _getInitials(student['name']),
                                                                    style: const TextStyle(
                                                                      color: Colors.white,
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 16,
                                                                    ),
                                                                  ),
                                                                ),
                                                          const SizedBox(width: 14),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  student['name'],
                                                                  style: const TextStyle(
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.w600,
                                                                    color: Colors.black87,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  student['roll'] ?? '',
                                                                  style: const TextStyle(
                                                                    fontSize: 13,
                                                                    color: Colors.black54,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Shimmer.fromColors(
                                                            baseColor: Colors.grey.shade300,
                                                            highlightColor: Colors.grey.shade100,
                                                            child: Container(
                                                              width: 48,
                                                              height: 28,
                                                              decoration: BoxDecoration(
                                                                color: Colors.white,
                                                                borderRadius: BorderRadius.circular(999),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }
                                                  final percent = snapshot.data ?? 0.0;
                                                  return InkWell(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => TrackStudentAttendanceDetails(
                                                            className: className,
                                                            classCode: classCode,
                                                            studentName: student['name'] ?? '',
                                                            studentEmail: student['email'] ?? '',
                                                            rollNo: student['roll'] ?? '',
                                                            profileImage: student['profile'] ?? '',
                                                            studentUID: student['uid'] ?? '',
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(16),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withOpacity(0.04),
                                                            blurRadius: 8,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          student['profile'] != null && student['profile'].toString().isNotEmpty
                                                              ? CircleAvatar(
                                                                  radius: 22,
                                                                  backgroundImage: NetworkImage(student['profile']),
                                                                )
                                                              : CircleAvatar(
                                                                  radius: 22,
                                                                  backgroundColor: Color(0xFF6366F1),
                                                                  child: Text(
                                                                    _getInitials(student['name']),
                                                                    style: const TextStyle(
                                                                      color: Colors.white,
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 16,
                                                                    ),
                                                                  ),
                                                                ),
                                                          const SizedBox(width: 14),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  student['name'],
                                                                  style: const TextStyle(
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.w600,
                                                                    color: Colors.black87,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  student['roll'] ?? '',
                                                                  style: const TextStyle(
                                                                    fontSize: 13,
                                                                    color: Colors.black54,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                            decoration: BoxDecoration(
                                                              color: _attendanceColor(percent.round()),
                                                              borderRadius: BorderRadius.circular(999),
                                                            ),
                                                            child: Text(
                                                              '${percent.toStringAsFixed(0)}%',
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 13,
                                                              ),
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
                                        ],
                                ],
          )
                              );
                            },


                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(IconData icon, String value, String label, Color color) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}
