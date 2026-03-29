import 'package:equatable/equatable.dart';

class StudentClassModel extends Equatable {
  final String classCode;
  final String className;
  final List<String> classDays;
  final String startTime;
  final String endTime;
  final String teacherId;
  final String teacherName;
  final String roomNo;
  final bool isActive;

  const StudentClassModel({
    required this.classCode,
    required this.className,
    required this.classDays,
    required this.startTime,
    required this.endTime,
    required this.teacherId,
    required this.teacherName,
    required this.roomNo,
    this.isActive = true,
  });

  // 🔹 JSON → Dart
  factory StudentClassModel.fromJson(Map<String, dynamic> json) {
    return StudentClassModel(
      classCode: json['classCode'] ?? '',
      className: json['className'] ?? '',
      classDays: List<String>.from(json['classDays'] ?? []),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      teacherId: json['teacherId'] ?? '',
      teacherName: json['teacherName'] ?? '',
      roomNo: json['roomNo'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  // 🔹 Dart → JSON (optional, useful later)
  Map<String, dynamic> toJson() {
    return {
      'classCode': classCode,
      'className': className,
      'classDays': classDays,
      'startTime': startTime,
      'endTime': endTime,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'roomNo': roomNo,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => [
    classCode,
    className,
    classDays,
    startTime,
    endTime,
    teacherId,
    teacherName,
    roomNo,
    isActive,
  ];
}
