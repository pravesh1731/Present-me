import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:present_me_flutter/src/models/class.dart';
import 'package:present_me_flutter/src/repositories/teacherClass_repository.dart';

part 'teacher_class_event.dart';
part 'teacher_class_state.dart';

class TeacherClassBloc extends Bloc<TeacherClassEvent, TeacherClassState> {
  final TeacherClassRepository repository;

  TeacherClassBloc({required this.repository}) : super(TeacherClassInitial()) {
    on<TeacherFetchClasses>(_onFetchClasses);
  }

  /// GET classes
  Future<void> _onFetchClasses(
    TeacherFetchClasses event,
    Emitter<TeacherClassState> emit,
  ) async {
    emit(TeacherClassLoading());
    try {
      final classes = await repository.getClasses(event.token);
      emit(TeacherClassLoaded(classes));
    } catch (e) {
      emit(TeacherClassError(e.toString()));
    }
  }
}
