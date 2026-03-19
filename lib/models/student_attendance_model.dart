class StudentAttendanceResponse {
  final String classCode;
  final String studentId;
  final List<StudentAttendance> attendance;

  StudentAttendanceResponse({
    required this.classCode,
    required this.studentId,
    required this.attendance,
  });

  factory StudentAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceResponse(
      classCode: json['classCode'] ?? '',
      studentId: json['studentId'] ?? '',
      attendance: (json['attendance'] as List<dynamic>?)
          ?.map((e) => StudentAttendance.fromJson(e))
          .toList() ??
          [],
    );
  }
}

/// SINGLE DAY ATTENDANCE MODEL
class StudentAttendance {
  final String date;
  final int status; // 1 = present, 0 = absent

  StudentAttendance({
    required this.date,
    required this.status,
  });

  /// ✅ ADD THIS ONLY
  StudentAttendance copyWith({
    String? date,
    int? status,
  }) {
    return StudentAttendance(
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }

  factory StudentAttendance.fromJson(Map<String, dynamic> json) {
    return StudentAttendance(
      date: json['date'] ?? '',
      status: json['status'] ?? 0,
    );
  }
}

/// OPTIONAL: HELPER EXTENSIONS (UNCHANGED)
extension AttendanceUtils on List<StudentAttendance> {
  int get presentCount => where((e) => e.status == 1).length;

  int get absentCount => where((e) => e.status == 0).length;

  double get percentage {
    if (isEmpty) return 0;
    return (presentCount / length) * 100;
  }
}