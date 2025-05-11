import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:present_me_flutter/button.dart';

class mark_Smart_Attendance_main extends StatelessWidget{
  final String className = "Python 4th semester";
  final String classCode = "b39747";
  final bool isAttendanceEnabled = false;
  final bool isAttendanceMarked = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mark Smart Attendance' ,style:TextStyle(fontSize: 24, color: Colors.white) ,),
        flexibleSpace: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff0BCCEB), Color(0xff0A80F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
            )
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Class Name: $className",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Class Code : $classCode",
                  style: TextStyle(color: Colors.grey[700]),
                ),
                SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "Status: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: isAttendanceEnabled
                            ? "Enabled by the teacher"
                            : "Attendance is disable by the teacher",
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  isAttendanceMarked
                      ? "Your attendance is marked"
                      : "Today your attendance is not marked",
                  style: TextStyle(
                    color: isAttendanceMarked ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                    child: Button(text: 'MARK ATTENDANCE', onPressed: (){}))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
