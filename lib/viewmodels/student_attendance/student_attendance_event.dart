abstract class StudentAttendanceEvent {}

class FetchStudentAttendance extends StudentAttendanceEvent {
  final String classCode;
  final String studentId;

  FetchStudentAttendance({
    required this.classCode,
    required this.studentId,
  });
}