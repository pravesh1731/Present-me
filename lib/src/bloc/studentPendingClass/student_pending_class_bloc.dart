import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:present_me_flutter/src/models/studentPendingClass.dart';
import 'package:present_me_flutter/src/repositories/studentPendingClass_repository.dart';

part 'student_pending_class_event.dart';
part 'student_pending_class_state.dart';

class StudentPendingClassBloc extends Bloc<StudentPendingClassEvent, StudentPendingClassState> {
  final StudentPendingClassRepository repository;

  StudentPendingClassBloc({required this.repository})
      : super(StudentPendingClassInitial()) {
    on<StudentFetchPendingClasses>(_onFetchPendingClasses);
  }

  // ================= GET =================
  Future<void> _onFetchPendingClasses(
      StudentFetchPendingClasses event,
      Emitter<StudentPendingClassState> emit,
      ) async {
    emit(StudentPendingClassLoading());
    try {
      final classes = await repository.getPendingClasses(event.token);
      emit(StudentPendingClassLoaded(classes));
    } catch (e) {
      emit(StudentPendingClassError(e.toString()));
    }
  }
}
