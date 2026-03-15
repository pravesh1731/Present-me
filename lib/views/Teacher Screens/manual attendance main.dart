import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'package:present_me_flutter/components/common/Button/token.dart';
import 'package:present_me_flutter/core/constants/constants.dart';
import 'package:present_me_flutter/core/widgets/header.dart';
import 'package:present_me_flutter/viewmodels/approveStudent_list/approveStudent_list_bloc.dart';
import 'package:present_me_flutter/viewmodels/approveStudent_list/approveStudent_list_event.dart';
import 'package:present_me_flutter/viewmodels/approveStudent_list/approveStudent_list_state.dart';

class ManualAttendanceMain extends StatefulWidget {
  final String className;
  final String classCode;

  const ManualAttendanceMain({
    super.key,
    required this.className,
    required this.classCode,
  });

  @override
  State<ManualAttendanceMain> createState() => _ManualAttendanceMainState();
}

class _ManualAttendanceMainState extends State<ManualAttendanceMain> {

  bool isAttendanceFinalized = false;

  /// studentId -> status
  /// 1 = present
  /// 0 = absent
  Map<String, int> attendanceMap = {};

  String _prettyDate() {
    return DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
  }

  String getTodayDate() {
    return DateFormat("yyyy-MM-dd").format(DateTime.now());
  }

  /// COUNTING
  int get presentCount =>
      attendanceMap.values.where((s) => s == 1).length;

  int get absentCount =>
      attendanceMap.values.where((s) => s == 0).length;

  /// BUILD ATTENDANCE JSON
  List<Map<String, dynamic>> buildAttendance() {
    return attendanceMap.entries.map((e) {
      return {
        "studentId": e.key,
        "status": e.value
      };
    }).toList();
  }

