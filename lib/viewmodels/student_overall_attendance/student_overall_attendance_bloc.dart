import 'package:app/viewmodels/student_overall_attendance/student_overall_attendance_event.dart';
import 'package:app/viewmodels/student_overall_attendance/student_overall_attendance_state.dart';
import 'package:bloc/bloc.dart';

import '../../repositories/student_overall_attendance_repository.dart';


class StudentOverallAttendanceBloc
    extends Bloc<StudentOverallAttendanceEvent, StudentOverallAttendanceState> {

  final StudentOverallAttendanceRepository repository;

  StudentOverallAttendanceBloc({required this.repository})
      : super(StudentOverallAttendanceInitial()) {
    on<FetchStudentOverallAttendance>(_onFetch);
  }

  Future<void> _onFetch(
      FetchStudentOverallAttendance event,
      Emitter<StudentOverallAttendanceState> emit,
      ) async {
    emit(StudentOverallAttendanceLoading());
    try {
      final data = await repository.getOverallAttendance(event.token);
      emit(StudentOverallAttendanceLoaded(data));
    } catch (e) {
      emit(StudentOverallAttendanceError(e.toString()));
    }
  }
}