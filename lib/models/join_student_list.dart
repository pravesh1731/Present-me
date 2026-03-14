import 'package:flutter/foundation.dart';

class JoinStudentList {
  final String studentId;
  final String firstName;
  final String lastName;
  final String emailId;
  final String rollNo;
  final String profilePicUrl;

  const JoinStudentList({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.emailId,
    required this.rollNo,
    required this.profilePicUrl,

  });


  factory JoinStudentList.fromJson(Map<String, dynamic> json) {
    return JoinStudentList(
      studentId: json["studentId"] ?? "",
      firstName: json["firstName"] ?? "",
      lastName: json["lastName"] ?? "",
      emailId: json["emailId"] ?? "",
      rollNo: json["rollNo"] ?? "",
      profilePicUrl: json["profilePicUrl"] ?? "",
    );
  }
}