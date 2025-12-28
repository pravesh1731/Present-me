import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'student_class_event.dart';
part 'student_class_state.dart';

class StudentClassBloc extends Bloc<StudentClassEvent, StudentClassState> {
  StudentClassBloc() : super(StudentClassInitial()) {
    on<StudentClassEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
