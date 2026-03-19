import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:pie_chart/pie_chart.dart';
import 'package:present_me_flutter/core/constants/constants.dart';
import 'package:present_me_flutter/models/student_attendance_model.dart';
import 'package:present_me_flutter/viewmodels/student_attendance/student_attendance_state.dart';
import 'package:intl/intl.dart';
import '../../components/common/Button/token.dart';
import '../../viewmodels/student_attendance/student_attendance_bloc.dart';
import '../../viewmodels/student_attendance/student_attendance_event.dart';

class TrackStudentAttendanceDetails extends StatefulWidget {
  final String className;
  final String classCode;
  final String studentName;
  final String studentEmail;
  final String rollNo;
  final String studentId; // <-- Add this
  final String? profileImage;

  TrackStudentAttendanceDetails({
    required this.className,
    required this.classCode,
    required this.studentName,
    required this.studentEmail,
    required this.rollNo,
    required this.studentId, // <-- Add this
    this.profileImage,
  });

  @override
  _TrackStudentAttendanceDetailsState createState() =>
      _TrackStudentAttendanceDetailsState();
}

class _TrackStudentAttendanceDetailsState
    extends State<TrackStudentAttendanceDetails> {
  int presentCount = 0;
  int absentCount = 0;
  int totalCount = 0;
  double attendancePercentage = 0.0;
  bool isInitialized = false;
  List<StudentAttendance> localAttendance = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = getToken();
      if (token.isNotEmpty) {
        context.read<StudentAttendanceBloc>().add(
          FetchStudentAttendance(
            classCode: widget.classCode,
            studentId: widget.studentId,
          ),
        );
      }
    });
  }

  Future<void> updateAttendance({
    required String classCode,
    required String date,
    required String studentId,
    required int status,
  }) async {
    final token = getToken();

    final res = await http.patch(
      Uri.parse("$baseUrl/teachers/update-attendance"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "classCode": classCode,
        "date": date,
        "studentId": studentId,
        "status": status,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to update attendance");
    }
  }

  Future<void> showUpdateDialog({
    required dynamic item,
    required int index,
    required List attendance,
  }) async {
    final newStatus = item.status == 1 ? 0 : 1;
    final actionText = newStatus == 1 ? "Present" : "Absent";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Update Attendance"),
          content: Text("Mark this student as $actionText?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final parentContext = this.context;

                Navigator.pop(context); // close dialog

                try {
                  await updateAttendance(
                    classCode: widget.classCode,
                    date: item.date,
                    studentId: widget.studentId,
                    status: newStatus,
                  );

                  if (!mounted) return;

                  setState(() {
                    localAttendance[index] =
                        localAttendance[index].copyWith(status: newStatus);

                    localAttendance.sort((a, b) =>
                        DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

                    localAttendance = List.from(localAttendance);
                  });

                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text("Marked as $actionText")),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(content: Text("Update failed")),
                  );
                }
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Modern Header (always shown)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 32,
                bottom: 24,
                left: 24,
                right: 24,
              ),
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
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      widget.profileImage != null &&
                              widget.profileImage!.isNotEmpty
                          ? CircleAvatar(
                            radius: 32,
                            backgroundImage: NetworkImage(widget.profileImage!),
                          )
                          : CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white.withOpacity(0.18),
                            child: Text(
                              widget.studentName.isNotEmpty
                                  ? widget.studentName
                                      .trim()
                                      .split(' ')
                                      .map((e) => e[0])
                                      .take(2)
                                      .join()
                                      .toUpperCase()
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
                              widget.rollNo,
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

            BlocBuilder<StudentAttendanceBloc, StudentAttendanceState>(
              builder: (context, state) {
                if (state is StudentAttendanceLoading) {
                  return Column(
                    children: [
                      const SizedBox(height: 10),
                      _shimmerBox(height: 150),
                      const SizedBox(height: 10),
                      _shimmerBox(height: 150),
                      const SizedBox(height: 80),
                      _shimmerBox(height: 50),
                      const SizedBox(height: 10),
                      _shimmerBox(height: 50),
                      const SizedBox(height: 10),
                      _shimmerBox(height: 50),
                    ],
                  );
                }

                if (state is StudentAttendanceError) {
                  return Center(child: Text(state.message));
                }

                if (state is StudentAttendanceLoaded) {
                  if (!isInitialized) {
                    localAttendance = List.from(state.data.attendance);

                    /// ✅ ADD THIS (SORT LATEST FIRST)
                    localAttendance.sort((a, b) =>
                        DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

                    isInitialized = true;
                  }


                  final attendance = localAttendance;
                  final presentCount = attendance.presentCount;
                  final absentCount = attendance.absentCount;
                  final totalCount = attendance.length;
                  final double attendancePercentage = attendance.percentage;

                  return Column(
                    children: [
                      /// ✅ SUMMARY CARD
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 18),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Overall Attendance',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const Spacer(),
                                Text(
                                  "${attendancePercentage.toStringAsFixed(0)}%",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _attendanceStatCard(
                                  Icons.people,
                                  totalCount,
                                  "Total",
                                ),
                                _attendanceStatCard(
                                  Icons.check,
                                  presentCount,
                                  "Present",
                                ),
                                _attendanceStatCard(
                                  Icons.close,
                                  absentCount,
                                  "Absent",
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      /// ✅ PIE CHART
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 18),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(

                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            const Text("Attendance Distribution"),

                            const SizedBox(height: 4),

                            SizedBox(
                              height: 100,
                              child: PieChart(
                                dataMap: {
                                  "Present": attendance.presentCount.toDouble(),
                                  "Absent": attendance.absentCount.toDouble(),
                                },
                                chartType: ChartType.ring,
                                colorList: [
                                  Colors.green.shade400,
                                  Colors.redAccent
                                ],
                                chartValuesOptions: ChartValuesOptions(

                                  showChartValueBackground: false,
                                  chartValueStyle: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 0,
                                  ),
                                ),
                                ringStrokeWidth: 16,
                                centerText: "${ ((attendance.presentCount /
                                    (attendance.presentCount + attendance.absentCount)) * 100)
                                    .toStringAsFixed(0)}%",
                                centerTextStyle: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            Text(
                              "Attendance History",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "Long Press to edit",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: attendance.length,
                        itemBuilder: (context, index) {
                          final item = attendance[index];
                          DateTime date = DateTime.parse(item.date);

                          String formattedDate = DateFormat(
                            "dd-MM-yyyy",
                          ).format(date);
                          String day = DateFormat("EEEE").format(date);

                          return GestureDetector(
                            onLongPress: () {
                              showUpdateDialog(
                                item: item,
                                index: index,
                                attendance: attendance,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: item.status == 1 ? Colors.green.shade50 : Colors.red.shade50,
                                border: Border(
                                  left: BorderSide(
                                    color: item.status == 1 ? Colors.green : Colors.red,
                                    width: 4,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.status == 1
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color:
                                        item.status == 1
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            color:
                                                item.status == 1
                                                    ? Colors.green.shade200
                                                    : Colors.red,
                                          ),

                                          child: Text(
                                            day,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
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
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

Widget _shimmerBox({required double height}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    height: height,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(16),
    ),
  );
}
