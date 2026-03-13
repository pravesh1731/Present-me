import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';


import '../../models/studentClass.dart';
import '../../repositories/studentClass_repository.dart';

part 'student_class_event.dart';
part 'student_class_state.dart';

class StudentClassBloc extends Bloc<StudentClassEvent, StudentClassState> {
  final StudentClassRepository repository;

  StudentClassBloc({required this.repository})
      : super(StudentClassInitial()) {
    on<StudentFetchEnrolledClasses>(_onFetchClasses);
    on<StudentJoinClass>(_onJoinClasses);
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

  // ================= JOIN =================
  Future<void> _onJoinClasses(
      StudentJoinClass event,
      Emitter<StudentClassState> emit,
      ) async {
    emit(StudentClassLoading());
    try {
    final message = await repository.joinClass(
        token: event.token,
        classCode: event.classCode,
      );

    emit(StudentClassActionSuccess(message));


    } catch (e) {
      emit(StudentClassError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
