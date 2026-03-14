import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:present_me_flutter/models/join_student_list.dart';
import 'package:present_me_flutter/viewmodels/approveStudent_list/approveStudent_list_bloc.dart';
import 'package:present_me_flutter/viewmodels/approveStudent_list/approveStudent_list_event.dart';
import 'package:present_me_flutter/viewmodels/approveStudent_list/approveStudent_list_state.dart';
import 'package:present_me_flutter/views/Teacher%20Screens/student%20request%20list.dart';
import 'package:present_me_flutter/views/Teacher%20Screens/track%20attendance%20of%20specificStudent%20for%20Teacher.dart';
import 'dart:math';
import 'package:get_storage/get_storage.dart';
import 'package:shimmer/shimmer.dart';


class classDetailsStudentList extends StatefulWidget {

    final String classCode;
    final String roomNo;
    final String className1;
    final List classDays;
    final String startTime;
    final String endTime;
    final int student;

    classDetailsStudentList({
      required this.classCode,
      required this.roomNo,
      required this.className1,
      required this.classDays,
      required this.startTime,
      required this.endTime,
      required this.student,
    });

  @override
  State<classDetailsStudentList> createState() => _classDetailsStudentListState();
}

class _classDetailsStudentListState extends State<classDetailsStudentList> {


  final GetStorage _storage = GetStorage();

  List<JoinStudentList> results = [];
  bool isLoading = true;

  String _getToken() {
    return _storage.read('token')?.toString() ?? '';
  }




  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = _getToken();
      if(token.isNotEmpty){
        context.read<ApproveStudentListBloc> ().add(
            ApproveStudentFetchList(token, widget.classCode)
        );
      }
    }
    );
  }

    String _shortDay(String day) {
      const map = {
        'Monday': 'Mon',
        'Tuesday': 'Tue',
        'Wednesday': 'Wed',
        'Thursday': 'Thu',
        'Friday': 'Fri',
        'Saturday': 'Sat',
        'Sunday': 'Sun',
      };

      return map[day] ?? day;
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
      Widget headerSection({String className = '', String roomNo = '', int requestCount = 0}) {
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
                                className.isNotEmpty ? '${widget.className1}' : 'Class',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                roomNo.isNotEmpty ? 'Room $roomNo' : 'Room --',
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
                          builder: (context) => StudentRequestList(classCode: widget.classCode,
                          className: widget.className1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0x2EFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  if (requestCount > 0)
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
      }

      Widget summaryCards({int student = 0, int attendance = 94, int classes = 45}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _summaryCard(Icons.people_alt_rounded, '$student', 'Students', Colors.blue),
            _summaryCard(Icons.check_circle_rounded, '$attendance%', 'Attendance', Color(0xFF10B981)),
            _summaryCard(Icons.calendar_month_rounded, '$classes', 'Classes', Colors.purple),
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
        body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerSection(className: widget.className1, roomNo: widget.roomNo, requestCount: 0),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 18),
                          summaryCards(
                            student:  widget.student,
                            attendance: 94,
                            classes: 20,
                          ),
                          const SizedBox(height: 18),
                          // if (loadingClass)
                          //   shimmerClassInfo()
                          // else
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
                                          color: Color(0x0A000000),
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
                                            Text('${widget.startTime} - ${widget.endTime}', style: TextStyle(fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_rounded, color: Color(0xFF6366F1), size: 22),
                                            const SizedBox(width: 10),
                                            Text('Location', style: TextStyle(fontWeight: FontWeight.w500)),
                                            const Spacer(),
                                            Text('Room ${widget.roomNo}', style: TextStyle(fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today_rounded, color: Color(0xFFF59E0B), size: 22),
                                            const SizedBox(width: 10),
                                            Text('Schedule', style: TextStyle(fontWeight: FontWeight.w500)),
                                            const Spacer(),
                                            Text(
                                              widget.classDays.map((d) => _shortDay(d.toString())).join(', '),
                                              style: TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 18),


                          BlocBuilder<ApproveStudentListBloc, ApproveStudentListState>(
                               builder: (context ,state){
                             if(state is ApproveStudentListLoading){
                               return shimmerStudentList();
                             };
                             if(state is ApproveStudentListLoaded){
                               return Padding(
                                 padding: const EdgeInsets.symmetric(horizontal: 18),
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       'Enrolled Students (${state.students.length})',
                                       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                                     ),
                                       ListView.builder(
                                         shrinkWrap: true,
                                         physics: const NeverScrollableScrollPhysics(),
                                         itemCount: state.students.length,
                                         itemBuilder: (context, index) {
                                           final student = state.students[index];
                                           // TODO: Replace with real attendance percentage from API when available.
                                           const percent = 0.0;
                                           return _buildStudentRow(
                                             student,
                                             percent,
                                             widget.className1,
                                             widget.classCode,
                                             context,
                                           );
                                         },
                                       ),
                                   ],
                                 ),
                                );
                             }
                             if(state is ApproveStudentListError){
                               return Center(child: Text(state.message));
                             };
                             return const SizedBox(height: 24,);
                           },
                           ),
                        // const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

            )

              ],

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
              color: Color(0x0A000000),
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


  Widget _buildStudentRow(
      JoinStudentList student,
      double percent,
      String className,
      String classCode,
      BuildContext context,
      ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackStudentAttendanceDetails(
              className: className,
              classCode: classCode,
              studentName: "${student.firstName} ${student.lastName}",
              studentEmail: student.emailId,
              rollNo: student.rollNo,
              profileImage: student.profilePicUrl,
              studentUID: student.studentId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 04),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            student.profilePicUrl.isNotEmpty
                ? CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(student.profilePicUrl),
            )
                : CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF6366F1),
              child: Text(
                _getInitials("${student.firstName} ${student.lastName}"),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${student.firstName} ${student.lastName}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    student.rollNo,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _attendanceColor(percent.round()),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${percent.toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

    toStringList(param0) {}
}


