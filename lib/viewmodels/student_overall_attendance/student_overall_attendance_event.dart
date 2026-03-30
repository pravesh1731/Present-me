abstract class StudentOverallAttendanceEvent {}

class FetchStudentOverallAttendance extends StudentOverallAttendanceEvent {
  final String token;
  FetchStudentOverallAttendance(this.token);
}