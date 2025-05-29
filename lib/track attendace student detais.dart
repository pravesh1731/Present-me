import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pie_chart/pie_chart.dart';


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
  bool isLoading = true;

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
    setState(() {
      isLoading = true;
    });

    final studentUID = auth.currentUser?.uid;

    if (studentUID == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

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
          isLoading = false;
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

        final status = recordSnapshot.exists
            ? recordSnapshot.get('status') ?? 'N/A'
            : 'N/A';

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
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching attendance records: $e');
      setState(() {
        isLoading = false;
      });
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
      body:isLoading
          ? Center(child: CircularProgressIndicator())
      :Column(
        children: [
          // Pie Chart Card
          Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            color: Colors.blue.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Attendance Status:",style: TextStyle(fontSize: 18),),
                      Text(
                        " $statusLabel",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: attendancePercentage >= 75
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, color: Colors.black),
                      children: [
                        TextSpan(text: "Total: $totalCount     "),
                        TextSpan(
                          text: "Present: $presentCount     ",
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: "Absent: $absentCount     ",
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      dataMap: {
                        "Present": presentCount.toDouble(),
                        "Absent": absentCount.toDouble(),
                      },
                      chartType: ChartType.disc,
                      colorList: [Colors.green, Colors.redAccent],
                      chartValuesOptions: ChartValuesOptions(
                        showChartValuesInPercentage: true,
                        showChartValues: true,
                        showChartValueBackground: true,
                      ),
                      legendOptions: LegendOptions(
                        showLegends:true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Attendance Records List
          Expanded(
            child: Builder(
              builder: (context) {
                // Sort list by date descending
                attendanceRecords.sort((a, b) => b['date']!.compareTo(a['date']!));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: attendanceRecords.length,
                  itemBuilder: (context, index) {
                    String rawDate = attendanceRecords[index]['date']!;
                    DateTime parsedDate = DateTime.parse(rawDate);
                    String formattedDate = "${parsedDate.day.toString().padLeft(2, '0')}-"
                        "${parsedDate.month.toString().padLeft(2, '0')}-"
                        "${parsedDate.year}";

                    String status = attendanceRecords[index]['status']!;
                    bool isPresent = status.toLowerCase() == "present";

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isPresent ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPresent ? Colors.green : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        title: Text(formattedDate),
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
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}
