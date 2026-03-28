import 'package:flutter/foundation.dart';

class StudentAttendanceSummary {
  final int totalClasses;
  final int present;
  final int absent;
  final double percentage;

  const StudentAttendanceSummary({
    required this.totalClasses,
    required this.present,
    required this.absent,
    required this.percentage,
  });

  factory StudentAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceSummary(
      totalClasses: json["totalClasses"] ?? 0,
      present: json["present"] ?? 0,
      absent: json["absent"] ?? 0,
      percentage: (json["percentage"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class JoinStudentList {
  final String studentId;
  final String firstName;
  final String lastName;
  final String emailId;
  final String rollNo;
  final String profilePicUrl;
  final StudentAttendanceSummary attendance; // ✅ added

  const JoinStudentList({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.emailId,
    required this.rollNo,
    required this.profilePicUrl,
    required this.attendance, // ✅ added
  });

  factory JoinStudentList.fromJson(Map<String, dynamic> json) {
    return JoinStudentList(
      studentId: json["studentId"] ?? "",
      firstName: json["firstName"] ?? "",
      lastName: json["lastName"] ?? "",
      emailId: json["emailId"] ?? "",
      rollNo: json["rollNo"] ?? "",
      profilePicUrl: json["profilePicUrl"] ?? "",
      // ✅ parse nested attendance object, default to zeros if missing
      attendance: json["attendance"] != null
          ? StudentAttendanceSummary.fromJson(json["attendance"])
          : const StudentAttendanceSummary(
        totalClasses: 0,
        present: 0,
        absent: 0,
        percentage: 0.0,
      ),
    );
  }
}