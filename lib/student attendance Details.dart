import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';

class StudentAttendanceDetails extends StatefulWidget {
  final String studentUID;
  final String classCode;
  final String studentName;
  final String rollNo;
  final String profileImage;

  StudentAttendanceDetails({
    required this.studentUID,
    required this.classCode,
    required this.studentName,
    required this.rollNo,
    required this.profileImage,
  });

  @override
  _StudentAttendanceDetailsState createState() => _StudentAttendanceDetailsState();
}

class _StudentAttendanceDetailsState extends State<StudentAttendanceDetails> {
  List<Map<String, String>> attendanceList = [];
  int presentCount = 0;
  int absentCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAttendanceRecords();
  }

  Future<void> fetchAttendanceRecords() async {
    setState(() => isLoading = true);
    final firestore = FirebaseFirestore.instance;

    try {
      final allDatesSnapshot = await firestore
          .collection("Attendance")
          .doc(widget.classCode)
          .collection("DateList")
          .doc("AllDates")
          .get();

      final dateList = List<String>.from(allDatesSnapshot.get("dates") ?? []);

      final List<Map<String, String>> tempList = [];

      for (String date in dateList) {
        final record = await firestore
            .collection("Attendance")
            .doc(widget.classCode)
            .collection(date)
            .doc(widget.studentUID)
            .get();

        String status = record.get("status") ?? "N/A";
        tempList.add({"date": date, "status": status});
      }

      tempList.sort((a, b) => b["date"]!.compareTo(a["date"]!));

      setState(() {
        attendanceList = tempList;
        presentCount = attendanceList.where((e) => e['status'] == 'Present').length;
        absentCount = attendanceList.length - presentCount;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> toggleStatus(int index) async {
    final record = attendanceList[index];
    final currentStatus = record['status']!;
    final newStatus = currentStatus == "Present" ? "Absent" : "Present";

    bool confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Change Status"),
        content: Text("Change status from $currentStatus to $newStatus?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Yes")),
        ],
      ),
    );

    if (confirmed) {
      try {
        await FirebaseFirestore.instance
            .collection("Attendance")
            .doc(widget.classCode)
            .collection(record['date']!)
            .doc(widget.studentUID)
            .update({"status": newStatus});

        setState(() {
          attendanceList[index]['status'] = newStatus;
          presentCount = attendanceList.where((e) => e['status'] == 'Present').length;
          absentCount = attendanceList.length - presentCount;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status updated")));
      } catch (e) {
        print("Update failed: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed")));
      }
    }
  }
  String formatDate(String rawDate) {
    try {
      DateTime parsedDate = DateTime.parse(rawDate); // assumes "yyyy-MM-dd"
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return rawDate; // fallback if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    int total = attendanceList.length;

    return Scaffold(
      appBar: AppBar(title: Text("Student Attendance",style: TextStyle(color: Colors.white),),
          flexibleSpace: Container(
          decoration: const BoxDecoration(
          gradient: LinearGradient(
          colors: [Color(0xff0BCCEB), Color(0xff0A80F5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    ),
    ),),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Profile Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(widget.profileImage),
                ),
                SizedBox(height: 8),
                Text(widget.studentName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(widget.rollNo),
              ],
            ),
          ),

          // Chart
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16,),
            color: Colors.lightBlue.shade100,
            child: Padding(
              padding: const EdgeInsets.only(top: 8,right: 16, left: 16,bottom:4),
              child: Column(
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, color: Colors.black),
                      children: [
                        TextSpan(text: "Total: $total     "),
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
                    height: 160,
                    child: PieChart(
                      dataMap: {
                        "Present": presentCount.toDouble(),
                        "Absent": absentCount.toDouble(),
                      },
                      chartType: ChartType.disc,
                      colorList: [Colors.green, Colors.redAccent],
                      chartValuesOptions: ChartValuesOptions(showChartValuesInPercentage: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
          // Attendance List
          Expanded(
            child: ListView.builder(
              itemCount: attendanceList.length,
              itemBuilder: (context, index) {
                final item = attendanceList[index];
                final isPresent = item['status'] == 'Present';

                return GestureDetector(
                  onLongPress: () => toggleStatus(index),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                      border: Border.all(color: isPresent ? Colors.green : Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatDate(item['date']!),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        Row(
                          children: [
                            Icon(isPresent ? Icons.check_circle : Icons.cancel,
                                color: isPresent ? Colors.green : Colors.red),
                            SizedBox(width: 6),
                            Text(item['status']!),
                          ],
                        ),
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
