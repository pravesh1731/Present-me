import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class TrackStudentAttendanceDetails extends StatefulWidget {
  final String className;
  final String classCode;

  TrackStudentAttendanceDetails({
    required this.className,
    required this.classCode,
  });

  @override
  _TrackStudentAttendanceDetailsState createState() =>
      _TrackStudentAttendanceDetailsState();
}

class _TrackStudentAttendanceDetailsState
    extends State<TrackStudentAttendanceDetails> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  List<Map<String, String>> attendanceRecords = [];
  int presentCount = 0;
  int absentCount = 0;
  int totalCount = 0;
  double attendancePercentage = 0.0;

  @override
  void initState() {
    super.initState();
    fetchAttendanceRecords();
  }

  Future<void> fetchAttendanceRecords() async {
    final studentUID = auth.currentUser?.uid;

    if (studentUID == null) return;

    final datesRef = firestore
        .collection('Attendance')
        .doc(widget.classCode)
        .collection('DateList')
        .doc('AllDates');

    try {
      final snapshot = await datesRef.get();
      final dateList = List<String>.from(snapshot.get('dates') ?? []);

      if (dateList.isEmpty) {
        setState(() {
          attendanceRecords.clear();
          presentCount = 0;
          absentCount = 0;
          totalCount = 0;
        });
        return;
      }

      List<Map<String, String>> fetchedAttendance = [];
      int present = 0;
      int absent = 0;

      for (var dateKey in dateList) {
        final recordSnapshot = await firestore
            .collection('Attendance')
            .doc(widget.classCode)
            .collection(dateKey)
            .doc(studentUID)
            .get();

        final status =
        recordSnapshot.exists ? recordSnapshot.get('status') ?? 'N/A' : 'N/A';

        fetchedAttendance.add({'date': dateKey, 'status': status});

        if (status.toLowerCase() == 'present') {
          present++;
        } else if (status.toLowerCase() == 'absent') {
          absent++;
        }
      }

      setState(() {
        attendanceRecords = fetchedAttendance;
        presentCount = present;
        absentCount = absent;
        totalCount = fetchedAttendance.length;
        attendancePercentage =
        totalCount > 0 ? (presentCount / totalCount) * 100 : 0;
      });
    } catch (e) {
      print('Error fetching attendance records: $e');
    }
  }

  String getStatus(double percentage) {
    if (percentage >= 95) return "Excellent";
    if (percentage >= 90) return "Good";
    if (percentage >= 75) return "Average";
    return "Poor";
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String statusLabel = getStatus(attendancePercentage);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.className,
                style: TextStyle(fontSize: 22, color: Colors.white)),
            Text(widget.classCode,
                style: TextStyle(fontSize: 16, color: Colors.white)),
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
      body: Column(
        children: [
          // Pie Chart Card
          Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Attendance Status: $statusLabel",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: attendancePercentage >= 75
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                      "Total: $totalCount    Present: $presentCount    Absent: $absentCount"),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            startDegreeOffset: -90,
                            sections: [
                              PieChartSectionData(
                                color: const Color(0xFF4CAF50),
                                value: presentCount.toDouble(),
                                title:
                                '${(presentCount / totalCount * 100).toStringAsFixed(1)}%',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                color: const Color(0xFFF44336),
                                value: absentCount.toDouble(),
                                title:
                                '${(absentCount / totalCount * 100).toStringAsFixed(1)}%',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          swapAnimationDuration: Duration(milliseconds: 800),
                          swapAnimationCurve: Curves.easeInOut,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${attendancePercentage.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: attendancePercentage >= 75
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            Text(
                              getStatus(attendancePercentage),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(Color(0xFF4CAF50), "Present"),
                      SizedBox(width: 20),
                      _buildLegend(Color(0xFFF44336), "Absent"),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Attendance Records List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: attendanceRecords.length,
              itemBuilder: (context, index) {
                String date = attendanceRecords[index]['date']!;
                String status = attendanceRecords[index]['status']!;
                bool isPresent = status.toLowerCase() == "present";

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isPresent ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPresent ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    title: Text(date),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPresent ? Icons.check_circle : Icons.cancel,
                          color: isPresent ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(status),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
