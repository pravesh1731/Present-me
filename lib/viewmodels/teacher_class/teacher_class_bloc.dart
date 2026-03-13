import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';


import '../../models/class.dart';
import '../../repositories/teacherClass_repository.dart';


part 'teacher_class_event.dart';
part 'teacher_class_state.dart';

class TeacherClassBloc extends Bloc<TeacherClassEvent, TeacherClassState> {
  final TeacherClassRepository repository;

  TeacherClassBloc({required this.repository})
      : super(TeacherClassInitial()) {
    on<TeacherFetchClasses>(_onFetchClasses);
    on<TeacherCreateClass>(_onCreateClass);
    on<TeacherUpdateClass>(_onUpdateClass);
    on<TeacherDeleteClass>(_onDeleteClass);
  }

  // ================= GET =================
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

  // ================= CREATE =================
  Future<void> _onCreateClass(
      TeacherCreateClass event,
      Emitter<TeacherClassState> emit,
      ) async {
    try {
      await repository.createClass(
        token: event.token,
        className: event.className,
        roomNo: event.roomNo,
        startTime: event.startTime, // HH:mm
        endTime: event.endTime,     // HH:mm
        classDays: event.classDays,
      );

      // refresh list
      final classes = await repository.getClasses(event.token);
      emit(TeacherClassLoaded(classes));
    } catch (e) {
      emit(TeacherClassError(e.toString()));
    }
  }

  // ================= UPDATE =================
  Future<void> _onUpdateClass(
      TeacherUpdateClass event,
      Emitter<TeacherClassState> emit,
      ) async {
    try {
      await repository.updateClass(
        token: event.token,
        classCode: event.classCode,
        className: event.className,
        roomNo: event.roomNo,
        startTime: event.startTime,
        endTime: event.endTime,
        classDays: event.classDays,
      );

      final classes = await repository.getClasses(event.token);
      emit(TeacherClassLoaded(classes));
    } catch (e) {
      emit(TeacherClassError(e.toString()));
    }
  }

  // ================= DELETE =================
  Future<void> _onDeleteClass(
      TeacherDeleteClass event,
      Emitter<TeacherClassState> emit,
      ) async {
    try {
      await repository.deleteClass(
        token: event.token,
        classCode: event.classCode,
      );

      final classes = await repository.getClasses(event.token);
      emit(TeacherClassLoaded(classes));
    } catch (e) {
      emit(TeacherClassError(e.toString()));
    }
  }
}
