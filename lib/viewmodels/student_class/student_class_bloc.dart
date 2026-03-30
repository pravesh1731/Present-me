import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/studentClass.dart';
import '../../models/student_overall_attendance_model.dart';
import '../../repositories/studentClass_repository.dart';
part 'student_class_event.dart';
part 'student_class_state.dart';

class StudentClassBloc extends Bloc<StudentClassEvent, StudentClassState> {
  final StudentClassRepository repository;
  List<StudentClassModel> _lastLoadedClasses = [];

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
      _lastLoadedClasses = List.from(classes);
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
    try {
      final message = await repository.joinClass(
        token: event.token,
        classCode: event.classCode,
      );
      emit(StudentClassActionSuccess(message));
    } catch (e) {
      // ✅ FIXED: emit JoinError instead of the main Error
      emit(StudentClassJoinError(e.toString().replaceFirst('Exception: ', '')));
      if (_lastLoadedClasses.isNotEmpty) {
        emit(StudentClassLoaded(_lastLoadedClasses));
      }
    }
  }
}
