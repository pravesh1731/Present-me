import '../../models/student_attendance_model.dart';

abstract class StudentAttendanceState {}

class StudentAttendanceInitial extends StudentAttendanceState {}

class StudentAttendanceLoading extends StudentAttendanceState {}

class StudentAttendanceLoaded extends StudentAttendanceState {
  final StudentAttendanceResponse data;

  StudentAttendanceLoaded(this.data);
}

class StudentAttendanceError extends StudentAttendanceState {
  final String message;

  StudentAttendanceError(this.message);
}