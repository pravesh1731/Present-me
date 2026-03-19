import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:present_me_flutter/components/common/Button/token.dart';
import 'package:present_me_flutter/core/widgets/header.dart';
import 'package:present_me_flutter/models/student_attendance_model.dart';
import 'package:present_me_flutter/viewmodels/student_attendance/student_attendance_state.dart';
import 'package:present_me_flutter/viewmodels/student_auth/auth_bloc.dart';
import '../../viewmodels/student_attendance/student_attendance_bloc.dart';
import '../../viewmodels/student_attendance/student_attendance_event.dart';
import '../../viewmodels/student_auth/auth_state.dart';

class StudentAttendanceDetails extends StatefulWidget {
  final String classCode;
  final String className;
  final String teacherName;


  const StudentAttendanceDetails({
    super.key,
    required this.classCode,
    required this.className,
    required this.teacherName,
  });

  @override
  _StudentAttendanceDetailsState createState() =>
      _StudentAttendanceDetailsState();
}

class _StudentAttendanceDetailsState extends State<StudentAttendanceDetails> {
  List<Map<String, String>> attendanceList = [];
  bool isLoading = true;
  late String studentId = '';

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      final studentID = state.student['studentId'];
        studentId = studentID;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = getToken();
      if (token.isNotEmpty) {
        context.read<StudentAttendanceBloc>().add(
          FetchStudentAttendance(
            classCode: widget.classCode,
            studentId: studentId,
          ),
        );
      }
    });
  }



  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: Column(
        children: [
          Header(heading: widget.className, subheading: widget.teacherName),

          BlocBuilder<StudentAttendanceBloc, StudentAttendanceState>(
              builder: (context, state) {
                if (state is StudentAttendanceLoading) {
                  return Column(
                    children: [
                      const SizedBox(height: 10),
                      _shimmerBox(height: 310),
                      const SizedBox(height: 40),
                      _shimmerBox(height: 50),
                      const SizedBox(height: 10),
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

                if(state is StudentAttendanceLoaded){
                  final attendance = state.data.attendance.reversed.toList();
                  print(attendance);
                  return Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 18),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(

                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],

                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Overall Attendance',
                                        ),
                                        const Spacer(),
                                        Text(
                                          "${attendance.percentage.toDouble()}%",
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .spaceAround,
                                      children: [
                                        _attendanceStatCard(
                                          Icons.people,
                                          attendance.presentCount + attendance.absentCount,
                                          "Total",
                                        ),
                                        _attendanceStatCard(
                                          Icons.check,
                                          attendance.presentCount,
                                          "Present",
                                        ),
                                        _attendanceStatCard(
                                          Icons.close,
                                          attendance.absentCount,
                                          "Absent",
                                        ),
                                      ],
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 8),
                                      height: 1,
                                      color: Colors.grey.shade300,
                                    ),
                                    Container(
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
                              SizedBox(height: 8),
                            ],
                          ),
                        ),

                        SizedBox(height: 10,),
                        Container(
                          padding: EdgeInsets.only(left: 16),
                          child: Row(
                            children: [
                              Text("Attendance History",
                                  style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                        // Attendance List

                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.only(top: 8),
                            itemCount: attendance.length,
                            itemBuilder: (context, index) {
                              final item = attendance[index];
                              final isPresent = item.status == 1; // ← fix: derive per item

                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
                                  border: Border(
                                    left: BorderSide(
                                      color: isPresent ? Colors.green : Colors.red,
                                      width: 4,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('dd-MM-yyyy').format(DateTime.parse(item.date ?? '')),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          isPresent ? Icons.check_circle : Icons.cancel,
                                          color: isPresent ? Colors.green : Colors.red,
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          item.status == 1 ? "Present" : "Absent",
                                          style: TextStyle(
                                            color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox();
              }
          )
        ],
      ),
    );
  }
}


Widget _attendanceStatCard(IconData icon, int value, String label) {
  return Container(
    width: 80,
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
            Color(0xFF06B6D4),
            Color(0xFF2563EB)
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Icon(icon,  size: 22, color: Colors.white,),
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
          style: const TextStyle(color: Colors.white70, fontSize: 13,),
        ),
      ],
    ),
  );
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