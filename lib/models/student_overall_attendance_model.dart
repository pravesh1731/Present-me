// models/student_overall_attendance_model.dart

class StudentClassSummary {
  final String classCode;
  final String className;
  final int totalPresent;
  final int totalAbsent;
  final int totalClasses;
  final double attendancePercentage;

  const StudentClassSummary({
    required this.classCode,
    required this.className,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalClasses,
    required this.attendancePercentage,
  });

  factory StudentClassSummary.fromJson(Map<String, dynamic> json) {
    return StudentClassSummary(
      classCode: json['classCode'] ?? '',
      className: json['className'] ?? '',
      totalPresent: (json['totalPresent'] as num?)?.toInt() ?? 0,
      totalAbsent: (json['totalAbsent'] as num?)?.toInt() ?? 0,
      totalClasses: (json['totalClasses'] as num?)?.toInt() ?? 0,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MonthlyAttendanceSummary {
  final String month;
  final int present;
  final int absent;
  final int totalClasses;
  final double attendancePercentage;

  const MonthlyAttendanceSummary({
    required this.month,
    required this.present,
    required this.absent,
    required this.totalClasses,
    required this.attendancePercentage,
  });

  factory MonthlyAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendanceSummary(
      month: json['month'] ?? '',
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      totalClasses: (json['totalClasses'] as num?)?.toInt() ?? 0,
      attendancePercentage:
      (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StudentOverallAttendance {
  final int totalClassesJoined;
  final int overallPresent;
  final int overallAbsent;
  final int overallTotalClasses;
  final double overallAttendancePercentage;
  final List<StudentClassSummary> classSummaries;
  final List<MonthlyAttendanceSummary> monthlySummary;

  const StudentOverallAttendance({
    required this.totalClassesJoined,
    required this.overallPresent,
    required this.overallAbsent,
    required this.overallTotalClasses,
    required this.overallAttendancePercentage,
    required this.classSummaries,
    required this.monthlySummary,
  });

  factory StudentOverallAttendance.fromJson(Map<String, dynamic> json) {
    return StudentOverallAttendance(
      totalClassesJoined: (json['totalClassesJoined'] as num?)?.toInt() ?? 0,
      overallPresent: (json['overallPresent'] as num?)?.toInt() ?? 0,
      overallAbsent: (json['overallAbsent'] as num?)?.toInt() ?? 0,
      overallTotalClasses: (json['overallTotalClasses'] as num?)?.toInt() ?? 0,
      overallAttendancePercentage: (json['overallAttendancePercentage'] as num?)?.toDouble() ?? 0.0,
      classSummaries: (json['classSummaries'] as List? ?? [])
          .map((e) => StudentClassSummary.fromJson(e))
          .toList(),
      monthlySummary: (json['monthlySummary'] as List? ?? [])
          .map((e) => MonthlyAttendanceSummary.fromJson(e))
          .toList(),
    );
  }
}


