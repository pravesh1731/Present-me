import 'package:equatable/equatable.dart';

class StudentPendingClassModel extends Equatable {
  final String classCode;
  final String className;
  final String teacherId;
  final String teacherName;
  final String roomNo;

  const StudentPendingClassModel({
    required this.classCode,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.roomNo
  });

  // 🔹 JSON → Dart
  factory StudentPendingClassModel.fromJson(Map<String, dynamic> json) {
    return StudentPendingClassModel(
      classCode: json['classCode'] ?? '',
      className: json['className'] ?? '',
      teacherId: json['teacherId'] ?? '',
      teacherName: json['teacherName'] ?? '',
      roomNo: json['roomNo'] ?? '',
    );
  }

  // 🔹 Dart → JSON (optional, useful later)
  Map<String, dynamic> toJson() {
    return {
      'classCode': classCode,
      'className': className,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'roomNo': roomNo,
    };
  }

  @override
  List<Object?> get props => [
    classCode,
    className,
    teacherId,
    teacherName,
    roomNo,
  ];
}
