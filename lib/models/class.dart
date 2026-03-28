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
  final int totalClasses;        // ✅ added
  final int totalStudents;       // ✅ added
  final double averageAttendance; // ✅ added

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
    this.totalClasses = 0,         // ✅ default 0
    this.totalStudents = 0,        // ✅ default 0
    this.averageAttendance = 0.0,  // ✅ default 0.0
  });

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    if (value is Map) return value.values.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    if (value is String) return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return [];
  }

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    String pickString(List<String> keys) {
      for (final k in keys) {
        if (json.containsKey(k) && json[k] != null) return json[k].toString();
      }
      return '';
    }

    dynamic createdRaw;
    if (json.containsKey('createdAt')) createdRaw = json['createdAt'];
    else if (json.containsKey('created_at')) createdRaw = json['created_at'];
    else if (json.containsKey('created')) createdRaw = json['created'];

    DateTime createdAt;
    try {
      if (createdRaw == null) {
        createdAt = DateTime.now();
      } else if (createdRaw is int) {
        createdAt = createdRaw > 10000000000
            ? DateTime.fromMillisecondsSinceEpoch(createdRaw)
            : DateTime.fromMillisecondsSinceEpoch(createdRaw * 1000);
      } else if (createdRaw is double) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(createdRaw.toInt());
      } else if (createdRaw is String) {
        createdAt = DateTime.tryParse(createdRaw) ?? DateTime.now();
      } else {
        createdAt = DateTime.now();
      }
    } catch (_) {
      createdAt = DateTime.now();
    }

    return ClassModel(
      classCode: pickString(['classCode', 'code', 'id']),
      className: pickString(['className', 'name', 'title']),
      roomNo: pickString(['roomNo', 'room', 'room_no']),
      startTime: pickString(['startTime', 'start_time', 'start']),
      endTime: pickString(['endTime', 'end_time', 'end']),
      classDays: _toStringList(json['classDays'] ?? json['days'] ?? json['class_days'] ?? json['days_of_week']),
      students: _toStringList(json['students'] ?? json['members'] ?? json['participants']),
      joinRequests: _toStringList(json['joinRequests'] ?? json['requests'] ?? json['pendingRequests']),
      createdAt: createdAt,
      // ✅ parse new fields with safe fallbacks
      totalClasses: (json['totalClasses'] as num?)?.toInt() ?? 0,
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      averageAttendance: (json['averageAttendance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "classCode": classCode,
      "className": className,
      "roomNo": roomNo,
      "startTime": startTime,
      "endTime": endTime,
      "classDays": classDays,
      "students": students,
      "joinRequests": joinRequests,
      "createdAt": createdAt.toIso8601String(),
      "totalClasses": totalClasses,
      "totalStudents": totalStudents,
      "averageAttendance": averageAttendance,
    };
  }

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
    int? totalClasses,
    int? totalStudents,
    double? averageAttendance,
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
      totalClasses: totalClasses ?? this.totalClasses,
      totalStudents: totalStudents ?? this.totalStudents,
      averageAttendance: averageAttendance ?? this.averageAttendance,
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
    totalClasses,
    totalStudents,
    averageAttendance,
  ];
}