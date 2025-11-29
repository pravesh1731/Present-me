import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:shimmer/shimmer.dart'; // <-- Add this
import 'package:fluttertoast/fluttertoast.dart'; // <-- Add this


class TrackStudentAttendanceDetails extends StatefulWidget {
  final String className;
  final String classCode;
  final String studentName;
  final String studentEmail;
  final String rollNo;
  final String studentUID; // <-- Add this
  final String? profileImage;

  TrackStudentAttendanceDetails({
    required this.className,
    required this.classCode,
    required this.studentName,
    required this.studentEmail,
    required this.rollNo,
    required this.studentUID, // <-- Add this
    this.profileImage,
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

    final studentUID = widget.studentUID;

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

        String status;
        if (!recordSnapshot.exists) {
          status = "Absent";
        } else {
          status = recordSnapshot.data()?['status']?.toString() ?? "Absent";
        }

        fetchedAttendance.add({'date': dateKey, 'status': status});

        // Use exact match for "Present" and "Absent"
        if (status == 'Present') {
          present++;
        } else if (status == 'Absent') {
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
      backgroundColor: const Color(0xFFF6F8FC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Modern Header (always shown)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 32, bottom: 24, left: 24, right: 24),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      widget.profileImage != null && widget.profileImage!.isNotEmpty
                          ? CircleAvatar(
                              radius: 32,
                              backgroundImage: NetworkImage(widget.profileImage!),
                            )
                          : CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white.withOpacity(0.18),
                              child: Text(
                                widget.studentName.isNotEmpty
                                    ? widget.studentName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                                    : 'ST',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              ),
                            ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.studentName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              widget.studentEmail,
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
            const SizedBox(height: 18),
            // Student Info Card (always shown)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Information',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.person_outline, color: Color(0xFF6366F1), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Roll Number',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            widget.rollNo,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F7FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.mail_outline, color: Color(0xFF06B6D4), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            widget.studentEmail,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Attendance Summary Card (shimmer if loading)
            isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Overall Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 22),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              '${attendancePercentage.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _attendanceStatCard(Icons.calendar_today_rounded, totalCount, 'Total'),
                            _attendanceStatCard(Icons.check_circle_rounded, presentCount, 'Present'),
                            _attendanceStatCard(Icons.cancel_rounded, absentCount, 'Absent'),
                          ],
                        ),
                      ],
                    ),
                  ),
            // Attendance Distribution Pie Chart (shimmer if loading)
            isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Attendance Distribution', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 14),
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
                              showLegends: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 18),
            // Attendance Records List (shimmer if loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Attendance History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Long press to edit', style: TextStyle(fontSize: 13, color: Colors.blue)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: isLoading
                  ? Column(
                      children: List.generate(4, (index) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: attendanceRecords.length,
                      itemBuilder: (context, index) {
                        String rawDate = attendanceRecords[index]['date']!;
                        DateTime parsedDate = DateTime.parse(rawDate);
                        String formattedDate = "${parsedDate.year}, ${_getMonthAbbr(parsedDate.month)} ${parsedDate.day.toString().padLeft(2, '0')}";
                        String status = attendanceRecords[index]['status']!;
                        bool isPresent = status == "Present";
                        String weekday = _getWeekdayAbbr(parsedDate.weekday);

                        return GestureDetector(
                          onLongPress: () async {
                            String currentStatus = attendanceRecords[index]['status']!;
                            String newStatus = currentStatus == 'Present' ? 'Absent' : 'Present';
                            bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Change attendance status?',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                      ),
                                      SizedBox(height: 18),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            ),
                                            icon: Icon(Icons.edit, color: Colors.white),
                                            label: Text('Change', style: TextStyle(color: Colors.white)),
                                            onPressed: () => Navigator.pop(context, true),
                                          ),
                                          SizedBox(width: 16),
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              backgroundColor: Colors.grey[200],
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            ),
                                            child: Text('Cancel', style: TextStyle(color: Colors.black)),
                                            onPressed: () => Navigator.pop(context, false),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                            if (confirm == true) {
                              String dateKey = attendanceRecords[index]['date']!;
                              await firestore
                                  .collection('Attendance')
                                  .doc(widget.classCode)
                                  .collection(dateKey)
                                  .doc(widget.studentUID)
                                  .set({'status': newStatus}, SetOptions(merge: true));
                              Fluttertoast.showToast(
                                msg: 'Status changed to "$newStatus"',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                              );
                              fetchAttendanceRecords();
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            decoration: BoxDecoration(
                              color: isPresent ? const Color(0xFFE8FFF3) : const Color(0xFFFFEBEB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isPresent ? Colors.green : Colors.red,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isPresent ? Colors.green : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPresent ? Icons.check : Icons.close,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        status,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isPresent ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isPresent ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    weekday,
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
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _attendanceStatCard(IconData icon, int value, String label) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 6),
          Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  // Add this method to build the weekly trend chart with real data
  Widget _buildWeeklyTrendChart() {
    // Group attendanceRecords by week
    Map<int, Map<String, int>> weekStats = {};
    for (var record in attendanceRecords) {
      DateTime date = DateTime.parse(record['date']!);
      int week = ((date.day - 1) ~/ 7) + 1;
      String status = record['status']!.toLowerCase();
      weekStats.putIfAbsent(week, () => {'present': 0, 'absent': 0});
      if (status == 'present') {
        weekStats[week]!['present'] = weekStats[week]!['present']! + 1;
      } else {
        weekStats[week]!['absent'] = weekStats[week]!['absent']! + 1;
      }
    }
    // Prepare data for 4 weeks
    List<int> presentData = List.generate(4, (i) => weekStats[i + 1]?['present'] ?? 0);
    List<int> absentData = List.generate(4, (i) => weekStats[i + 1]?['absent'] ?? 0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Present bar
              Container(
                height: presentData[i] * 12.0,
                width: 16,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Absent bar
              Container(
                height: absentData[i] * 12.0,
                width: 16,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text('Week ${i + 1}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        );
      }),
    );
  }

  // Add shimmer loading widget
  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 120,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
          ),
          // Student info card shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Attendance summary card shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Pie chart shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Attendance records shimmer list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: List.generate(4, (index) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
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
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  String _getWeekdayAbbr(int weekday) {
    const days = [
      '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    return days[weekday];
  }
}
