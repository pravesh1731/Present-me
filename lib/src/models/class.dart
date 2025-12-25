import 'package:equatable/equatable.dart';

class ClassModel extends Equatable {
  final String classCode;
  final String className;
  final String roomNo;
  final String startTime;
  final String endTime;
  final List<String> classDays;
  final List<String> students;
  final List<String> joinRequests;
  final DateTime createdAt;

  const ClassModel({
    required this.classCode,
    required this.className,
    required this.roomNo,
    required this.startTime,
    required this.endTime,
    required this.classDays,
    required this.students,
    required this.joinRequests,
    required this.createdAt,
  });

  /// ✅ Convert JSON → Dart Object
  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      classCode: json['classCode'] ?? '',
      className: json['className'] ?? '',
      roomNo: json['roomNo'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      classDays: List<String>.from(json['classDays'] ?? []),
      students: List<String>.from(json['students'] ?? []),
      joinRequests: List<String>.from(json['joinRequests'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  /// ✅ Convert Dart Object → JSON
  Map<String, dynamic> toJson() {
    return {
      'classCode': classCode,
      'className': className,
      'roomNo': roomNo,
      'startTime': startTime,
      'endTime': endTime,
      'classDays': classDays,
      'students': students,
      'joinRequests': joinRequests,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// ✅ Helpful for PATCH / copy updates
  ClassModel copyWith({
    String? classCode,
    String? className,
    String? roomNo,
    String? startTime,
    String? endTime,
    List<String>? classDays,
    List<String>? students,
    List<String>? joinRequests,
    DateTime? createdAt,
  }) {
    return ClassModel(
      classCode: classCode ?? this.classCode,
      className: className ?? this.className,
      roomNo: roomNo ?? this.roomNo,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      classDays: classDays ?? this.classDays,
      students: students ?? this.students,
      joinRequests: joinRequests ?? this.joinRequests,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    classCode,
    className,
    roomNo,
    startTime,
    endTime,
    classDays,
    students,
    joinRequests,
    createdAt,
  ];
}
