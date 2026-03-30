// viewmodels/student_overall_attendance/student_overall_attendance_state.dart
import '../../models/student_overall_attendance_model.dart';

abstract class StudentOverallAttendanceState {}

class StudentOverallAttendanceInitial extends StudentOverallAttendanceState {}

class StudentOverallAttendanceLoading extends StudentOverallAttendanceState {}

class StudentOverallAttendanceLoaded extends StudentOverallAttendanceState {
  final StudentOverallAttendance data;
  StudentOverallAttendanceLoaded(this.data);
}

class StudentOverallAttendanceError extends StudentOverallAttendanceState {
  final String message;
  StudentOverallAttendanceError(this.message);
}