  /// SUBMIT ATTENDANCE
  Future<void> submitAttendance() async {

    final token = getToken();

    final body = {
      "classCode": widget.classCode,
      "date": getTodayDate(),
      "attendance": buildAttendance()
    };

    final response = await http.post(
      Uri.parse("${baseUrl}/teachers/mark-attendance"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {

      setState(() {
        isAttendanceFinalized = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance submitted successfully")),
      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit attendance")),
      );
    }
  }

  /// CHECK IF ATTENDANCE ALREADY SUBMITTED
  Future<void> checkAttendanceStatus() async {

    final token = getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/teachers/attendance-status/${widget.classCode}"),
      headers: {
        "Authorization": "Bearer $token"
      },
    );

    final data = jsonDecode(response.body);

    if (data["submitted"] == true) {

      setState(() {

        isAttendanceFinalized = true;

        for (var item in data["attendance"]) {
          attendanceMap[item["studentId"]] = item["status"];
        }

      });
    }
  }

  /// VALIDATE & FINALIZE
  Future<void> finalizeAttendance(List students) async {

    if (attendanceMap.length != students.length) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please mark all students")),
      );

      return;
    }

    await submitAttendance();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      final token = getToken();

      if (token.isNotEmpty) {

        context.read<ApproveStudentListBloc>().add(
          ApproveStudentFetchList(token, widget.classCode),
        );

      }

      checkAttendanceStatus();
    });
  }

  void showConfirmationDialog(List students) {

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          title: const Text("Submit Attendance"),

          content: const Text(
              "Are you sure you want to submit today's attendance?"
          ),

          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {

                Navigator.pop(context);

                await finalizeAttendance(students);

              },
              child: const Text("Submit"),
            )

          ],
        );
      },
    );
  }

  Widget attendanceSummary(int total) {

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x11000000),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [

          _summaryItem("Total", total, Colors.black),

          _summaryItem("Present", presentCount, Colors.green),

          _summaryItem("Absent", absentCount, Colors.red),

        ],
      ),
    );
  }

  Widget _summaryItem(String title, int count, Color color) {

    return Column(
      children: [

        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          "$count",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),

      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Column(
        children: [

          /// HEADER
          Stack(
            children: [

              Header(
                heading: "Manual Attendance",
                subheading: widget.classCode,
              ),

              Positioned(
                right: 16,
                bottom: 26,
                child: SafeArea(
                  top: false,
                  child: Text(
                    _prettyDate(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            ],
          ),

          /// STUDENT LIST
          BlocBuilder<ApproveStudentListBloc, ApproveStudentListState>(
            builder: (context, state) {

              if (state is ApproveStudentListLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ApproveStudentListLoaded) {

                final students = state.students;

                return Expanded(
                  child: Column(
                    children: [

                      /// SUMMARY
                      attendanceSummary(students.length),

                      /// STUDENT LIST
                      Expanded(
                        child: ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (context, index) {

                            final student = students[index];
                            final status = attendanceMap[student.studentId];

                            Color cardColor = Colors.white;

                            if (status == 1) {
                              cardColor = const Color(0xFFE6F9EF);
                            } else if (status == 0) {
                              cardColor = const Color(0xFFFFEBEB);
                            }

                            return Container(

                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),

                              padding: const EdgeInsets.all(8),

                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: const Color(0xFFE5E7EB)),
                              ),

                              child: Row(
                                children: [

                                  /// AVATAR
                                  Container(
                                    width: 48,
                                    height: 48,

                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF6366F1),
                                          Color(0xFFA855F7)
                                        ],
                                      ),
                                    ),

                                    child: ClipOval(
                                      child: student.profilePicUrl.isNotEmpty
                                          ? Image.network(
                                        student.profilePicUrl,
                                        fit: BoxFit.cover,
                                      )
                                          : Center(
                                        child: Text(
                                          student.firstName
                                              .toUpperCase()[0] +
                                              student.lastName
                                                  .toUpperCase()[0],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  /// STUDENT INFO
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [

                                        Text(
                                          "${student.firstName} ${student.lastName}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),

                                        Text(
                                          student.rollNo,
                                          style: const TextStyle(fontSize: 12),
                                        ),

                                      ],
                                    ),
                                  ),

                                  /// PRESENT BUTTON
                                  IconAction(
                                    enabled: !isAttendanceFinalized,
                                    bg: status == 1
                                        ? Colors.green
                                        : const Color(0xFFDDFBE7),
                                    fg: const Color(0xFF16A34A),
                                    icon: Icons.check,
                                    onTap: () {

                                      setState(() {
                                        attendanceMap[student.studentId] = 1;
                                      });

                                    },
                                  ),

                                  const SizedBox(width: 10),

                                  /// ABSENT BUTTON
                                  IconAction(
                                    enabled: !isAttendanceFinalized,
                                    bg: status == 0
                                        ? Colors.red
                                        : const Color(0xFFFCE1E1),
                                    fg: const Color(0xFFDC2626),
                                    icon: Icons.close,
                                    onTap: () {

                                      setState(() {
                                        attendanceMap[student.studentId] = 0;
                                      });

                                    },
                                  ),

                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      /// SUBMIT BUTTON
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(

                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),

                          onPressed: isAttendanceFinalized
                              ? null
                              : () => showConfirmationDialog(students),

                          child: const Text("Submit Attendance"),

                        ),
                      )

                    ],
                  ),
                );
              }

              if (state is ApproveStudentListError) {
                return Center(child: Text(state.message));
              }

              return const SizedBox();
            },
          ),

        ],
      ),
    );
  }
}

class IconAction extends StatelessWidget {

  final bool enabled;
  final Color bg;
  final Color fg;
  final IconData icon;
  final VoidCallback onTap;

  const IconAction({
    super.key,
    required this.enabled,
    required this.bg,
    required this.fg,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return Opacity(
      opacity: enabled ? 1.0 : 0.2,

      child: InkWell(

        onTap: enabled ? onTap : null,

        borderRadius: BorderRadius.circular(16),

        child: Container(
          width: 48,
          height: 48,

          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),

          child: Icon(icon, color: fg),
        ),
      ),
    );
  }
}