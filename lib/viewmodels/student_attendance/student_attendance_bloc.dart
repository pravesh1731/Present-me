import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:present_me_flutter/repositories/student_attendance.dart';
import 'student_attendance_event.dart';
import 'student_attendance_state.dart';


class StudentAttendanceBloc extends Bloc<StudentAttendanceEvent, StudentAttendanceState> {

  final StudentAttendanceRepository repository;

  StudentAttendanceBloc({required this.repository} )
      : super(StudentAttendanceInitial()) {

    on<FetchStudentAttendance>(_onFetchAttendance);
  }

  Future<void> _onFetchAttendance(
      FetchStudentAttendance event,
      Emitter<StudentAttendanceState> emit,
      ) async {

    emit(StudentAttendanceLoading());

    try {

      final result = await repository.getStudentAttendance(
        classCode: event.classCode,
        studentId: event.studentId,
      );

      emit(StudentAttendanceLoaded(result));

    } catch (e) {

      emit(StudentAttendanceError(e.toString()));

    }
  }
}