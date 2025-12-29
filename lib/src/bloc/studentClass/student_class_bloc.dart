import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:present_me_flutter/src/models/studentClass.dart';
import 'package:present_me_flutter/src/repositories/studentClass_repository.dart';

part 'student_class_event.dart';
part 'student_class_state.dart';

class StudentClassBloc extends Bloc<StudentClassEvent, StudentClassState> {
  final StudentClassRepository repository;

  StudentClassBloc({required this.repository})
      : super(StudentClassInitial()) {
    on<StudentFetchEnrolledClasses>(_onFetchClasses);
  }

  // ================= GET =================
  Future<void> _onFetchClasses(
      StudentFetchEnrolledClasses event,
      Emitter<StudentClassState> emit,
      ) async {
    emit(StudentClassLoading());
    try {
      final classes = await repository.getEnrolledClasses(event.token);
      emit(StudentClassLoaded(classes));
    } catch (e) {
      emit(StudentClassError(e.toString()));
    }
  }
}
